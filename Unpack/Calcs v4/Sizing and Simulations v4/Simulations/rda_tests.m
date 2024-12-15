close all; clear;
sim_set = "hw4";
hw4_data = proj_file("Simulations", "sample_data", "hw4_synthetic_phist_and_meta.mat");
vanc_data = proj_file("Simulations", "sample_data", "radarsat1_vancouver_phist.mat");
switch sim_set
%% Simulated phase history
    case "hw4"
        raw = load(hw4_data);
        samples_tT = raw.simsar_output.data;

        c = 299792458;
        f_c = 5.3e9;
        K_r = 20e6/1e-6;
        tau = 2.5e-6;
        R_0 = 20e3;
        spd = 150;
        f_s = 60e6;
        F_prf = 100;
    case "vancouver"
        raw = load(vanc_data);
        samples_tT = raw.data_raw;

        c = 299792458;
        f_c = 5.3e9;
        K_r = -7.2135e11;
        tau = 41.75e-6;
        R_0 = 988.6475e3;
        spd = 7062;
        f_s = 32.3170e6;
        F_prf = 1256.980;
    otherwise
        error("Case not recognized")
end

lambda = c / f_c;
B = tau*K_r;
[n_fast, N_slow] = size(samples_tT);

t_fast = 2*R_0/c + linspace(-n_fast/2, n_fast/2, n_fast) / f_s;
T_slow = linspace(-N_slow/2, N_slow/2, N_slow) / F_prf;
[synth_image, interms] = ifp_rda(samples_tT, t_fast', B, tau, ...
    T_slow, spd, R_0, lambda);

figure(name = "Raw phase history");
phplot(samples_tT, 1e6*t_fast, T_slow, "re");
xlabel("Slow-time [s]");
ylabel("Fast-time [\mu s]");

figure(name = "Intermediate results");
tiledlayout(1,2);
nexttile;
phplot(interms.range_compressed_tT, 1e6*t_fast, T_slow, "log", 80);
xlabel("Slow-time [s]");
ylabel("Fast-time [\mu s]");
title("Range-compressed phase history");

nexttile;
phplot(interms.rangedop_tF, 1e6*t_fast, ...
    freqaxis(F_prf, size(interms.rangedop_tF, 2)), "log", 60);
xlabel("Doppler [Hz]");
ylabel("Fast-time [\mu s]");
title("Range-Doppler map")

figure(name = "Azimuth compressed phase history");
phplot(synth_image, ( c*t_fast/2 - R_0 ) / cosd(40), spd*T_slow, "log", 60);
xlabel("Cross-range [m]");
ylabel("Ground range [m]");
axis equal;
