function [image, interms] = ifp_rda(data)
    arguments
        data (1,1) phasehistory
        % samples (:, :) double;
        % t_fast (:, 1) double;
        % T_slow (1, :) double;
        % s_tx (:, 1) double;
        % spd (1,1) double;
        % R_0 (1,1) double;
        % lambda (1,1) double;
    end

    samples = data.values;
    T_slow = data.slow_time;
    sample_time = mean(diff(data.fast_time(:, 1), 1));
    sigtime = 0:sample_time:data.ramp_time;
    sigtime = sigtime';

    s_tx = exp(1j*pi*data.ramp_rate*(sigtime - mean(sigtime)).^2);
    spd = vecnorm(mean(diff(data.velocity), 2), 2, 1);
    R_0 = vecnorm(data.grp, 2, 1);
    lambda = data.wavelength;
    
    c = 299792458;
    [N_range, N_cross] = size(samples);

    K_a = 2*spd^2/(lambda*R_0);

    prog = progressbar("Range-Doppler processing");

    N_range_fft = N_range;
    range_MF = fft(conj(s_tx), N_range_fft);
    samples_fT = fft(samples, N_range_fft, 1);
    samples_cT = ifft(samples_fT .* range_MF, N_range_fft, 1);
    crop_indices = length(s_tx):size(samples, 1);
    samples_cT = samples_cT(length(s_tx):size(samples, 1), :);
    t_fast = data.fast_time(1:(size(samples,1)-length(s_tx)+1), 1);
    keyboard;

    prog(0.25, "Finished range compression")
    
    % RCMC
    N_cross_fft = N_cross; %* 2;
    F_dop_bins = freqaxis(1/(T_slow(2)-T_slow(1)), N_cross_fft);
    cross_MF = exp(-1j*pi*F_dop_bins.^2 / K_a);

    ranges = c*t_fast/2
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
    samples_cC = ifft(ifftshift(samples_rcmc_cF .* cross_MF, 2), N_cross_fft, 2);
    image = compleximage(samples_cC, ranges, data.position(1,:), data.grp);

    prog(0.75, "Finished azimuth compression");

    interms.range_compressed = data;
    interms.range_compressed.values = samples_cT;

    interms.rangedop = data;
    interms.rangedop.values = samples_cF;

    interms.rangedop_rcmc = data;
    interms.rangedop_rcmc.values = samples_rcmc_cF;
end
