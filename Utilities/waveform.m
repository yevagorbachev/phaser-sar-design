classdef waveform
    %WAVEFORM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        samples (1, :) double {mustBeFinite};
        sample_freq (1,1) double {mustBePositive} = 1;
        offset (1,1) duration = seconds(0);
    end

    % properties (Dependent)
    %     time (1, :) duration;
    % end
    
    methods
        function wv = waveform(samples, f_s)
            wv.samples = samples;
            wv.sample_freq = f_s;
        end

        function wv = plus(a, b)
            if ~isa(a, "waveform")
                error("invalid");
            end

            if isa(b, "waveform")
                if a.sample_freq ~= b.sample_freq
                    error("invalid");
                end

                if b.offset > a.offset
                    first = a;
                    second = b;
                else
                    first = b;
                    second = a;
                end
                n_start = floor(seconds(second.offset - first.offset) * first.sample_freq) + 1;
                n_end = n_start + length(second.samples) - 1; 
                n_pad = max(n_end - length(first.samples), 0);
                first.samples = [first.samples zeros(1, n_pad)];
                first.samples(n_start:n_end) = first.samples(n_start:n_end) + second.samples;
                wv = first;

            elseif isa(b, "duration")
                a.offset = a.offset + b;
                wv = a;
            else
                error("invalid")
            end
        end

        function wv = minus(a, b)
            wv = a + (-b);
        end

        function wv = uminus(wv)
            wv.samples = -wv.samples;
        end

        function ph = plot(wv, varargin)
            t = (0:(length(wv.samples)-1))/wv.sample_freq;
            ph = plot(wv.offset + seconds(t), wv.samples, varargin{:});
        end

    end
end

