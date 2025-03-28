function [pulse, time] = idealLFM(chirp_bandwidth, pulse_width, sample_freq)
    % Generates an ideal centered LFM waveform at baseband
    % [pulse, f_s] = idealLFM(chirp_bandwidth, pulse_width)
    % INPUTS
    %   chirp_bandwidth     chirp bandwidth (Hz)
    %   pulse_width `       pulse width (s)
    %   sample_freq         Frequency to sample signal
    % OUTPUTS
    %   pulse               baseband chirped signal samples (complex)
    time = (0:(1/sample_freq):pulse_width)';
    chirp_rate = chirp_bandwidth/pulse_width;
    pulse = exp(1j*(pi * chirp_rate .* (time - pulse_width/2).^2));

    assert(iscolumn(pulse));
end
