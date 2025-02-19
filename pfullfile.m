% Create fullfile() path, pre-pending the current project 
function path = pfullfile(varargin)
    prj = currentProject();
    path = fullfile(prj.RootFolder, varargin{:});
end

