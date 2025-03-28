function x_target = grp_targets(grp, targets)
    % Create 2-D targets relative to a GRP
    % x_target = grp_targets(grp, target1, target2, ...)
    %   grp     GRP location (3x1)
    %   targets target x/y (2x1)
    
    arguments
        grp (3,1) double {mustBeFinite};
    end
    arguments (Repeating)
        targets (2,1) double {mustBeFinite};
    end
    
    positions = [horzcat(targets{:}); 
        zeros(1, length(targets))];
    x_target = grp + positions;
end
