function [pulse, f_s] = idealLFM(chirp_bandwidth, pulse_width)
    % Generates an ideal centered LFM waveform at baseband
    % [pulse, f_s] = idealLFM(chirp_bandwidth, pulse_width)
    % INPUTS
    %   chirp_bandwidth     chirp bandwidth (Hz)
    %   pulse_width `       pulse width (s)
    % OUTPUTS
    %   pulse               baseband chirped signal samples (complex)
    %   f_s                 1.4B - bandwidth required for adequate sampling/simulation`
    f_s = 1.4*chirp_bandwidth;
    t = (0:(1/f_s):pulse_width);
    chirp_rate = chirp_bandwidth/pulse_width;
    pulse = exp(1j*(pi * chirp_rate .* (t - pulse_width/2).^2));
end
