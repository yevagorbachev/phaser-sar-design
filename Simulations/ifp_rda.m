function [image, t_fast, T_slow, interms] = ifp_rda(samples, t_fast, T_slow, s_tx, ...
    spd, R_0, lambda)
    arguments
        samples (:, :) double;
        t_fast (:, 1) double;
        T_slow (1, :) double;
        s_tx (:, 1) double;
        spd (1,1) double;
        R_0 (1,1) double;
        lambda (1,1) double;
    end

    assert(isequal(size(samples), [length(t_fast) length(T_slow)]), ...
        "Sample matrix must be [t by T]");
    
    c = 299792458;
    % samples = [samples; zeros(length(s_tx) - 1, size(samples, 2))];
    [N_range, N_cross] = size(samples);

    K_a = 2*spd^2/(lambda*R_0);

    prog = progressbar("Range-Doppler processing");

    % t_tx = (0:(1/f_s):tau)';
    % N_range_fft = N_range + length(s_tx) - 1;
    range_MF = fft(conj(s_tx), N_range);
    samples_fT = fft(samples, N_range, 1);
    samples_cT = ifft(samples_fT .* range_MF, N_range, 1);
    N_bins = size(samples, 1) - length(s_tx);
    samples_cT = samples_cT((end-N_bins+1):end, :);
    t_fast = t_fast((end-N_bins+1):end);

    prog(0.25, "Finished range compression")
    
    % RCMC
    N_cross_fft = N_cross; %* 2;
    F_dop_bins = freqaxis(1/(T_slow(2)-T_slow(1)), N_cross_fft);
    cross_MF = exp(-1j*pi*F_dop_bins.^2 / K_a);

    ranges = c*t_fast/2;
    rcmc_ranges = ranges * (1 + (lambda^2 * F_dop_bins .^2) / (8*spd^2));
    samples_cF = fftshift(fft(samples_cT, N_cross_fft, 2), 2);
    samples_rcmc_cF = samples_cF;
    % samples_rcmc_cF = interp1(ranges, samples_rcmc_cF, rcmc_ranges, "linear", 0);
    for i_slow = 1:N_cross
        samples_rcmc_cF(:, i_slow) = interp1(ranges, ...
            samples_rcmc_cF(:, i_slow), rcmc_ranges(:, i_slow), ...
            "linear", 0);
    end
    prog(0.5, "Finished RCMC")

    % Doppler compression
    image = ifft(ifftshift(samples_rcmc_cF .* cross_MF, 2), N_cross_fft, 2);

    prog(0.75, "Finished azimuth compression");
    % samples_cC = samples_cC(1:(end-length(s_tx)), :);

    if nargout == 4
        interms.range_compressed = samples_cT;
        interms.rangedop = samples_cF;
        interms.rangedop_rcmc = samples_rcmc_cF;
    end
end
