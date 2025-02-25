function [samples, fast_time, slow_time] = stripmap_phase_history(aperture, radio, targets)
    mustBeFields(aperture, ["altitude", "ground_range", "scene_dims", "speed", "pulse_rate"]);
    mustBeFields(radio, ["wavelength", "sample_freq", "pulse", "f_tx_gain", "f_rx_gain"]);
    mustBeFields(targets, ["position", "rcs"]);
    
    wavespeed = 299792458; % [m/s] speed of light

    ground_range_swath = aperture.ground_range + aperture.scene_dims(2) * [-1/2 1/2];
    slant_range_swath = sqrt(aperture.altitude^2 + ground_range_swath.^2);
    fast_time_range = 2*slant_range_swath/wavespeed;
    fast_time_range = round(fast_time_range * radio.sample_freq) / radio.sample_freq;

    % one-sided pulse time vector (column)
    pulse_time = ((1:length(radio.pulse))-1) / radio.sample_freq;
    pulse_time = pulse_time';
    % fast time vector padded by an additional pulse (to capture entire far-range return)
    fast_time = fast_time_range(1):(1/radio.sample_freq):(fast_time_range(2) + pulse_time(end));
    fast_time = fast_time';

    cross_range_swath = aperture.scene_dims(1) * [-1/2 1/2];
    slow_time_range = cross_range_swath / aperture.speed;
    slow_time = slow_time_range(1):(1/aperture.pulse_rate):slow_time_range(2);

    assert(iscolumn(pulse_time), "Pulse time must be a column vector");
    assert(iscolumn(fast_time), "Fast time samples must be a column vector");
    assert(isrow(slow_time), "Slow time samples must be a row vector");

    % platform motion
    velocity = [aperture.speed; 0; 0];
    position = velocity * slow_time + [0; 0; aperture.altitude];
    grazing = atan(aperture.altitude / mean(ground_range_swath));
    % antenna frame's direction cosine matrix -- such that u(ant) = look * u(world)
    direction = [1 0 0;
        0 cos(grazing) -sin(grazing);
        0 sin(grazing) cos(grazing)];

    N_fast = length(fast_time);
    N_slow = length(slow_time);
    N_targets = length(targets.rcs);
    samples = zeros(N_fast, N_slow);

    prog_every = floor(N_slow/50); % 50 progress steps
    prog = progressbar("Generating phase history");

    for i_slow = 1:N_slow
        for i_tgt = 1:N_targets
            r_tgt = targets.position(:, i_tgt) - position(:, i_slow);
            R_tgt = norm(r_tgt);
            u_tgt = r_tgt/R_tgt;

            t_tgt = 2*R_tgt/wavespeed;
            t_return = t_tgt + pulse_time;

            u_in_antenna = direction * u_tgt;
            az = asin(u_in_antenna(1));
            el = asin(u_in_antenna(3));

            G2 = radio.f_tx_gain(az, el) * radio.f_rx_gain(az, el);
            A_rx = sqrt(targets.rcs(i_tgt) * radio.wavelength^2/(4*pi)^3 * G2 / R_tgt^4);

            F_dop = 2*radio.wavelength * velocity' * u_tgt;
            phase_dop = 2*pi*F_dop*t_return;
            phase_tgt = -(4*pi/radio.wavelength)*R_tgt;

            return_pulse = radio.pulse .* exp(1j*(phase_dop + phase_tgt)); 
            s_rx = A_rx * interp1(t_return, return_pulse, fast_time, "linear", 0);
            s_rx(isnan(s_rx)) = 0;

            samples(:, i_slow) = samples(:, i_slow) + s_rx;
        end

        if mod(i_slow, prog_every) == 0
            prog(i_slow/N_slow, "Simulated pulse %d of %d", i_slow, N_slow);
        end
    end

end

function mustBeFields(structure, fields)
    fn = string(fieldnames(structure));
    notpresent = setdiff(fields, fn);
    name = inputname(1);
    if ~isempty(notpresent)
        mex = MException("simulate_phase_history:notfields", ...
            "Required fields of %s not present: %s", name, mat2str(notpresent));
        throwAsCaller(mex);
    end
end

