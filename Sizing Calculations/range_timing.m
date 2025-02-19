clear;
c = 299792458; % [m/s] speed of light
f_c = 10.25e9; % [Hz] RF center frequency
tx_bandwidth = 150e6; % [Hz] Transmitted chirp width
rx_bandwidth = 20e6; % [Hz] Receiver bandwidth
slant_grp = 75; % [m] GRP range
slant_len = 10; % [m] scene length

t_grp = 2*slant_grp/c;
t_swath = 2*slant_len/c;
tau = t_grp;

chirp_rate = tx_bandwidth/tau;
image_bandwidth = tx_bandwidth * (tau - t_swath) / tau;

fprintf("Bandwidth in image: %.0f MHz\n", image_bandwidth / 1e6);
fprintf("Maximum receiver bandwidth: %.0f MHz\n", rx_bandwidth / 1e6)
fprintf("Actual receiver bandwidth: %.0f MHz\n", chirp_rate * t_swath / 1e6)

tx = waveform(chirp_rate * (0:(1/rx_bandwidth/10):tau), 10*rx_bandwidth);
% tx = tx + seconds(-tau/2);
tx = tx + (tx + seconds(t_grp));

rx_grp = tx + seconds(t_grp);
rx_far = tx + seconds(t_grp + t_swath/2);
rx_close = tx + seconds(t_grp - t_swath/2);

figure;
tiledlayout(3,1);
sgtitle("Pulse timing diagram");

ax1 = nexttile;
hold on; grid on;
title("LO frequency");
plot(tx, DisplayName = "tx");

ax2 = nexttile;
hold on; grid on;
title("Return frequencies");
plot(rx_grp, DisplayName = "GRP return");
plot(rx_close, DisplayName = "Near-range return");
plot(rx_far, DisplayName = "Far-range return");

ax3 = nexttile;
hold on; grid on;
title("Beat frequencies (LO - Rx)");

plot(rx_grp - tx, DisplayName = "GRP return");
plot(rx_close - tx, DisplayName = "Near-range return");
plot(rx_far - tx, DisplayName = "Far-range return");

yline(rx_bandwidth/2 * [-1 1], "--k", DisplayName = "Radio bandwidth");
% yline(rx_bandwidth/2, "--k", "Limit", HandleVisibility = "off");
% yline(-rx_bandwidth/2, "--k", "Limit", HandleVisibility = "off");
xregion(seconds(t_grp + [t_swath/2 tau-t_swath/2]), ...
    DisplayName = "Processing interval");

legend;

linkaxes([ax1 ax2 ax3], "xy");
