% Gainblock: Convenience class representing amplification or attenutation stage
% 
% Simplifies link budget calculations, including saturation and damage level of
% each component. 
% All powers given in dBm for consistency with typical hardware specifications
%
% Overrides '+' to easily chain stages into a channel:
%   amp = gainblock(...)
%   ant = gainblock(...)
%   chan = amp + ant;
% Overrides paren () so that p_out = gb(p_in) gives the output power inclusive of saturations
%   p_tx = chan(in)
% 
% P22714 Multifrequency SAR 
% Yevgeniy Gorbachev - Fall 2024 
classdef gainblock

    % Potential improvements
    % - Make some arguments optional
    % - Add NF
    % - Add P_rev_max and VSWR for reflection 
    properties
        stages (:, 5) table;
    end

    properties (Constant, Access = protected)
        name_map = struct(name = "Component", gain = "Gain [dB]", ...
            p_sat = "P_sat [dBm]", p_max = "P_max [dBm]", ...
            NF = "NF [dB]", vswr = "VSWR [:1]");
    end

    methods (Access = public)
        function gb = gainblock(params)
            % Construct gainblock
            % gb = gainblock(name, gain, p_sat, p_max, NF)
            % name [str]    display name 
            % gain [dB]     small-signal gain 
            % p_sat [dBm]   saturated power 
            % p_max [dBm]   maximum input power 
            % NF [dB]       Noise figure
            % All arguments may be supplied as vectors to represent several stages,
            % provided that they have the same length.
            arguments
                params.name (1,:) string = "";
                params.gain (1,:) double;
                params.p_sat (1,:) double = NaN;
                params.p_max (1,:) double = NaN;
                params.NF (1,:) double = 0;
            end
            gb.stages = struct2table(params);
        end

        % Display, but replace NaN or Inf values with spaces
        function disp(gb)
            disp_table = gb.stages;
            disp_table.Properties.VariableNames = ...
                cellfun(@(n) gainblock.name_map.(n), ...
                disp_table.Properties.VariableNames);
            txt = formattedDisplayText(disp_table);
            txt = strrep(txt, "Inf", "   ");
            txt = strrep(txt, "NaN", "   ");
            disp(txt);
        end
        
        function gb1 = plus(gb1, gb2)
            arguments
                gb1 gainblock
                gb2 gainblock
            end

            % this is ok because gainblock is not a handle
            gb1.stages = [gb1.stages; gb2.stages];
        end
    end

    methods (Access = public)
        % Find output power inclusive of saturations
        % Emit warning if maxima are exceeded
        function [P_out, NF] = snr(gb, P_sig)
            arguments
                gb gainblock;
                P_sig double;
            end

            P_out = P_sig;
            NF = 0;
            for i_st = 1:height(gb.stages) 
                stage = gb.stages(i_st, :);
                if P_out > stage.p_max
                    warning("Stage %d: %s supplied with %.1f dBm, damaged at %.1f dBm.", ...
                        i_st, stage.name, P_out, stage.p_max);
                end
                P_out = P_out + stage.gain;
                if isfinite(stage.p_sat)
                    P_out = min(stage.p_sat, P_out);
                end
                if isfinite(stage.NF)
                    NF = NF + stage.NF;
                end
            end

            % NOTE Deliberately not vectorized - unclear that it is possible to
            % consider effects of upstream saturation on downstream components 
        end
    end
end

