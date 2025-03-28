% function [waveform, info] = adf4159(ramp_time, ramp_bandwidth)
clear;
% specs
ramp_time = 500e-9;
ramp_bandwidth=150e6;

% fixed by hardware
reference_clk = 100e6; % [Hz] reference clock frequency
dev_max = 2^15;
clk1_max = 
% magic numbers
freq_dev = 250e3;
clk_2 = 1;
bit_D = 1;
bit_T = 0;
int_R = 1;

% 
freq_pfd = reference_clk * (1+bit_D)/(int_R*(1+bit_T));
freq_res = reference_clk / 2^25;

ramp_rate = ramp_bandwidth / ramp_time;
dev_offset = log2(freq_dev/(freq_res * dev_max));
dev_offset_rnd = round(dev_offset);
% end
    
