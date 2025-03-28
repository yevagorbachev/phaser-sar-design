%% Generate phase history
clear;
link_budget;

set(groot, "DefaultAxesNextPlot", "add");
set(groot, "DefaultAxesXGrid", "on");
set(groot, "DefaultAxesYGrid", "on");

% enable or disable plots
plot_laydown = true;
add_noise = false;

radio.wavelength = wavelength;
radio.sample_freq = 10*center_freq;
pulse_time = (0:(1/radio.sample_freq):pulse_width)';
radio.pulse = cos(2*pi*center_freq*pulse_time + ...
    pi*(bandwidth/pulse_width)*(pulse_time - mean(pulse_time)).^2);

radio.f_tx_gain = ant_rectangular([D_az_tx, D_el_tx] / wavelength, eff_tx);
radio.f_rx_gain = ant_rectangular([D_az_rx, D_el_rx] / wavelength, eff_rx);

aperture.ground_range = grp_range;
aperture.altitude = platform_height;
aperture.scene_dims = [scene_width; scene_length];
aperture.speed = platform_spd;
aperture.pulse_rate = F_prf;

targets.position = grp_targets([0; aperture.ground_range; 0], ...
    [0 0], [-2 0], [2 0], [0 -2], [0 2], [7.5 0]);
targets.rcs = [1 0 0 1 1 0];

if plot_laydown
    figure(name = "Laydown");

    rcs_dB = db10(targets.rcs);
    for i_target = find(targets.rcs)
        x = targets.position(:, i_target);
        display_rcs = rcs_dB(i_target)/5 + 2;
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

slant_range = sqrt(aperture.altitude.^2 + aperture.ground_range.^2);
grp_time = 2*slant_range/c;
local_osc = exp(1j*(2*pi*center_freq*pulse_time + ...
    pi*(bandwidth/pulse_width)*(pulse_time - mean(pulse_time)).^2));

rx_rate = 20e6;
% mix
local_osc = interp1(pulse_time + grp_time, local_osc, fast_time, "linear", 0);
mixed = samples .* local_osc;
dechirped = lowpass(mixed, rx_rate, radio.sample_freq);

% sample
sampled = movsum(dechirped, seconds(1/rx_rate), 1, ...
    SamplePoints = seconds(fast_time), Endpoints = "shrink");
rx_fast_time = (fast_time(1):(1/rx_rate):fast_time(end))';
sampled = interp1(fast_time, sampled, rx_fast_time, "linear", 0);


figure(name = "Dechirped phase history");
tiledlayout(1,2);

nexttile;
title("Carrier-band")
phplot(dechirped, 1e9*fast_time, slow_time, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");

nexttile;
title("Sampled")
phplot(sampled, 1e9*rx_fast_time, slow_time, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");

figure(name = "Approximate PFA");
inv = ifftshift(ifftshift(ifft2(sampled), 1), 2);
phplot(inv, 1e9*rx_fast_time, slow_time, "abs");
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");

