%% Airport radar power calculations
% The airport is very loud at 2.8GHz, which has the potential to damage some
% components. This script calculates its incident power (before antenna gain).
% 
% P22714 Multifrequency SAR 
% Yevgeniy Gorbachev - Fall 2024 

link_budget;

P_tx_asr = 1.3e6; % [W] ASR-9 peak output power
bw_az = 1.4; % [deg] ASR-9 azimuth beamwidth
bw_el = 5; % [deg] ASR-9 elevation beamwidth
range_asr = 4e3; % [m] range to RIT
f_c_asr = 2.8e9; % [Hz] ASR-9 center frequency
lambda_asr = freq2wavelen(f_c_asr); % [m] wavelength

G_asr_tx_dBi = beamwidth2gain([bw_az; bw_el], "UniformRectangular"); % Airport antenna gain
P_asr_tx_dBm = 30 + db10(P_tx_asr);
P_asr_rx_dBm = P_asr_tx_dBm + G_asr_tx_dBi + db10( (lambda_asr/(4*pi*range_asr))^2 ); 
% Received P_tx_asr (at antenna) before amplification
fprintf("\nAirport radar power\n")
fprintf("Incident power from ASR-9: %.1f dBm\n", P_asr_rx_dBm);
