%% Generate phase history
clear;
link_budget;

set(groot, "DefaultAxesNextPlot", "add");
set(groot, "DefaultAxesXGrid", "on");
set(groot, "DefaultAxesYGrid", "on");

% enable or disable plots
plot_laydown = true;
add_noise = true;
plot_interm = true;

radio.wavelength = wavelength;
radio.sample_freq = 2*bandwidth;
radio.pulse = idealLFM(bandwidth, pulse_width, radio.sample_freq);
radio.f_tx_gain = ant_rectangular([D_az_tx, D_el_tx] / wavelength, eff_tx);
radio.f_rx_gain = ant_rectangular([D_az_rx, D_el_rx] / wavelength, eff_rx);

aperture.ground_range = grp_range;
aperture.altitude = platform_height;
aperture.scene_dims = [scene_width; scene_length];
aperture.speed = platform_spd;
aperture.pulse_rate = F_prf;


targets.position = grp_targets([0; aperture.ground_range; 0], ...
    [0 0], [-4 0], [4 0], [0 -4], [0 4], [7.5 0]);
targets.rcs = [1 1 1 1 1 1];

if plot_laydown
    figure(name = "Laydown");

    rcs_dB = db10(targets.rcs);
    for i_target = 1:size(targets.position, 2)
        x = targets.position(:, i_target);
        display_rcs = (rcs_dB(i_target) - min(rcs_dB))/5 + 2;
        plot(x(1), x(2), "+", LineWidth = display_rcs, MarkerSize = 10 + display_rcs, ...
            DisplayName = sprintf("Target %d", i_target));

        xlabel("Cross range [m]");
        ylabel("Ground range [m]");
        daspect([1 1 1]);
    end
    legend;

    rect_x = aperture.scene_dims(1) * [-1/2 1/2];
    rect_y = aperture.ground_range + aperture.scene_dims(2) * [-1/2 1/2];
    rectangle(Position = [rect_x(1) rect_y(1) diff(rect_x) diff(rect_y)]);

    [x_min, x_max] = bounds(targets.position(1, :));
    [y_min, y_max] = bounds(targets.position(2, :));
    xlim([x_min x_max] + (x_max - x_min)/3 * [-1 1]) ;
    ylim([y_min y_max] + (y_max - y_min)/3 * [-1 1]);

    figure(name = "Antenna patterns");
    layout = tiledlayout(1,2);
    sgtitle("Antenna patterns");

    angle_max = deg2rad(20); 
    angles = linspace(-angle_max, angle_max, 100);

    nexttile(1);
    title("Transmit");
    plot(rad2deg(angles), db10(radio.f_tx_gain(angles, 0)), DisplayName = "Azimuth");
    plot(rad2deg(angles), db10(radio.f_tx_gain(0, angles)), DisplayName = "Elevation");
    legend(Location = "northoutside", Orientation = "horizontal");
    ylabel("Gain [dB]");
    xlabel("Angle [deg]");

    ax_el = nexttile(2);
    title("Recieve");
    plot(rad2deg(angles), db10(radio.f_rx_gain(angles, 0)), DisplayName = "Azimuth");
    plot(rad2deg(angles), db10(radio.f_rx_gain(0, angles)), DisplayName = "Elevation");
    legend(Location = "northoutside", Orientation = "horizontal");
    ylabel("Gain [dB]");
    xlabel("Angle [deg]");

    layout.TileSpacing = "compact";
end

[samples, fast_time, slow_time] = stripmap_phase_history(aperture, radio, targets);

if add_noise
    figure(name = "Raw phase history");
    tiledlayout(1, 2);

    nexttile;
    title("Clean phase");
    phplot(samples, 1e9*fast_time, slow_time, "re");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");

    amps = adl8107 + adl8107 + hmc451 + ad9363;
    samples = samples .* amps.gain;
    noise = wgn(size(samples,1), size(samples,2), N_thermal_dBm + nf - 30, "complex");
    samples = samples + noise;

    nexttile;
    title("Noisy phase");
    phplot(samples, 1e9*fast_time, slow_time, "re");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
end

[rda_image, scene_fast_time, slow_time, interms] = ifp_rda(samples, fast_time, slow_time, radio.pulse, ...
        platform_spd, sqrt(platform_height.^2 + grp_range.^2), radio.wavelength);

slant_range = c*scene_fast_time/2;
cross_range = slow_time * aperture.speed;
ground_range = sqrt(slant_range.^2 - aperture.altitude^2);
ground_grp_range = ground_range - aperture.ground_range;

if plot_interm
    dynr = db20(bandwidth * pulse_width) + 10; 
    figure(name = "Intermediate results");
    tiledlayout(1,2);
    nexttile;
    phplot(interms.range_compressed, 1e9*scene_fast_time, slow_time, "log", dynr);
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
    title("Range-compressed phase history");

    nexttile;
    phplot(interms.rangedop, 1e9*scene_fast_time, ...
        freqaxis(F_prf, size(interms.rangedop, 2)), "log");
    xlabel("Doppler [Hz]");
    ylabel("Fast-time [ns]");
    title("Range-Doppler map")
end

figure(name = "Azimuth compressed phase history");

tiledlayout(1,2);

nexttile;
phplot(rda_image, ground_range, cross_range, "abs");
xlabel("Cross range [m]");
ylabel("Ground range [m]");
daspect([1 1 1])
title("Linear scale");

nexttile;
phplot(rda_image, ground_range, cross_range, "log");
xlabel("Cross range [m]");
ylabel("Ground range [m]");
daspect([1 1 1])
title("Log scale");

