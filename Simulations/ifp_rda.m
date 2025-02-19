function [samples_cC, interms] = ifp_rda(samples, t_fast, s_tx, f_s, ...
    T_slow, spd, R_0, lambda)
    
    % Form image using Range-Doppler Algorithm
    % INPUTS (T - number of slow-time samples, t - number of fast-time samples)
    %   samples     (T by t)    phase history
    %   t_fast      (1 by t)    fast times
    %   s_tx        (1 by t)    transmitted pulse
    %   f_s         (1 by 1)    sample frequency
    c = 299792458;
    [N_range, N_cross] = size(samples);

    F_prf = 1/(T_slow(2) - T_slow(1));
    % K_r = B/tau;
    K_a = 2*spd^2/(lambda*R_0);

    wb = waitbar(0, "Range-Doppler processing");
    oc = onCleanup(@() close(wb));

    % t_tx = (0:(1/f_s):tau)';
    N_range_fft = N_range + length(s_tx) - 1;
    range_MF = fft(s_tx', N_range_fft);

    waitbar(0.25, wb, "Range compression");
    samples_fT = fft(samples, N_range_fft, 1);
    samples_cT = ifft(samples_fT .* range_MF, N_range_fft, 1);
    samples_cT = samples_cT((1:N_range) + floor(length(s_tx)/2), :);
    
    % RCMC
    waitbar(0.5, wb, "Range cell migration");
    N_cross_fft = N_cross; %* 2;
    F_dop_bins = freqaxis(F_prf, N_cross_fft);
    cross_MF = exp(-1j*pi*F_dop_bins.^2 / K_a);

    ranges = c*t_fast/2;
    rcmc_ranges = ranges * (1 + (lambda^2 * F_dop_bins .^2) / (8*spd^2));
    samples_cF = fftshift(fft(samples_cT, N_cross_fft, 2), 2);
    samples_rcmc_cF = samples_cF;
    for i_slow = 1:N_cross
        samples_rcmc_cF(:, i_slow) = interp1(ranges, ...
            samples_rcmc_cF(:, i_slow), rcmc_ranges(:, i_slow), ...
            "linear", 0);
    end

    % Doppler compression
    waitbar(0.75, wb, "Cross-range compression");
    samples_cC = ifft(ifftshift(samples_rcmc_cF .* cross_MF, 2), N_cross_fft, 2);
    % samples_cC = samples_cC(1:N_cross, 1);

    waitbar(1, wb, "Done");
    delete(oc);

    if nargout == 2
        interms.range_compressed = samples_cT;
        interms.rangedop = samples_cF;
        interms.rangedop_rcmc = samples_rcmc_cF;
    end
end
