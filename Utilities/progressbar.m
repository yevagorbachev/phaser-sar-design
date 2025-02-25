function func = progressbar(title)
    %
    % Setup:
    % func = progressbar(title)
    %
    % Creates a waitbar with initial value 0, text <title>, and figure name <title>
    % Sets up onCleanup() to close the waitbar on destruction
    % Returns a function with cleaner syntax to set the bar's progress and text
    %
    % Use:
    % func(value)  
    %   set progress bar value to <value> (0 to 1)
    % func(value, format[, fields])
    %   pass additional arguments to sprintf() to change the bar's text

    wb = waitbar(0, title, Name = title);
    oc = onCleanup(@() close(wb));

    func = @callback;
    function callback(varargin)
        narginchk(1, Inf);
        if ~isvalid(wb)
            return;
        end

        if nargin == 1
            waitbar(varargin{1}, wb);
        elseif nargin >= 2
            waitbar(varargin{1}, wb, sprintf(varargin{2:end}));
        end
    end
end

