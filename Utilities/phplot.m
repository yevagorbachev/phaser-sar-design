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

    if size(row_labels, 1) ~= size(data, 1)
        error("Data and row labels have inconsistent sizes");
    end
    if size(col_labels, 2) ~= size(data, 2)
        error("Data and column labels have inconsistent sizes");
    end

    switch im_mode
        case "log"
            scaler = @(d) 20*log10(abs(d)); 
            zlabel = "Magnitude [dB]";
        case "abs"
            scaler = @abs;
            zlabel = "Magnitude [V]";
        case "re"
            scaler = @real;
            zlabel = "I channel [V]";
        case "im"
            scaler = @imag;
            zlabel = "Q channel [V]";
        case "ph"
            scaler = @angle;
            zlabel = "Phase [rad]";
        otherwise 
            error("Image scaling '%s' not recognized", im_mode);
    end

    data = scaler(data);

    dfloor = max(data, [], "all") - dy_range;
    data(data < dfloor) = dfloor;

    ax = gca;
    im = imagesc(ax, col_labels, row_labels, data);
    colormap(ax, "bone");
    cb = colorbar(ax);
    cb.Label.String = zlabel;
    axis tight;
end
