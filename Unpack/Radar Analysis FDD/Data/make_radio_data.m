function data = make_radio_data(data_file)
    data = struct;

    vnp = {"VariableNamingRule", "preserve"};

    % Read sheets
    metrics_table = readtable(data_file, vnp{:}, Sheet = "Metrics");
    tx_evm_table = readtable(data_file, vnp{:}, Sheet = "Transmit EVM");
    rx_evm_table = readtable(data_file, vnp{:}, Sheet = "Receive EVM");
    rx_fs_table = readtable(data_file, vnp{:}, Sheet = "Receive FS");
    rx_nsd_table = readtable(data_file, vnp{:}, Sheet = "Noise PSD");

    data.metrics = dictionary(string(metrics_table.Metric), metrics_table.Value);

    sci_settings = {"linear", "none"};

    % Transmitter EVM power [dBm, Hz -> dB]
    data.tx_evm = scatteredInterpolant(...
        tx_evm_table.("Power [dBm]"), ...
        1e6 * tx_evm_table.("Frequency [MHz]"), ...
        tx_evm_table.("EVM [dB]"), ...
        sci_settings{:});
    
    % Receiver EVM power [dBm, Hz -> dB]
    data.rx_evm = scatteredInterpolant(...
        rx_evm_table.("Power [dBm]"), ...
        1e6 * rx_evm_table.("Frequency [MHz]"), ...
        rx_evm_table.("EVM [dB]"), ...
        sci_settings{:});

    % Receiver full-scale power table [Hz->dB]
    rx_fs_table = sortrows(rx_fs_table, "Frequency [GHz]");
    data.rx_fs = griddedInterpolant(1e9*rx_fs_table.("Frequency [GHz]"), ...
        rx_fs_table.("FS [dB]"), sci_settings{:});

    % Receiver noise density [Hz->dBm/Hz]
    data.rx_noise_psd = griddedInterpolant(1e9 * rx_nsd_table.("Frequency [GHz]"), ...
        rx_nsd_table.("PSD [dBFS/Hz]") + data.metrics("RF-ADC FS [dBm]"), ...
        sci_settings{:});
end
