%% Data capture budget
% Ensure sufficient instantaneous or average data rate for calculated pulse parameters
%
% P22714 Multifrequency SAR 
% Yevgeniy Gorbachev - Fall 2024 

link_budget;

samp_width = 2 * 2; % [B/samp] size of each sample [bits]
samp_freq = 2 ^ nextpow2(BW); % [samp/s] required sampling rate
range_gate = sqrt(platform_height ^2 + [min_range max_range] .^2); % [m m] slant-range gate
time_gate = 2*PW + 2*diff(range_gate)/c; % [s] time range plus padding

inst_rate = samp_width * samp_freq;
mean_rate = inst_rate * time_gate * F_prf;
total = mean_rate * T_CPI;

fprintf("\nData budget\n");
data_table = table(Size = [0 3], VariableTypes = ["string", "double", "string"], ...
    VariableNames = ["Quantity", "Value", "Unit"]);
data_table(end+1, :) = {"Inst. data rate", inst_rate / 2^20, "MiB/s"};
data_table(end+1, :) = {"Mean data rate", mean_rate / 2^10, "kiB/s"};
data_table(end+1, :) = {"Total data", mean_rate * T_CPI / 2^20, "MiB"};
disp(data_table);
