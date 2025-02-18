function [x, v, look, t_range] = ap_stripmap(h, s_range, L_range, spd, F_prf)
    % Create strip-map aperture parallel to +x
    % [x, v, look] = ap_stripmap(h, s_range, L_range, spd, F_prf)
    % INPUTS
    %   h           height
    %   s_range     cross-range [min, max]
    %   L_range     ground-range [min, max]
    %   spd         constant platform speed
    %   F_prf       Pulse rep frequency
    % OUTPUTS
    %   x           platform positions (3xN)
    %   v           platform velocities (3xN)
    %   look        antenna direction cosines (3x3xN)
    %               u_tgt(ant) = look * u_tgt(world)
    %   t_range     fast-time window

    c = 299792458;
    [s_min, s_max] = bounds(s_range);
    x_positions = s_min:(spd/F_prf):s_max;
    N = length(x_positions);
    x = [x_positions; zeros([1 N]); repmat(h, [1 N])];
    v = repmat([spd; 0; 0], [1 N]);

    [L_min, L_max] = bounds(L_range);
    t_range = 2*sqrt([L_min L_max].^2 + h.^2)/c;
    grazing = atan(h / mean([L_min, L_max]));
    look = repmat([1 0 0;
        0 cos(grazing) -sin(grazing);
        0 sin(grazing) cos(grazing)], [1 1 N]);
end
