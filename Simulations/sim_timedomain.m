% Generate phase history
clear;

c = 299792458;
k = 1.38e-23; % [Js/K] boltzmann's constant
% enable or disable plots
plot_laydown = true;
add_noise = true;
plot_interm = true;

pulse_width = 10e-6;
bandwidth = 150e6;
radio.wavelength = 0.0333;
radio.sample_freq = 210e6;
radio.ramp_rate = 150e6/10e-6;
radio.ramp_time = pulse_width;
dims = [1.62 0.254]; % [m] [az, el]
efficiency = 0.7;
radio.f_tx_gain = ant_rectangular(dims / radio.wavelength, efficiency);
radio.f_rx_gain = ant_rectangular(dims / radio.wavelength, efficiency);

aperture.ground_range = 12.9e3;
aperture.altitude = 7620;
aperture.scene_dims = [1000; 100];
aperture.speed = 150;
aperture.pulse_rate = 500;

r_grp = [0; aperture.ground_range; 0];
targets(1).position = r_grp + [0; 0; 0];
targets(1).rcs = 1;
targets(2).position = r_grp + [50; 50; 0];
targets(2).rcs = 1;
targets(3).position = r_grp + [-50; 0; 0];
targets(3).rcs = 1;
targets(4).position = r_grp + [0; 50; 0];
targets(4).rcs = 1;

if plot_laydown
    % figure(name = "Laydown");

    % rcs_dB = db10(targets.rcs);
    % for i_target = find(targets.rcs)
    %     x = targets.position(:, i_target);
    %     display_rcs = 1;%(rcs_dB(i_target) - min(rcs_dB))/5 + 2;
    %     plot(x(1), x(2), "+", LineWidth = display_rcs, MarkerSize = 10 + display_rcs, ...
    %         DisplayName = sprintf("Target %d", i_target));
    %
    %     xlabel("Cross range [m]");
    %     ylabel("Ground range [m]");
    %     daspect([1 1 1]);
    % end
    % legend;
    %
    % rect_x = aperture.scene_dims(1) * [-1/2 1/2];
    % rect_y = aperture.ground_range + aperture.scene_dims(2) * [-1/2 1/2];
    % rectangle(Position = [rect_x(1) rect_y(1) diff(rect_x) diff(rect_y)]);
    %
    % [x_min, x_max] = bounds(targets.position(1, :));
    % [y_min, y_max] = bounds(targets.position(2, :));
    % xlim([x_min x_max] + (x_max - x_min)/3 * [-1 1]) ;
    % ylim([y_min y_max] + (y_max - y_min)/3 * [-1 1]);

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

data = stripmap_phase_history(aperture, radio, targets);

[image, interms] = ifp_rda(data);

figure(name = "Range-compressed data");
plot(interms.range_compressed, scale = "log", range = "time", cross = "time");

figure(name = "Range-Doppler images");
tiledlayout(1,2);

nexttile;
plot(interms.rangedop, scale = "log", range = "time", cross = "index");
title("Range-Doppler image");
nexttile;
plot(interms.rangedop_rcmc, scale = "log", range = "time", cross = "index");
title("RCMC Range-Doppler image")


figure(name = "Formed image");
tiledlayout(1,2);
nexttile;
plot(image, scale = "abs", range = "grp", cross = "grp");
title("Magnitude plot")
nexttile;
plot(image, scale = "log", range = "grp", cross = "grp", dynamic = 30);
title("Logarithmic plot")

return;
if add_noise
    figure(name = "Raw phase history");
    tiledlayout(1, 2);

    nexttile;
    title("Clean phase");
    phplot(samples, 1e9*fast_time, slow_time, "im");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");

    amps = adl8107 + adl8107 + hmc451 + ad9363;
    samples = samples .* amps.gain;
    noise = wgn(size(samples,1), size(samples,2), N_thermal_dBm + nf - 30, "complex");
    samples = samples + noise;

    nexttile;
    title("Noisy phase");
    phplot(samples, 1e9*fast_time, slow_time, "im");
    xlabel("Slow-time [s]");
    ylabel("Fast-time [ns]");
end
