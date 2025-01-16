% Create fullfile() path, pre-pending the current project 
function path = proj_file(varargin)
    prj = currentProject();
    path = fullfile(prj.RootFolder, varargin{:});
end

