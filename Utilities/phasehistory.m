classdef phasehistory
    properties
        slow_time (1,:) double;
        fast_time (:,:) double;
        values (:,:) double;
        position (3,:) double;
        velocity (3,:) double;
        grp (3,1) double;
        wavelength (1,1) double;
        ramp_rate (1,1) double;
        ramp_time (1,1) double;
    end

    properties (Dependent)
        N_fast (1,1) double {mustBeInteger};
        N_slow (1,1) double {mustBeInteger};
    end

    properties (Constant)
        wavespeed = 299792458; % [m/s]
    end

    methods
        function ph = phasehistory(values)
            ph.values = values;
        end

        function N_fast = get.N_fast(ph)
            N_fast = size(ph.values, 1);
        end

        function N_slow = get.N_slow(ph)
            N_slow = size(ph.values, 2);
        end

        function ph = set.slow_time(ph, times)
            assert(isrow(times));
            assert(length(times) == ph.N_slow)
            ph.slow_time = times;
        end

        function ph = set.fast_time(ph, times)
            if iscolumn(times)
                times = repmat(times, 1, ph.N_slow); %#ok
            end     
            assert(ismatrix(times));
            assert(isequal(size(times), [ph.N_fast ph.N_slow])); %#ok
            ph.fast_time = times;
        end

        function ph = set.position(ph, pos)
            assert(size(pos, 2) == ph.N_slow) %#ok
            ph.position = pos;
        end

        function ph = set.velocity(ph, vel)
            if size(vel, 2) == 1
                vel = repmat(vel, 1, ph.N_slow); %#ok
            end
            assert(size(vel, 2) == ph.N_slow); %#ok
            ph.velocity = vel;
        end

        function [range, az, el] = pos2raz(ph, pos)
            arguments
                ph (1,1) phasehistory;
                pos (3,1) double;
            end
            range_vector = pos - ph.position; % relative position platform-to-target (global)
            range = vecnorm(range_vector, 2, 1);
            az = atan2(range_vector(1,:), range_vector(2,:));
            el = atan2(range_vector(3,:), range_vector(2,:));
        end

        function im = plot(ph, opts)
            arguments
                ph (1,1) phasehistory;
                opts.scale (1,1) string {mustBeMember(opts.scale, ...
                    ["log", "abs", "re", "im", "ph"])} = "abs"; 
                opts.dynamic (1,1) double {mustBePositive} = Inf;
                opts.range (1,1) string {mustBeMember(opts.range, ...
                    ["index", "time", "slant", "ground"])} = "index";
                opts.cross (1,1) string {mustBeMember(opts.cross, ...
                    ["index", "time", "range"])} = "index";
            end

            switch opts.scale
                case "log"
                    data = 20*log10(abs(ph.values));
                    z_label = "Magnitude [dB]";
                case "abs"
                    data = abs(ph.values);
                    z_label = "Magnitude [V]";
                case "re"
                    data = real(ph.values);
                    z_label = "I channel [V]";
                case "im"
                    data = imag(ph.values);
                    z_label = "Q channel [V]";
                case "ph"
                    data = angle(ph.values);
                    z_label = "Phase [rad]";
            end

            switch opts.cross
                case "index"
                    x_data = 1:ph.N_slow;
                    x_label = "Cross-range line";
                case "time"
                    x_data = ph.slow_time;
                    x_label = "Slow-time [s]";
                case "range"
                    x_data = ph.position(1,:);
                    x_label = "Cross-range [m]";
            end

            switch opts.range
                case "index"
                    y_data = 1:ph.N_fast;
                    y_label = "Range line";
                case "time"
                    y_data = ph.fast_time(:, 1);
                    y_label = "Fast time [s]";
                case "slant"
                    % XXX using first sample
                    y_data = ph.wavespeed .* ph.fast_time(:, 1) / 2;
                    y_label = "Slant range [m]";
                case "ground"
                    % XXX using first sample
                    grp_relative = ph.position(:, 1) - ph.grp;
                    grazing = atan2(grp_relative(3), grp_relative(2));
                    y_data = ph.wavespeed .* ph.fast_time(:, 1) / 2;
                    y_data = y_data / grazing;
                    y_label = "Ground range [m]";
            end


            dfloor = max(data, [], "all") - opts.dynamic;
            data(data < dfloor) = dfloor;
            im = imagesc(x_data, y_data, data, HandleVisibility = "off");
            ax = im.Parent;
            colormap(ax, "bone");
            cb = colorbar(ax);
            cb.Label.String = z_label;
            xlabel(ax, x_label);
            ylabel(ax, y_label);
            axis(ax, "tight");
        end
    end
end
