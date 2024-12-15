function struct2wkspace(stru)
    for field = string(fieldnames(stru))'
        assignin("caller", field, stru.(field));
    end
end
