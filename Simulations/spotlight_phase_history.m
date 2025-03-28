function data = spotlight_phase_history(aperture, radio, targets, config)
    arguments
        aperture (1,1) struct {mustBeFields(aperture, ...
            ["altitude", "ground_range", "scene_dims", "speed", "pulse_rate"])};
        radio (1,1) struct {mustBeFields(radio, ...
            ["wavelength", "sample_freq", "ramp_rate", "ramp_time", "f_tx_gain", "f_rx_gain"])};
        targets (1,:) struct {mustBeFields(targets, ["position", "rcs"])};
        config.amplitude (1,1) string {mustBeMember(config.amplitude, ...
            ["unit", "true"])} = "true";
    end

    wavespeed = 299792458; % [m/s] speed of light
    center_freq_angular = 2*pi*wavespeed/radio.wavelength;

    grp_position = [0; aperture.ground_range; 0];

    cross_range_swath = aperture.scene_dims(1) * [-1/2 1/2];
    slow_time_range = cross_range_swath / aperture.speed;
    slow_time = slow_time_range(1):(1/aperture.pulse_rate):slow_time_range(2);
    velocity = [aperture.speed; 0; 0];
    position = velocity * slow_time + [0; 0; aperture.altitude];

    pulse_time = 0:(1/radio.sample_freq):radio.ramp_time;
    pulse_time = pulse_time';

    grp_range_vector = grp_position - position;
    grp_range = vecnorm(grp_range_vector, 2, 1);
    slant_range_swath = grp_range + aperture.scene_dims(2) * [-1/2; 1/2];
    % add 1 full pulse of padding to the end
    fast_time_range = 2*slant_range_swath/wavespeed + [0; radio.ramp_time];
    fast_time_range = round(fast_time_range * radio.sample_freq) / radio.sample_freq;
    N_fast = (fast_time_range(2,1) - fast_time_range(1,1)) * radio.sample_freq;

    % use interp1 to do all of the channels simultaneously
    fast_time = interp1([0; 1], fast_time_range, (0:(N_fast-1))'/N_fast, "linear", "extrap");

    assert(iscolumn(pulse_time), "Pulse time must be a column vector");
    assert(isrow(slow_time), "Slow time samples must be a row vector");

    grp_azimuth = atan2(grp_range_vector(1, :), grp_range_vector(2, :));
    grp_elevation = atan2(grp_range_vector(3, :), grp_range_vector(2, :));

    N_fast = size(fast_time, 1);
    N_slow = size(fast_time, 2);
    % N_targets = length(targets.rcs);
    samples = zeros(N_fast, N_slow);

    prog_every = floor(N_slow/100); % 100 progress steps
    prog = progressbar("Generating phase history");

    tgt_to_simulate = find([targets.rcs] ~= 0);
    parfor i_slow = 1:N_slow
        t_grp = 2*grp_range(i_slow)/wavespeed;
        for i_tgt = tgt_to_simulate
            r_tgt = targets(i_tgt).position - position(:, i_slow); %#ok
            R_tgt = norm(r_tgt);
            u_tgt = r_tgt/R_tgt;

            t_tgt = 2*R_tgt/wavespeed;
            t_diff = t_tgt - t_grp;
            t_return = t_tgt + pulse_time;

            if config.amplitude == "unit"
                A_rx = 1;
            elseif config.amplitude == "true"
                az = asin(u_tgt(1)) - grp_azimuth(i_slow);
                el = asin(u_tgt(3)) - grp_elevation(i_slow);
                G2 = radio.f_tx_gain(az, el) * radio.f_rx_gain(az, el);
                A_rx = sqrt((targets(i_tgt).rcs * G2 * radio.wavelength^2)/((4*pi)^3 * R_tgt^4))/2;
            else
                error("Invalid amplitude")
            end
            
            phase = pi*radio.ramp_rate .* t_diff.^2 - ...
                t_diff*(center_freq_angular + 2*pi*radio.ramp_rate*(t_return - t_grp));

            phase_rx = interp1(t_return, phase, fast_time(:, i_slow), "linear", NaN);
            s_rx = A_rx * exp(1j*phase_rx);
            s_rx(isnan(s_rx)) = 0;

            samples(:, i_slow) = samples(:, i_slow) + s_rx;
        end

        if mod(i_slow, prog_every) == 0
            % prog(i_slow/N_slow, "Simulated pulse %d of %d", i_slow, N_slow);
        end
    end

    data = phasehistory(samples);
    data.slow_time = slow_time;
    data.fast_time = fast_time;
    data.position = position;
    data.velocity = velocity;
    data.grp = [0; aperture.ground_range; 0];
    data.wavelength = radio.wavelength;
    data.ramp_rate = radio.ramp_rate;
    data.ramp_time = radio.ramp_time;
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

