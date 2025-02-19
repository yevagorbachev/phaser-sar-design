% [samples_tT, t_fast, T_slow] = simulate_phase_history(radar, aperture, targets)
%   Inputs are structures,
%   radar: wavelength, tau, B, sample_freq, phase
%   aperture: F_prf, platform_posn_3T, V_aT, platform_look_33T, t_range(1), t_max, G_ant(sin_az, sin_el)
%   targets: plat_posn_3N, sig_1N
%   
%   samples_tT:     phase history
%   t_fast:         fast-time vector
%   T_slow:         slow-time vector
% 
% Returns phase history, inclusive of range modulation, antenna gain, and
% target RCS. Transmit power, system losses, and noise must be included
% separately.

function [samples, t_fast, T_slow] = simulate_phase_history(radar, aperture, targets)
    c = 299792458;

    mustBeFields(radar, ["pulse", "sample_freq", "wavelength"])
    mustBeFields(aperture, ["platform_position", "platform_velocity", ...
        "platform_look", "t_range", "T_range"]);
    mustBeFields(targets, ["target_position", "target_RCS"]);

    t_fast = aperture.t_range(1):(1/radar.sample_freq):aperture.t_range(2);
    t_fast = t_fast';
    n_fast = length(t_fast);

    T_slow = linspace(aperture.T_range(1), aperture.T_range(2), ...
        size(aperture.platform_position, 2));
    N_slow = length(T_slow);

    N_tgt = length(targets.target_RCS);

    samples = zeros(n_fast, N_slow);

    % much or all of this can be vectorized, but the cost to readability is not
    % worth it in my opinion
    wb = waitbar(0, "Generating raw phase history", Name = "Progress");
    oc = onCleanup(@() close(wb));
    every = floor(N_slow/20);


    for i_slow = 1:N_slow
        for i_tgt = 1:N_tgt
            r_tgt = targets.target_position(:, i_tgt) - aperture.platform_position(:, i_slow);
            v_tgt = aperture.platform_velocity(:, i_slow);

            R_tgt = norm(r_tgt);
            t_tgt = 2*R_tgt/c;
            u_tgt = r_tgt / R_tgt;
            az = sin(u_tgt(1));
            el = sin(u_tgt(1));

            F_dop = 2/radar.wavelength * v_tgt' * u_tgt;
            G_tx = aperture.tx_antenna_gain(az, el);
            G_rx = aperture.rx_antenna_gain(az, el);
            A_rx = sqrt(targets.target_RCS(i_tgt) * radar.wavelength^2/(4*pi)^3 * G_tx * G_rx / R_tgt^4);

            phase_dop = 2*pi*F_dop*t_fast;
            phase_tgt = -(4*pi/radar.wavelength)*R_tgt;
            pulse = interp1(radar.pulse, (t_fast - t_tgt)*radar.sample_freq + 1, "linear", 0);
            pulse(isnan(pulse)) = 0;
            s_rx = A_rx .* exp(1j*(phase_dop + phase_tgt)) .* pulse;
            
            samples(:, i_slow) = samples(:, i_slow) + s_rx;
        end

        if mod(i_slow, every) == 0
            waitbar(i_slow / N_slow, wb, sprintf("Position %d of %d", i_slow, N_slow));
        end
    end
    delete(oc);
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
