%% Define parameters and geerate aperture
clear;
link_budget;

set(groot, "DefaultAxesNextPlot", "add");
plot_raw = true;
add_noise = false;
plot_interm = true;

aperture.altitude = platform_height;
aperture.ground_range = grp_range;
aperture.scene_dims = [scene_width; scene_length];
aperture.speed = platform_spd;
aperture.pulse_rate = F_prf;

radio.wavelength = wavelength;
radio.sample_freq = 2*bandwidth;
radio.pulse = idealLFM(bandwidth, pulse_width, radio.sample_freq);
radio.f_tx_gain = ant_rectangular([D_az_tx, D_el_tx] / wavelength, eff_tx);
radio.f_rx_gain = ant_rectangular([D_az_rx, D_el_rx] / wavelength, eff_rx);

targets.position = grp_targets([0; aperture.ground_range; 0], ...
    [0 0], [-4 0], [4 0], [0 -4], [0 4], [7.5 0]);
targets.rcs = [0 0 0 1 1 0];

[samples, fast_time, slow_time] = stripmap_phase_history(aperture, radio, targets);

% amps = adl8107 + adl8107 + hmc451;
% gn = amps.gain + 50;
% samples = samples .* gn;

if plot_raw
    figure(name = "Raw phase history");
    title("Simulated phase");
    phplot(samples, 1e9*fast_time, slow_time, "re");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
end

if add_noise
    noise = wgn(size(samples,1), size(samples,2), N_thermal_dBm - 30, "complex");
    samples = samples + noise;

    figure(name = "Noisy phase history");
    title("Simulated phase");
    phplot(samples, 1e9*fast_time, slow_time, "re");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
end

[synth_image, fast_time, slow_time, interms] = ifp_rda(samples, fast_time, slow_time, radio.pulse, ...
    platform_spd, sqrt(platform_height.^2 + grp_range.^2), radio.wavelength);

slant_range = c*fast_time/2;
cross_range = slow_time * aperture.speed;
ground_range = sqrt(slant_range.^2 - aperture.altitude^2);
ground_grp_range = ground_range - aperture.ground_range;

if plot_interm
    dynr = db20(bandwidth * pulse_width) + 10; 
    figure(name = "Intermediate results");
    tiledlayout(1,2);
    nexttile;
    phplot(interms.range_compressed, 1e9*fast_time, slow_time, "log", dynr);
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
    title("Range-compressed phase history");

    nexttile;
    phplot(interms.rangedop, 1e9*fast_time, ...
        freqaxis(F_prf, size(interms.rangedop, 2)), "log");
    xlabel("Doppler [Hz]");
    ylabel("Fast-time [ns]");
    title("Range-Doppler map")
end

figure(name = "Azimuth compressed phase history");

tiledlayout(1,2);

nexttile;
phplot(synth_image, slant_range, cross_range, "abs");
xlabel("Cross range [m]");
ylabel("Slant range [m]");
title("Linear scale");

nexttile;
phplot(synth_image, slant_range, cross_range, "log");
xlabel("Cross range [m]");
ylabel("Slant range [m]");
title("Log scale");

sample_times = fast_time - grp_time;
t_lessfast = fast_time(1):(1/40e6):fast_time(end);
mixing_chirp = interp1((1:length(radio.pulse)) - 1, radio.pulse, sample_times * radio.sample_freq, ...
    "linear", 0);
% mixing_chirp = interp1(radio.pulse, (sample_times * radio.sample_freq)-1, "linear", 0);
mixed = samples .* mixing_chirp;
% dechirped = lowpass(mixed, 30e6, radio.sample_freq);
dechirped = mixed;
% dechirped = interp1(fast_time, dechirped, t_lessfast);

figure(name = "Dechirped phase history");
phplot(dechirped, fast_time*1e9, slow_time, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");
title("Simulated dechirped phase")

figure(name = "IFFT");
phplot(ifftshift(ifftshift(ifft2(dechirped), 1), 2), ...
    slant_range, cross_range, "abs");
xlabel("Cross range [m]");
ylabel("Slant range [m]");
title("IFFT")

% samp_ranges = c*fast_time/2;
% samp_xranges = x_positions;
% [binned_rx, ranges, xranges] = bin_samples(samples_tT, samp_ranges, ...
%     samp_xranges, range_res, xrange_res);
%
% nexttile;
% phplot(binned_rx, ranges, xranges, "log");
% xlabel("Cross-range [m]");
% xlim(spd*slow_time([1 end]));
% ylabel("Ground range [m]");
% axis equal;
% title("Binned energies");

