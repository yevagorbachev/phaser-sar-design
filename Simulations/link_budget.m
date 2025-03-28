%% Link budget
% Assign physical parameters and requirements
% Find required gain (amplifiers + antennas) for given scene
% Calculate actual gain for specified hardware
% 
% P22714 Multifrequency SAR 
% Yevgeniy Gorbachev - Fall 2024 

clear;

plot_candidates = true;

%% Constants
c = 299792458;
k = 1.3806e-23;
T = 273.15 + 40; % [K] reciever temperature (from 40C)

%% Hardware fixed
aperture_width = 10; % [m] maximum synthezied aperture
platform_height = 20; % [m] roof elevation
target_rcs_dBsm = 5; % Car RCS

center_freq = 10.25e9; % [Hz] center frequency
interm_bandwidth = 20e6 * 0.75; % [Hz] IF bandwidth (actually 20, but margin added)
max_ramp_bandwidth = 500e6; % [Hz] Maximum ramp bandwidth (antenna passband)
wavelength = c/center_freq;
D_az_rx = 8*(wavelength/2); % 8 elements at lambda/2
D_el_rx = 4*(wavelength/2); % 4 elements at lambda/2
beamwidth_az = wavelength/D_az_rx;

if plot_candidates
    range_candidates = 75:25:300; % [m] candidate ranges
    swath_candidates = 10:5:30; % [m] candidate range swaths
    [range_candidates, swath_candidates] = ndgrid(range_candidates, swath_candidates);

    pulse_widths = 2*range_candidates/c;
    swath_times = 2*swath_candidates/c;
    ramp_bandwidths = interm_bandwidth .* pulse_widths ./ swath_times;
    ramp_bandwidths(ramp_bandwidths > max_ramp_bandwidth) = max_ramp_bandwidth;
    integration_angles = atan(aperture_width ./ range_candidates);
    range_resolutions = c ./ (2 .* ramp_bandwidths);
    cross_resolutions = wavelength ./ (2 .* integration_angles);

    figure(name = "Aperture candidates");
    hold on;
    plot(range_candidates(:, 1), cross_resolutions(:, 1), "-", ...
        DisplayName = "$\delta_\mathrm{az}$", LineWidth = 2);
    for i_swath = 1:size(range_candidates, 2)
        name = sprintf("$\\delta_\\mathrm{r}$ (%g-m swath)", swath_candidates(1, i_swath));
        plot(range_candidates(:, i_swath), range_resolutions(:, i_swath), "--", ...
            DisplayName = name);
    end
    title("Aperture dimension candidates");
    ylabel("Resolution cell size [m]");
    xlabel("GRP range [m]");
    legend(Interpreter = "latex");
    grid on;

    
end

return;
layout = tiledlayout("flow");
nexttile;
imagesc(swath_candidates(1,:), range_candidates(:,1),  range_resolutions);
xlabel("Range swath");
ylabel("GRP range");
cb = colorbar;
cb.Label.String = "Range resolution [m]";

nexttile;
imagesc(swath_candidates(1,:), range_candidates(:,1),  cross_resolutions);
cb = colorbar
cb.Label.String = "Cross-range resolution [m]";
xlabel("Range swath");
ylabel("GRP range");


return;


scene_width = 10; % [m]


grp_range_candidates = 75:25:300;
scene_length_requiremetns


grp_range = 200; % [m]
scene_length = 10; % [m]
platform_height = 20; % [m]
target_rcs_dBsm = 5; % [dBsm] car radar cross section

slant_range = sqrt(platform_height^2 + grp_range^2);
integration_angle = atan(scene_width / slant_range);

%% Frequency allocation
bandwidth = 150e6;
wavelength = c/center_freq;
range_res = c/(2*bandwidth); % [m]
xrange_res = wavelength/(2*integration_angle);

