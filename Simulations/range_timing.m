c = 299792458; % [m/s] speed of light
f_c = 10.25e9; % [Hz] RF center frequency
f_s = 40e6;
bandwidth = 250e6; % [Hz] bandwidth
slant_grp = 75; % [m] GRP range
slant_len = 10; % [m] scene length

t_grp = 2*slant_grp/c;
t_swath = 2*slant_len/c;
tau_p = t_grp;

chirp_rate = bandwidth/tau_p;

tx = waveform(chirp_rate * (0:(1/(10*f_s)):tau_p), 10*f_s);
tx = tx + seconds(-tau_p/2);
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

plot(tx - rx_grp, DisplayName = "GRP return");
plot(tx - rx_close, DisplayName = "Near-range return");
plot(tx - rx_far, DisplayName = "Far-range return");

yline(f_s/2, "--k", "Limit", HandleVisibility = "off");
yline(-f_s/2, "--k", "Limit", HandleVisibility = "off");
xregion(seconds(t_grp + [t_swath/2-tau_p/2 tau_p/2-t_swath/2]), ...
    DisplayName = "Processing interval");

legend;

linkaxes([ax1 ax2 ax3], "xy");
