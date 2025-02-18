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

% NOTE PE9856B doesn't list beamwidth, PEWAN090 looks similar and has same gain
horn_gain_dB = 10; % PE9856B-SF-10
horn_azbw = deg2rad(52.1); % PEWAN090-10SM 
horn_elbw = deg2rad(51.6); % PEWAN090-10SM 

radio_amplifier_dB = 70; % AD9363 Rx gain at 2.4 GHz [Datasheet Rev D page 24]
radio_NF_dB = 3; % AD9363 NF at 2.4 GHz [Datasheet Rev D page 24]
P_tx_radio_dBm = 7.5; % AD9363 Tx power at 2.4 GHz [Datasheet Rev D page 25]

L_total_dB = 3; % Wild guess

% Back-out Tx parameters
% solve numerically for D_az/el giving correct HPBW
% using Daz/el and gain, solve for efficiency
D_az_tx = fzero(@(Dl) sinc((Dl / lam_c) * (horn_azbw/2)).^2 - 0.5, ...
    lam_c / horn_azbw);
D_el_tx = fzero(@(Dl) sinc((Dl / lam_c) * (horn_elbw/2)).^2 - 0.5, ...
    lam_c / horn_elbw);
eff_tx = (mag10(horn_gain_dB) * lam_c^2) / (4*pi*D_az_tx*D_el_tx);
% Back-out Rx parameters

array_gain = mag10(array_gain_dB);
D_az_rx = 8*(lam_c/2); % 8 elements at lambda/2
D_el_rx = 4*(lam_c/2); % 8 elements at lambda/2
eff_rx = array_gain * lam_c^2 / (4*pi*D_az_rx*D_el_rx);

N_thermal_dBm = db10(k*T*BW) + 30;

%% Hardware

% Environment effects
freespace = gainblock(name = "Free space", gain = G_path_dB);
target = gainblock(name = "Target", gain = target_rcs_dBsm);

% Components
cable = gainblock(name = "Coaxial cable", gain = -1);
cn0566 = gainblock(name = "PHASER", gain = array_gain_dB);
adl8107 = gainblock(name = "ADL8107", gain = rx_amplifier_dB, NF = rx_amplifier_NF_dB);
ad9363 = gainblock(name = "PLUTO", gain = 70, NF = radio_NF_dB);
wr90 = gainblock(name = "PEWAN090-10SM", gain = horn_gain_dB);

tx = cable + adl8107 + cable + wr90;
rx = cn0566 + adl8107 + cable + ad9363;
link = tx + freespace + target + rx;

[P_signal, nf] = link.snr(P_tx_radio_dBm);
P_noise = N_thermal_dBm + nf;

disp(link);
fprintf("Actual hardware powers:\n");
fprintf("Signal power at receiver: %+.1f dB\n", P_signal);
fprintf("Noise power at receiver: %+.1f dB\n", P_noise)

fprintf("\nSNR metrics\n");
SNR_single = P_signal - P_noise;
SNR_coherent = SNR_single + G_CPI_dB + G_chirp_dB;
fprintf("Single-pulse SNR: %+.1f dB\n", SNR_single);
fprintf("Coherent SNR: %+.1f dB\n", SNR_coherent);
