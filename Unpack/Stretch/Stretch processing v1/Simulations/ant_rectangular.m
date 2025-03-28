function func = ant_rectangular(normalized_azel, efficiency)
    % Create antenna gain function using normalized dimensions and efficiency
    % func = ant_rectangular(normalized_azel, efficiency)
    % INPUTS
    %   normalized_azel     (1x2) double        Normalized (D/lam) aperture dimensions
    %   efficiency          (1x1) double        Aperture efficiency
    % OUTPUTS
    %   func(az, el)        function            Power gain as a function of az/el (rad)
    arguments
        normalized_azel (1,2) double {mustBePositive};
        efficiency (1,1) double {mustBePositive};
    end
    d_az = normalized_azel(1);
    d_el = normalized_azel(2);

    func = @(az, el) 4*pi*d_az*d_el*efficiency * ...
        sinc(d_az * sin(az)) .^ 2 .* ...
        sinc(d_el * sin(el)) .^ 2;
end

% function sc = sinc(arg)
%     sc = ones(size(arg));
%     nz = arg ~= 0;
%     sc(nz) = sin(arg(nz)) ./ arg(nz);
% end
