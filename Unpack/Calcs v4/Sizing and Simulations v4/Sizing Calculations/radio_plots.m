%% Radio EVM and noise power plots
% Plot radio's EVM at 3.2 GHz (linearly interpolated from 2.5 and 3.6 GHz)
% Plot noise power using EVM
% 
% 
% P22714 Multifrequency SAR 
% Yevgeniy Gorbachev - Fall 2024 

link_budget;

powers = -40:10;
freqs = repmat(f_c, size(powers));
noise_factor = BW/(radio_data.metrics("EVM Measurement BW [MHz]") * 1e6);
rx_evm = radio_data.rx_evm(powers, freqs) + db10(noise_factor);
tx_evm = radio_data.tx_evm(powers, freqs) + db10(noise_factor);


figure(name = "Radio EVM plots");
tiledlayout(2,1);
nexttile;
plot(powers, tx_evm, DisplayName = "EVM");
xline(P_tx_radio_dBm, "--k", DisplayName = "Selected Tx power")
legend;
xlabel("Output power");
xsecondarylabel("dBm");
ylabel("RMS EVM");
ysecondarylabel("dBc");
title("Transmit noise power");

nexttile;
plot(powers, rx_evm, DisplayName = "EVM");
axis manual;
plot(powers, N_radio_dBm - powers, "--r", DisplayName = "Thermal noise");
legend;
xlabel("Input power");
xsecondarylabel("dBm");
ylabel("RMS EVM");
ysecondarylabel("dBc");
title("Receiver noise power");

figure(name = "Radio noise power plots");
tiledlayout(2,1);
nexttile;
plot(powers, tx_evm + powers, DisplayName = "Noise power");
xline(P_tx_radio_dBm, "--k", DisplayName = "Selected Tx power")
legend;
xlabel("Output power");
xsecondarylabel("dBm");
ylabel("Noise power");
ysecondarylabel("dBm");
title("Transmit noise power");

nexttile;
plot(powers, rx_evm + powers, DisplayName = "Noise power");
axis manual;
yline(N_radio_dBm, "--r", DisplayName = "Thermal noise");
legend;
xlabel("Input power");
xsecondarylabel("dBm");
ylabel("Noise power");
ysecondarylabel("dBm");
title("Receive noise power");