% Coherent processing 
platform_spd = 0.1; % [m/s] platform velocity
grp_time = 2*slant_range/c;
pulse_width = grp_time;
% B_dop = 2*platform_spd*sin(integration_angle)/wavelength; % [s] Doppler 
B_dop = 2*platform_spd*sind(30)/wavelength;
F_prf = 1.4*B_dop;
T_CPI = scene_width / platform_spd; % [s] Coherent processing time
% NOTE: Signal processing gains are db20 because they are voltage-like

G_CPI_dB = db20(T_CPI * F_prf); % Coherent processing gain 
G_chirp_dB = db20(pulse_width * bandwidth); % Pulse compression gain 

% Environment effects
G_path_dB = db10(wavelength^2 / ((4*pi)^3 * slant_range^4));
% Two-way Friis (without G or P)

freespace = gainblock(name = "Free space", gain = G_path_dB);
target = gainblock(name = "Target", gain = target_rcs_dBsm);

%% Hardware parameters
% ADL8107 Datasheet Rev B
%   typical gain - page 1
%   typical NF - page 1
%   saturating output - page 3
%   maximum input - page 5
adl8107 = gainblock(name = "ADL8107", gain = 24, NF = 1.3, p_max = 22, p_sat = 20);

% HMC451 Datasheet v02.0121 
%   typical gain - page 1
%   typical NF - page 1
%   satuating output - page 1
%   maximum input - page 4
hmc451 = gainblock(name = "HMC451LP3", gain = 18, NF = 7, p_max = 10, p_sat = 21);

% gain - PE9856B-SF-10
wr90 = gainblock(name = "PE9856B", gain = 10);

% CN0566 Circuit Note Rev 0 - onboard antenna gain - page 5
cn0566 = gainblock(name = "PHASER", gain = -10);

% AD9363 Datasheet Rev D
%   Rx gain - page 24
%   NF - page 24
%   Max Rx power - page 25
ad9363 = gainblock(name = "PLUTO", gain = 10, NF = 3, p_max = 2.5);

% wild guess
cable = gainblock(name = "Coaxial cable", gain = -1);

% Back-out Tx parameters
% solve numerically for D_az/el giving correct HPBW
% using Daz/el and gain, solve for efficiency
% NOTE PE9856B doesn't list beamwidth, PEWAN090 looks similar and has same gain
horn_azbw = deg2rad(52.1); % PEWAN090-10SM datasheet
horn_elbw = deg2rad(51.6); % PEWAN090-10SM datasheet

D_az_tx = fzero(@(Dl) sinc((Dl / wavelength) * (horn_azbw/2)).^2 - 0.5, ...
    wavelength / horn_azbw);
D_el_tx = fzero(@(Dl) sinc((Dl / wavelength) * (horn_elbw/2)).^2 - 0.5, ...
    wavelength / horn_elbw);

eff_tx = (mag10(wr90.gain) * wavelength^2) / (4*pi*D_az_tx*D_el_tx);

% Back-out Rx parameters
array_gain = mag10(cn0566.gain);
D_az_rx = 8*(wavelength/2); % 8 elements at lambda/2
D_el_rx = 4*(wavelength/2); % 8 elements at lambda/2
eff_rx = array_gain * wavelength^2 / (4*pi*D_az_rx*D_el_rx);

N_thermal_dBm = db10(k*T*bandwidth) + 30;

tx = hmc451 + cable + adl8107 + cable + wr90;
rx = cn0566 + adl8107 + cable + ad9363;
link = tx + freespace + target + rx;

disp(link);

P_signal = link.transmit(7.5);
nf = link.nf;
P_noise = N_thermal_dBm + nf;

fprintf("Actual hardware powers:\n");
fprintf("Signal power at receiver: %+.1f dB\n", P_signal);
fprintf("Noise power at receiver: %+.1f dB\n", P_noise)

fprintf("\nSNR metrics\n");
SNR_single = P_signal - P_noise;
SNR_coherent = SNR_single + G_CPI_dB + G_chirp_dB;
fprintf("Single-pulse SNR: %+.1f dB\n", SNR_single);
fprintf("Coherent SNR: %+.1f dB\n", SNR_coherent);
