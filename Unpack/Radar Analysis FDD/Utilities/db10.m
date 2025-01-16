function [db] = db10(mag)
    arguments
        mag double;
    end
    db = 10 * log10(abs(mag));
end
