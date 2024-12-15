function [mag] = mag10(db)
    arguments
        db double;
    end
    mag = 10 .^ (db / 10);
end
