function siprefix(label_fmt, axis, ruler_field, tick_field)
    ruler = axis.(ruler_field);
    [mul, prefix] = get_prefix(ruler.Exponent);
    ruler.Exponent = 0;
    ruler.Label.String = sprintf(label_fmt, prefix);
    axis.(tick_field) = compose(ruler.TickLabelFormat, mul * ruler.TickValues);
end

function [mul, text] = get_prefix(expnt)
    % prevpow3 = floor(expnt/3)*3;
    breakpoints = (-12):3:12;
    prefixes = ["p", "n", "u", "m", "", "k", "M", "G", "T"];
    assert(length(prefixes) == length(breakpoints), "Every exponent must be assigned a prefix")

    pt = find(expnt >= breakpoints, 1, "last");
    if isempty(pt)
        error("Input out of range");
    end

    mul = 10 ^ -breakpoints(pt);
    text = prefixes(pt);
end

