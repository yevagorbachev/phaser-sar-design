function [mag] = mag20(db)
    arguments
        db double;
    end
    mag = 10 .^ (db / 20);
end
