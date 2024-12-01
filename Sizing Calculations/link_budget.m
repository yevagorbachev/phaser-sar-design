%% Link budget
% Assign physical parameters and requirements
% Find required gain (amplifiers + antennas) for given scene
% Calculate actual gain for specified hardware
% 
% P22714 Multifrequency SAR 
% Yevgeniy Gorbachev - Fall 2024 

clear;

%% Constants
c = 299792458;
k = 1.3806e-23;
T = 273.15 + 40; % [K] reciever temperature (from 40C)

%% Customer Requirements
range_res_req = 1; % [m]
xrange_res_req = 1; % [m]
min_range = 50; % [m]
max_range = 100; % [m]
aperture_width = 10; % [m]
platform_height = 20; % [m]
target_rcs_dBsm = 5; % [dBsm] car radar cross section

range = sqrt(platform_height ^ 2 + max_range ^ 2);
theta = atan(aperture_width / range); % rad
grazing_min = atand(platform_height / max_range); % [deg]
grazing_max = atand(platform_height / min_range); % [deg]
el_beam_min = grazing_max - grazing_min; % [deg]

PW_max = (2*min_range/c) /2;
PRF_max = 1 / ((2*max_range/c) + PW_max);

%% Frequency allocation
f_c = 3.2e9; % [Hz] center frequency
lam_c = c/f_c; % [m] wavelength
BW = 200e6; % [Hz] bandwidth

%% Aperture parameters
% Performance metrics
xrange_res = lam_c / (2*theta); % [m]
range_res = c/(2*BW); % [m]

% Coherent processing 
v = 0.1; % [m/s] platform velocity
PW = 150e-9; % [s] pulse width
B_dop = 2*v/lam_c; % [s] Doppler bandwidth without accounting for beam (forward/backward)
F_prf_min = B_dop*1.4; % [Hz] pulse rep. frequency
F_prf = 100;
T_CPI = aperture_width / v; % [s] Coherent processing time
% NOTE: Signal processing gains are db20 because they are voltage-like
G_CPI_dB = db20(T_CPI * F_prf); % Coherent processing gain 
G_chirp_dB = db20(PW * BW); % Pulse compression gain 

% Environment effects
G_path_dB = db10(lam_c^2 / ((4*pi)^3 * range^4));
% Two-way Friis without G or P

%% Radio Parameters
% if make_radio_data or x440_data are modified, use clearCache(load_radio_data) to refresh.
load_radio_data = memoize(@make_radio_data); % so that repeated runs use cached results
radio_data = load_radio_data(proj_file("Data", "x440_data.xlsx"));

P_tx_radio_dBm = -27;
N_thermal_dBm = db10(k*T*BW) + 30; % dBW to dBm
N_radio_dBm = radio_data.rx_noise_psd(f_c) + db10(BW);
NF_radio_dB = N_radio_dBm - N_thermal_dBm;

%% Hardware parameters
NF_amp_dB = 3 * 3; % [dB] Three 3dB amplifier stages
L_coax_dB = 6 * 1; % [dB] insertion loss of 6 coaxial cables
VSWR = 2;
refl = (VSWR - 1) / (VSWR + 1);
L_swr_dB = -db10(1 - refl^2); % Antenna SWR mismatch

L_total = L_coax_dB + L_swr_dB;

%% Required Link Budget
P_rx_radio_req_dBm = 10 + radio_data.rx_fs(f_c) - db20(2^12);

signal_budget = table(Size = [0 3], ...
    VariableTypes = ["string", "double", "string"], ...
    VariableNames = ["Parameter", "Value", "Unit"]);
noise_budget = table(Size = [0 3], ...
    VariableTypes = ["string", "double", "string"], ...
    VariableNames = ["Parameter", "Value", "Unit"]);

% signal_budget(end+1, :) = {"Required return", P_rx_radio_req_dBm, "dBm"};
signal_budget(end+1, :) = {"Transmit power", P_tx_radio_dBm, "dBm"};
signal_budget(end+1, :) = {"Path loss", G_path_dB, "dB"};
signal_budget(end+1, :) = {"Target RCS", target_rcs_dBsm, "dBsm"};
signal_budget(end+1, :) = {"Receiver losses", -L_total, "dB"};
signal_budget(end+1, :) = {"Required gain", ...
    P_rx_radio_req_dBm - sum(signal_budget.Value(1:end)),"dB"};

signal_budget(end+1, :) = {"Pulse compression", G_chirp_dB, "dB"};
signal_budget(end+1, :) = {"Coherent processing", G_CPI_dB, "dB"};
signal_budget(end+1, :) = {"Signal power", sum(signal_budget.Value), "dBm"};

noise_budget(end+1, :) = {"Thermal base (kTB)", N_thermal_dBm, "dBm"};
noise_budget(end+1, :) = {"Radio NF", NF_radio_dB, "dB"};
noise_budget(end+1, :) = {"3x amplifier NF", NF_amp_dB, "dB"};
P_noise = sum(noise_budget.Value);
noise_budget(end+1, :) = {"Noise power", P_noise, "dBm"};

disp(signal_budget);
disp(noise_budget);

%% Physical Hardware

% Environment effects
freespace = gainblock(name = "Free space", gain = G_path_dB);
target = gainblock(name = "Target", gain = target_rcs_dBsm);

% Components
% Amplifier data read from datasheet plots at ~3.2 GHz
cable = gainblock(name = "Coaxial cable", gain = -1);
fmam1087 = gainblock(name = "FMAM1087", gain = 59, ...
    P_sat = 18, P_max = -2, NF = 1.4);
fmam63018 = gainblock(name = "FMAM63018", gain = 33, ...
    p_sat = 14.5, p_max = 30, NF = 3.2);
aaronia = gainblock(name = "HyperLOG 7040", gain = 4, ...
    P_sat = db10(50e3), P_max = db10(50e3));
lcom = gainblock(name = "Parabolic mesh", gain = 22, ...
    P_sat = db10(50e3), P_max = db10(50e3));

% Links
ant = aaronia;
tx = cable + fmam63018 + cable + ant;
rx = ant + cable + fmam1087 + cable + fmam63018 + cable;
link = tx + freespace + target + rx;

[P_signal, nf] = link.snr(P_tx_radio_dBm);
P_noise = N_thermal_dBm + NF_radio_dB + nf;

disp(link);
fprintf("Actual hardware powers:\n");
fprintf("Signal power at receiver: %+.1f dB\n", P_signal);
fprintf("Noise power at receiver: %+.1f dB\n", P_noise)

fprintf("\nSNR metrics\n");
SNR_single = P_signal - P_noise;
SNR_coherent = SNR_single + G_CPI_dB + G_chirp_dB;
fprintf("Single-pulse SNR: %+.1f dB\n", SNR_single);
fprintf("Coherent SNR: %+.1f dB\n", SNR_coherent);
