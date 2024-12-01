function [samples_cC, interms] = ifp_rda(samples_tT, t_fast, K_r, tau, ...
    T_slow, K_a, spd, lambda)
    c = 299792458;
    [N_range, N_cross] = size(samples_tT);

    f_s = 1/(t_fast(2) - t_fast(1));
    F_prf = 1/(T_slow(2) - T_slow(1));

    wb = waitbar(0, "Range-Doppler processing");

    t_tx = (0:(1/f_s):tau)';
    range_chirp = exp(1j*pi*K_r*(t_tx - tau/2).^2);
    N_range_fft = N_range + length(range_chirp);
    range_MF = fft(conj(range_chirp), N_range_fft); 

    waitbar(0.25, wb, "Range compression");
    samples_fT = fft(samples_tT, N_range_fft, 1);
    samples_cT = ifft(samples_fT .* range_MF, N_range_fft, 1);
    samples_cT = samples_cT((1:N_range) + floor(length(range_chirp)/2), :);
    
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
    samples_cC = samples_cC(:, 1:N_cross);

    waitbar(1, wb, "Done");
    close(wb);

    if nargout == 2
        interms.range_compressed_tT = samples_cT;
        interms.rangedop_tF = samples_cF;
        interms.rangedop_rcmc_tF = samples_rcmc_cF;
    end
end
