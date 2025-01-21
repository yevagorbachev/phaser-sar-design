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
f_c = 10.25e9; % [Hz] center frequency
lam_c = c/f_c; % [m] wavelength
BW = 500e6; % [Hz] bandwidth

%% Aperture parameters
% Performance metrics
xrange_res = lam_c / (2*theta); % [m]
range_res = c/(2*BW); % [m]

% Coherent processing 
v = 0.1; % [m/s] platform velocity
PW = 150e-9; % [s] pulse width
B_dop = 2*v/lam_c; % [s] Doppler bandwidth without accounting for beam (forward/backward)
F_prf_min = B_dop*1.4; % [Hz] pulse rep. frequency
% F_prf = 2*B_dop;
F_prf = 100;
T_CPI = aperture_width / v; % [s] Coherent processing time
% NOTE: Signal processing gains are db20 because they are voltage-like
G_CPI_dB = db20(T_CPI * F_prf); % Coherent processing gain 
G_chirp_dB = db20(PW * BW); % Pulse compression gain 

% Environment effects
G_path_dB = db10(lam_c^2 / ((4*pi)^3 * range^4));
% Two-way Friis without G or P

%% Hardware parameters
rx_amplifier_dB = 24; % ADL8107 typical gain [Datasheet Rev B page 1]
rx_amplifier_NF_dB = 1.3; % ADL8107 typical NF [Datasheet Rev B page 1]

tx_amplifier_dB = 24; % ADL8107 typical gain [Datasheet Rev B page 1]
tx_amplifier_NF_dB = 1.3; % ADL8107 typical NF [Datasheet Rev B page 1]

array_gain_dB = -10; % CN0566 onboard antenna gain [Circuit Note Rev 0 page 5]

NF_radio_dB = 3; % AD9363 NF at 2.4 GHz [Datasheet Rev D page 24]
P_tx_radio_dBm = 7.5; % AD9363 Tx power at 2.4 GHz [Datasheet Rev D page 25]
P_rx_radio_req_dBm = -90; % [CN0566 Circuit Note Rev 0 page 6, Figure 11]
% Minimum reading on the "receive signal path measurements"

L_total_dB = 5; % Wild guess

% Efficiency calculation
array_gain = mag10(array_gain_dB);
D_az = 8*(lam_c/2); % 8 elements at lambda/2
D_el = 4*(lam_c/2); % 8 elements at lambda/2
eff = array_gain * lam_c^2 / (4*pi*D_az*D_el);

N_thermal_dBm = db10(k*PW*BW) + 30;

%% Required Link Budget

signal_budget = table(Size = [0 3], ...
    VariableTypes = ["string", "double", "string"], ...
    VariableNames = ["Parameter", "Value", "Unit"]);
noise_budget = table(Size = [0 3], ...
    VariableTypes = ["string", "double", "string"], ...
    VariableNames = ["Parameter", "Value", "Unit"]);

signal_budget(end+1, :) = {"Transmit power", P_tx_radio_dBm, "dBm"};
signal_budget(end+1, :) = {"Transmitter LNA", tx_amplifier_dB, "dBm"};
signal_budget(end+1, :) = {"Path loss", G_path_dB, "dB"};
signal_budget(end+1, :) = {"Target RCS", target_rcs_dBsm, "dBsm"};
signal_budget(end+1, :) = {"Receiver LNA", rx_amplifier_dB, "dB"};
signal_budget(end+1, :) = {"Receiver array gain", array_gain_dB, "dB"};
signal_budget(end+1, :) = {"Receiver losses", -L_total_dB, "dB"};
signal_budget(end+1, :) = {"Required gain", ...
    P_rx_radio_req_dBm - sum(signal_budget.Value(1:end)),"dB"};

signal_budget(end+1, :) = {"Pulse compression", G_chirp_dB, "dB"};
signal_budget(end+1, :) = {"Coherent processing", G_CPI_dB, "dB"};
signal_budget(end+1, :) = {"Signal power", sum(signal_budget.Value), "dBm"};

noise_budget(end+1, :) = {"Thermal base (kTB)", N_thermal_dBm, "dBm"};
noise_budget(end+1, :) = {"Radio NF", NF_radio_dB, "dB"};
noise_budget(end+1, :) = {"2x ADL8107 NF", 2*rx_amplifier_NF_dB, "dB"};
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
cn0566 = gainblock(name = "CN0566", gain = array_gain_dB);
adl8107 = gainblock(name = "ADL8107", gain = rx_amplifier_dB, NF = rx_amplifier_NF_dB);
tx_ant = gainblock(name = "WR-62", gain = 20);

tx = cable + adl8107 + tx_ant;
rx = cn0566 + adl8107 + cable;
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
