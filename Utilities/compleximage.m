classdef compleximage
    properties
        values (:, :) double;
        range (:, 1) double;
        cross_range (1, :) double;
        grp (3,1) double;
    end
    
    methods
        function img = compleximage(values, range, cross_range, grp)
            arguments
                values (:, :) double;
                range (:, 1) double;
                cross_range (1, :) double;
                grp (3,1) double;
            end
            assert(size(range, 1) == size(values, 1));
            assert(size(cross_range, 2) == size(values, 2));
            img.values = values;
            img.range = range;
            img.cross_range = cross_range;
            img.grp = grp;
        end
        
        function im = plot(img, opts)
            arguments
                img (1,1) compleximage;
                opts.scale (1,1) string {mustBeMember(opts.scale, ...
                    ["log", "abs", "re", "im", "img"])} = "abs"; 
                opts.dynamic (1,1) double {mustBePositive} = Inf;
                opts.range (1,1) string {mustBeMember(opts.range, ...
                    ["global", "grp"])} = "global";
                opts.cross (1,1) string {mustBeMember(opts.cross, ...
                    ["global", "grp"])} = "global";
            end

            switch opts.scale
                case "log"
                    data = 20*log10(abs(img.values));
                    z_label = "Magnitude [dB]";
                case "abs"
                    data = abs(img.values);
                    z_label = "Magnitude [V]";
                case "re"
                    data = real(img.values);
                    z_label = "I channel [V]";
                case "im"
                    data = imag(img.values);
                    z_label = "Q channel [V]";
                case "img"
                    data = angle(img.values);
                    z_label = "Phase [rad]";
            end

            switch opts.range
                case "global"
                    y_data = img.range;
                    y_label_fmt = "Range [%sm]";

                case "grp"
                    y_data = img.range - img.grp(2);
                    y_label_fmt = "GRP range [%sm]";
            end
            % [prefix, scale] = compleximage.siprefix(max(y_data));
            % y_data = y_data ./ (10 ^ scale);
            y_label = sprintf(y_label_fmt, "");

            switch opts.cross
                case "global"
                    x_data = img.cross_range;
                    x_label_fmt = "Cross-range [%sm]";
                case "grp"
                    x_data = img.cross_range - img.grp(1);
                    x_label_fmt = "GRP cross-range [%sm]";
            end
            % [prefix, scale] = compleximage.siprefix(max(x_data));
            % x_data = x_data ./ (10 ^ scale);
            x_label = sprintf(x_label_fmt, "");


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

    methods (Static, Access = protected)
        function [prefix, scale] = siprefix(value)
            arguments
                value (1,1) double;
            end
            
            prefixes = ["p", "n", "u", "m", "", "k", "M", "G", "T"];
            exps = [-12 -9 -6 -3 0 3 6 9 12];
            assert(length(prefixes) == length(exps), ...
                "Prefixes and exponents have inconsistent definitions");
            i_exp = find(exps <= log10(abs(value)), 1, "last");
            if isempty(i_exp)
                i_exp = 1;
            end

            prefix = prefixes(i_exp);
            scale = exps(i_exp);
        end
    end
end

