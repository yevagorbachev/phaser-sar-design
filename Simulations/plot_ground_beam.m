function patches = plot_ground_beam(range, swath, beamwidth, synlength)
    n_angles = 30;
    n_ranges = 20;
    angle_range = linspace(-beamwidth/2, beamwidth/2, n_angles);
    cross_positions = [-synlength/2; 0; synlength/2];
    ax = gca;
    hold(ax, "on");
    for i_cross = 1:length(cross_positions)
        cross = cross_positions(i_cross);
        grp_range = sqrt(range .^2 + cross .^2);
        azimuth_angle = atan(cross / range);
        
        collection_ranges = linspace(grp_range - swath/2, grp_range+swath/2, n_ranges);

        patch_ranges = [collection_ranges, collection_ranges(end) * ones(1, n_angles), ...
            flip(collection_ranges), collection_ranges(1) * ones(1, n_angles)];
        patch_angles = [angle_range(1)*ones(1, n_ranges), angle_range, ...
            angle_range(end)*ones(1, n_ranges), flip(angle_range)];
        patch_x = patch_ranges .* sin(patch_angles) + cross;
        patch_y = patch_ranges .* cos(patch_angles);
        rot = [cos(azimuth_angle), -sin(azimuth_angle);
            sin(azimuth_angle), cos(azimuth_angle)];
        patch_xy = rot * [patch_x; patch_y];
       
        % line_xy = [cross cross; 0 grp_range];
        % line_xy = rot * line_xy;
        % plot(line_xy(1,:), line_xy(2,:));

        patches(i_cross) = patch(ax, patch_xy(1,:), patch_xy(2,:), "b", ...
            FaceAlpha = 0.2, EdgeColor = "none"); %#ok
    end
    daspect(ax, [1 1 1]);
end
