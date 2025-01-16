function [prefix, data] = siprefix(data)
    prefixes = dictionary();
    prefixes(-12) = "p";
    prefixes(-9) = "n";
    prefixes(-6) = "u";
    prefixes(-3) = "m";
    prefixes(0) = "";
    prefixes(3) = "k";
    prefixes(6) = "M";
    prefixes(9) = "G";
    prefixes(12) = "T";

    scale = max(log10(data), [], "all");
    exponent = floor(scale/3)*3;
    prefix = prefixes(exponent);
    data = data / 10^exponent;
end
