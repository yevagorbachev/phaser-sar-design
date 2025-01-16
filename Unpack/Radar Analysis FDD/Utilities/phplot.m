%% Plot phase history
% im = phplot(data, im_mode, x_label, x_values, y_label, y_values)
% INPUTS
%   data    aligned [y, x]

% TODO specify 
function im = phplot(data, row_labels, col_labels, im_mode, dy_range)
    arguments
        data (:, :) double;
        row_labels (:, 1) double;
        col_labels (1, :) double;
        im_mode (1,1) string;
        dy_range (1,1) double {mustBePositive, mustBeReal} = Inf ;
    end

    scales = dictionary;
    labels = dictionary;

    scales("log") = @(d) 20*log10(abs(d));
    labels("log") = "Magnitude [dB]";
    scales("abs") = @abs;
    labels("abs") = "Magnitude [V]";
    scales("re") = @real;
    labels("re") = "I channel [V]";
    scales("im") = @imag;
    labels("im") = "Q channel [V]";
    scales("ph") = @angle;
    labels("ph") = "Angle [rad]";

    if ~isKey(scales, im_mode)
        error("Image scaling '%s' not recognized", im_mode);
    end

    if size(row_labels, 1) ~= size(data, 1)
        error("Data and row labels have inconsistent sizes");
    end
    if size(col_labels, 2) ~= size(data, 2)
        error("Data and column labels have inconsistent sizes");
    end

    scaler = scales(im_mode);
    label = labels(im_mode);
    data = scaler(data);

    dfloor = max(data, [], "all") - dy_range;
    data(data < dfloor) = dfloor;

    ax = gca;
    im = imagesc(ax, col_labels, row_labels, data);
    colormap(ax, "bone");
    cb = colorbar(ax);
    cb.Label.String = label;
end
