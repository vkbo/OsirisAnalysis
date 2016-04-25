
%
%  GUI :: Time Tools
% *******************
%

function uiTimeTools(oData, varargin)

    % Check Input
    if nargin < 1
        fprintf(2,'Error: Please provide an OsirisData object.\n');
        return;
    end %if

    % Read input parameters
    oOpt = inputParser;
    addParameter(oOpt, 'Position', []);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

end % end GUI function
