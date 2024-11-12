function [db] = db20(mag)
    arguments
        mag double;
    end
    db = 20 * log10(abs(mag));
end
