% [samples_tT, t_fast, T_slow] = simulate_phase_history(radar, aperture, targets)
%   Inputs are structures,
%   radar: lambda, tau, B, f_s, phase
%   aperture: F_prf, X_aT, V_aT, look_aaT, t_min, t_max, G_ant(sin_az, sin_el)
%   targets: X_aN, sig_1N
%   
%   samples_tT:     phase history
%   t_fast:         fast-time vector
%   T_slow:         slow-time vector
% 
% Returns phase history, inclusive of range modulation, antenna gain, and
% target RCS. Transmit power, system losses, and noise must be included
% separately.

function [samples_tT, t_fast, T_slow, aux] = simulate_phase_history(radar, aperture, targets)
    c = 299792458;
    range2time = @(r) 2/c*r;

    % Calculate geometry
    x_tgt_a1N = permute(targets.X_aN, [1 3 2]); % permute for broadcasting
    sig_tgt_11N = permute(targets.sig_N(:), [2 3 1]); % permute for broadcasting
    r_tgt_aTN = aperture.X_aT - x_tgt_a1N; % displacement platform-to-target
    R_tgt_1TN = vecnorm(r_tgt_aTN, 2, 1); % ranges 
    u_tgt_aTN = r_tgt_aTN ./ R_tgt_1TN; % unit vectors

    t_tx_t = (0:(1/radar.f_s):radar.tau)' - radar.tau/2;
    t_tgt_1TN = range2time(R_tgt_1TN);

    % sample-justify received signal timing
    t_samp_tTN = floor(t_tgt_1TN * radar.f_s) / radar.f_s + t_tx_t - t_tgt_1TN;
    % calculate received signal destination indicies
    i_tgt_1TN = floor(radar.f_s * (t_tgt_1TN - aperture.t_min - radar.tau/2));
    i_tgt_eTN = cat(1, i_tgt_1TN, i_tgt_1TN + length(t_tx_t) - 1);
    % max index to expand received sample array (if necessary) for targets at extreme corners
    i_rx_max = max(i_tgt_eTN(2, :, [1 end]), [], "all");
    t_max = max(aperture.t_max, i_rx_max/radar.f_s + aperture.t_min);

    t_fast = (aperture.t_min:(1/radar.f_s):t_max)';
    n_fast = length(t_fast);

    N_slow = size(aperture.X_aT, 2);
    T_slow = ((1:N_slow)-1)/aperture.F_prf;  
    T_slow = T_slow - mean(T_slow); % 0-centered

    % Doppler to each target

    V_aTN = repmat(aperture.V_aT, 1, size(u_tgt_aTN, 2), size(u_tgt_aTN, 3));
    F_dop_1TN = 2/radar.lambda * dot(V_aTN, u_tgt_aTN, 1); 
    % Unit vector in antenna axes (left-x, forward-y, up-z)
    u_tgt_ant_aTN = pagemtimes(aperture.look_aaT, u_tgt_aTN);
    G_ant_1TN = aperture.G_ant(u_tgt_ant_aTN(1, :, :), u_tgt_ant_aTN(3, :, :));
    h_rx_1TN = sqrt(sig_tgt_11N * (radar.lambda^2/(4*pi)^3) .* G_ant_1TN.^2 ./ R_tgt_1TN.^4);
    K_r = radar.B / radar.tau;
    s_rx_tTN = h_rx_1TN .* exp(1j*(-(4*pi/radar.lambda)*R_tgt_1TN + ...
        pi*K_r * t_samp_tTN.^2 + 2*pi * F_dop_1TN.*t_samp_tTN));

    samples_tT = zeros(n_fast, N_slow);
    wb = waitbar(0, "Composing phase history");
    N_pulses = size(s_rx_tTN, 2);
    for slow_i = 1:N_pulses

        if mod(slow_i, floor(N_pulses/10)) == 0
            waitbar(slow_i/size(s_rx_tTN, 2), wb, sprintf("Pulse %d", slow_i));
        end

        for tar_i = 1:size(s_rx_tTN, 3)
            slc = i_tgt_eTN(1, slow_i, tar_i):i_tgt_eTN(2, slow_i, tar_i);
            samples_tT(slc, slow_i) = samples_tT(slc, slow_i) + s_rx_tTN(:, slow_i, tar_i);
        end
    end
    waitbar(1, wb, "Done.");
    close(wb);
    
    % Cut off samples beyond max time
    i_aperture = t_fast < aperture.t_max;
    t_fast = t_fast(i_aperture);
    samples_tT = samples_tT(i_aperture, :);

    aux.R_tgt = squeeze(R_tgt_1TN);
    aux.F_dop = squeeze(F_dop_1TN);
    aux.G_ant = squeeze(G_ant_1TN);
end
