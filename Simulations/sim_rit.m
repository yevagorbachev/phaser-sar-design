%% Define parameters and generate aperture
clear;
link_budget;

h = platform_height;
S_min = -aperture_width/2;
S_max = aperture_width/2;
L_0 = mean([min_range max_range]);
L_min = min_range;
L_max = max_range;
spd = v;

radar.lambda = c/f_c;
radar.tau = PW;
radar.B = BW;
radar.f_s = 2^nextpow2(1.2*BW);

D_az = 0.1;
D_el = 0.1;
eff = 0.2;

aperture.F_prf = F_prf;
x_positions = S_min:(spd/F_prf):S_max;
aperture.X_aT = [x_positions; zeros(size(x_positions)); repmat(h, size(x_positions))];
aperture.V_aT = [spd; 0; 0];
aperture.t_min = 2*sqrt(L_min^2 + h^2)/c;
aperture.t_max = 2*sqrt(L_max^2 + h^2)/c;

R_0 = sqrt(h^2 + mean([L_min L_max]).^2);
grazing = atan(h / (mean([L_min L_max])));

aperture.look_aaT = [1 0 0;
    0 cos(grazing) -sin(grazing); 
    0 sin(grazing) cos(grazing)];

aperture.G_ant = @(sin_az, sin_el) 4*pi*D_az*D_el*eff/radar.lambda.^2 * ...
    sinc(D_az / radar.lambda * sin_az) .^ 2 .* ...
    sinc(D_el / radar.lambda * sin_el) .^ 2;

targets.X_aN = [0; L_0; 0] + [-2.5 -2.5 0 2.5 7.5; 2.5 -2.5 0 2.5 0; 0 0 0 0 0];
targets.sig_N = [1 1 1 1 1];
        
%% Simulate scene
figure(name = "3D view");
for ti = 1:size(targets.X_aN, 2)
    plot3(targets.X_aN(1, ti), targets.X_aN(2, ti), targets.X_aN(3, ti), ...
        "+", LineWidth = 2, DisplayName = sprintf("Target %d", ti));
end
plot3(aperture.X_aT(1, :), aperture.X_aT(2, :), aperture.X_aT(3, :), ...
    "-k", DisplayName = "Aperture");
ground_area = [S_min S_min S_max S_max S_min; 
    L_min L_max L_max L_min L_min; 
    0 0 0 0 0];
plot3(ground_area(1, :), ground_area(2, :), ground_area(3, :),...
    "--k", HandleVisibility = "off");

xlabel("Coss-range [m]");
ylabel("Range [m]");
zlabel("Altitude [m]");
legend;
view([45 20]);

[samples_tT, t_fast, T_slow, aux] = simulate_phase_history(radar, aperture, targets);

amps = cable + fmam1087 + cable + fmam63018 + cable + fmam63018 + cable;
P_dB = P_tx_radio_dBm + sum(amps.stages.gain) - 30;
samples_tT = samples_tT * mag20(P_dB);

B_n = radar.f_s;
P_n = k*T*B_n * mag10(NF_radio_dB + nf);

make_noise = memoize(@wgn);
noise_tT = make_noise(size(samples_tT, 1), size(samples_tT, 2), db10(P_n), "complex");
samples_tT = samples_tT + noise_tT;

%% Process phase history

cgain = db20(radar.B*radar.tau);
figure(name = "Raw phase history");
phplot(samples_tT, 1e9*t_fast, T_slow, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");

[synth_image, interms] = ifp_rda(samples_tT, t_fast, radar.B, radar.tau, ...
    T_slow, spd, R_0, radar.lambda);

figure(name = "Intermediate results");
tiledlayout(1,2);
nexttile;
phplot(interms.range_compressed_tT, 1e9*t_fast, T_slow, "log", cgain);
xlabel("Slow-time [s]");
ylabel("Fast-time [ns]");
title("Range-compressed phase history");

nexttile;
phplot(interms.rangedop_tF, 1e9*t_fast, ...
    freqaxis(F_prf, size(interms.rangedop_tF, 2)), "log", cgain);
xlabel("Doppler [Hz]");
ylabel("Fast-time [ns]");
title("Range-Doppler map")

figure(name = "Target modulation")
tiledlayout(2,1)
nexttile;
plot(T_slow, aux.F_dop);
xlabel("Slow-time [s]"); ylabel("Doppler [Hz]");
title("Doppler trajectories")

nexttile;
plot(T_slow, db10(aux.G_ant));
xlabel("Slow-time [s]"); ylabel("Gain [dB]");
title("Antenna gain");

figure(name = "Azimuth compressed phase history");
phplot(synth_image, ( c*t_fast/2 - R_0 ) / cos(grazing), spd*T_slow, "log", cgain);
xlabel("Cross-range [m]");
ylabel("Ground range [m]");
axis equal;
