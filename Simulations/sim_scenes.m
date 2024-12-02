clear; 
c= 299729458;
k = 1.3086e-23;

scene = "midterm";
% scene = "rit"

switch scene
    case "hw4"
        f_c = 5.3e9;
        tau = 2.5e-6;
        K_r = 20e6/1e-6;
        B = K_r*tau;
        f_s = 60e6;
        F_prf = 100;

        D_az = 0.25;
        D_el = 0.25;
        eff = 1;

        n_fast = 383;
        R_0 = 20e3;
        grazing = deg2rad(40);
        h = R_0 * sin(grazing);
        R_min = R_0 - c*(n_fast/2/f_s)/2;
        R_max = R_0 + c*(n_fast/2/f_s)/2;

        L_0 = sqrt(R_0^2 - h^2);
        L_min = sqrt(R_min^2 - h^2);
        L_max = sqrt(R_max^2 - h^2);

        N_slow = 256;
        spd = 150;
        S = spd*(N_slow-1)/F_prf;
        S_min = -S/2;
        S_max = S/2;

        targets.X_aN = [0; L_0; 0] + [-50 -50 0 50; 50 -50 0 50; 0 0 0 0];
        targets.sig_N = [1 1 1 1];
    case "midterm"
        f_c = 10e9;
        tau = 10e-6;
        B = 150e6;
        f_s = 1.4*B;
        F_prf = 500;

        h = 7620;
        L_0 = 13e3;
        L_min = L_0 - 1.5e3;
        L_max = L_0 + 1.5e3;
        S_min = -500;
        S_max = 500;
        spd = 140;

        D_az = 1.62;
        D_el = 254e-3;
        eff = 0.7;

        targets.X_aN = [0; L_0; 0] + [-50 -50 0 50; 50 -50 0 50; 0 0 0 0];
        targets.sig_N = [1 1 1 1];
    % case "rit"
    %
    %     h = 20;
    %     L_0 = 75;
    %     L_min = 50;
    %     L_max = 100;
    %     S_min = -5;
    %     S_max = 5;
    %     spd = 0.1;
    %
    %     target.X_aN = [-50 -50 0 50; 50 -50 0 50; 0 0 0 0];
    %     targets.sig_1N = [1 1 1 1];
        
    otherwise 
        error("Scene not defined")
end


radar.lambda = c/f_c;
radar.tau = tau;
radar.B = B;
radar.f_s = f_s;

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

figure(name = "Raw phase history");
phplot(samples_tT, 1e6*t_fast, T_slow, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [\mu s]");

[synth_image, interms] = ifp_rda(samples_tT, t_fast, B, tau, ...
    T_slow, spd, R_0, radar.lambda);

figure(name = "Intermediate results");
tiledlayout(1,2);
nexttile;
phplot(interms.range_compressed_tT, 1e6*t_fast, T_slow, "log", db20(125));
xlabel("Slow-time [s]");
ylabel("Fast-time [\mu s]");
title("Range-compressed phase history");

nexttile;
phplot(interms.rangedop_tF, 1e6*t_fast, ...
    freqaxis(F_prf, size(interms.rangedop_tF, 2)), "log", db20(125));
xlabel("Doppler [Hz]");
ylabel("Fast-time [\mu s]");
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
phplot(synth_image, ( c*t_fast/2 - R_0 ) / cosd(40), spd*T_slow, "log", db20(125));
xlabel("Cross-range [m]");
ylabel("Ground range [m]");
axis equal;
