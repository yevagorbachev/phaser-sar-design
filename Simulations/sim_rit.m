%% Define parameters and generate aperture
clear;
link_budget;

set(groot, "DefaultAxesNextPlot", "add");
plot_laydown = true;
plot_raw = true;
plot_real = true;
plot_result = true;

radar.wavelength = lam_c;
[radar.pulse, radar.sample_freq] = idealLFM(BW, PW);

aperture.X_range = aperture_width * [-1/2 1/2];
aperture.L_range = [min_range, max_range];
[aperture.platform_position, aperture.platform_velocity, ...
    aperture.platform_look, aperture.t_range, aperture.T_range] = ...
    ap_stripmap(platform_height, aperture.X_range, aperture.L_range, v, F_prf);

aperture.tx_antenna_gain = ant_rectangular([D_az_tx, D_el_tx] / lam_c, eff_tx);
aperture.rx_antenna_gain = ant_rectangular([D_az_rx, D_el_rx] / lam_c, eff_rx);

aperture.grp_posn = [0; mean([min_range, max_range]); 0];
targets.target_position = grp_targets(aperture.grp_posn, [0 0], [-1.5 0], [7.5 0]);
targets.target_RCS = [1 1 1];

if plot_laydown
    figure(name = "Laydown");

    for i_tgt = size(targets.target_position, 2)
        plot3(targets.target_position(1, i_tgt), ...
            targets.target_position(2, i_tgt), ...
            targets.target_position(3, i_tgt), ...
            "+", LineWidth = 1.5, DisplayName = sprintf("Target %d", i_tgt));
    end

    plot3(aperture.platform_position(1, :), ...
        aperture.platform_position(2, :), ...
        aperture.platform_position(3, :), ...
        "-r", LineWidth = 1.5, DisplayName = "Aperture");

    xlabel("Coss-range [m]");
    ylabel("Range [m]");
    zlabel("Altitude [m]");
    legend;
    view([45 20]);
    daspect([1 1 1]);

    figure(name = "Antenna patterns")
    layout = tiledlayout(1,2);
    sgtitle("Antenna patterns");

    angle_max = deg2rad(30); 
    angles = linspace(-angle_max, angle_max, 100);

    ax_az = nexttile(1);
    title("Azimuth");
    plot(rad2deg(angles), db10(aperture.tx_antenna_gain(angles, 0)), DisplayName = "Transmit");
    plot(rad2deg(angles), db10(aperture.rx_antenna_gain(angles, 0)), DisplayName = "Receive");
    legend(Location = "northoutside", Orientation = "horizontal");
    ylabel("Gain [dB]");
    xlabel("Azimuth angle [deg]");

    ax_el = nexttile(2);
    title("Elevation");
    plot(rad2deg(angles), db10(aperture.tx_antenna_gain(0, angles)), DisplayName = "Transmit");
    plot(rad2deg(angles), db10(aperture.rx_antenna_gain(0, angles)), DisplayName = "Receive");
    legend(Location = "northoutside", Orientation = "horizontal");
    xlabel("Elevation angle [deg]");

    linkaxes([ax_az, ax_el], "y");
    ylim([ax_az.YLim(2) - 50, ax_az.YLim(2)]);
    layout.TileSpacing = "compact";
end

[samples, t_fast, T_slow] = simulate_phase_history(radar, aperture, targets);
amps = adl8107 + adl8107 + hmc451;
gn = amps.gain + 50;
samples = samples .* gn;

if plot_raw
    figure(name = "Raw phase history");
    title("Simulated phase");
    phplot(samples, 1e9*t_fast, T_slow, "re");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
end

noise = wgn(size(samples,1), size(samples,2), N_thermal_dBm - 30, "complex");
samples = samples + noise;

figure(name = "Noisy phase history");
title("Simulated phase");
phplot(samples, 1e9*t_fast, T_slow, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");

[synth_image, interms] = ifp_rda(samples, t_fast, radar.pulse, radar.sample_freq, ...
    T_slow, v, sqrt(platform_height.^2 + (min_range + max_range)^2/4), radar.wavelength);

dynr = db20(BW * PW) + 10;
figure(name = "Intermediate results");
tiledlayout(1,2);
nexttile;
phplot(interms.range_compressed, 1e9*t_fast, T_slow, "log", dynr);
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");
title("Range-compressed phase history");

nexttile;
phplot(interms.rangedop, 1e9*t_fast, ...
    freqaxis(F_prf, size(interms.rangedop, 2)), "log");
xlabel("Doppler [Hz]");
ylabel("Fast-time [ns]");
title("Range-Doppler map")

figure(name = "Azimuth compressed phase history");

tiledlayout(1,2);

nexttile;
phplot(synth_image, t_fast, T_slow, "abs");
xlabel("Cross-range [m]");
ylabel("Ground range [m]");
title("Linear scale");

nexttile;
phplot(synth_image, t_fast, T_slow, "log");
xlabel("Cross-range [m]");
ylabel("Ground range [m]");
title("Log scale");

% samp_ranges = c*t_fast/2;
% samp_xranges = x_positions;
% [binned_rx, ranges, xranges] = bin_samples(samples_tT, samp_ranges, ...
%     samp_xranges, range_res, xrange_res);
%
% nexttile;
% phplot(binned_rx, ranges, xranges, "log");
% xlabel("Cross-range [m]");
% xlim(spd*T_slow([1 end]));
% ylabel("Ground range [m]");
% axis equal;
% title("Binned energies");

