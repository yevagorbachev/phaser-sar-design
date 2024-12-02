function [f] = freqaxis(F_s, N, mode)
    if nargin == 2
        mode = "cent";
    end
    switch mode
        case "cent"
            f = F_s/N * (-N/2:(N/2-1));
        case "left"
            f = F_s/N * (0:(N-1));
        otherwise
            error("Undefined frequency axis mode");
    end
end

