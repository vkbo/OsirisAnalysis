
%
%  GUI :: Phase Space
% ********************
%

function uiPhaseSpace(oData, varargin)

    %
    %  Input
    % *******
    %

    % Check Input
    if nargin < 1
        fprintf(2,'Error: Please provide an OsirisData object.\n');
        return;
    end %if

    % Read input parameters
    oOpt = inputParser;
    addParameter(oOpt, 'Position', []);
    addParameter(oOpt, 'ReUseFig', 'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    %
    %  Figure
    % ********
    %
    
    if strcmpi(stOpt.ReUseFig,'Yes')
        hMain = findobj('Tag','uiOA-PS');
        set(0,'CurrentFigure',hMain);
        clf;
    else
        hMain = figure('IntegerHandle','Off'); clf;
    end % if
    
    aFPos = get(hMain, 'Position');
    figW  = 1170;
    figH  = 610;
    
    if isempty(stOpt.Position)
        figX = aFPos(1);
        figY = aFPos(2);
    else
        figX = stOpt.Position(1);
        figY = stOpt.Position(2);
    end % if
    
    % Set Figure Properties
    hMain.Units        = 'Pixels';
    hMain.MenuBar      = 'None';
    hMain.Position     = [figX figY figW figH];
    hMain.Name         = 'OsirisAnalysis: Phase Space';
    hMain.NumberTitle  = 'Off';
    hMain.DockControls = 'Off';
    hMain.Tag          = 'uiOA-PS';

    %
    %  Initial Values
    % ****************
    %
    
    % Get Values
    iDumps  = oData.MSData.MaxFiles;
    dPStart = oData.Config.Simulation.PlasmaStart;
    dTFac   = oData.Config.Convert.SI.TimeFac;
    dLFac   = oData.Config.Convert.SI.LengthFac;

    % Get DataSet Info
    X.Name    = oData.Config.Name;                          % Name of dataset
    X.Species = fieldnames(oData.Config.Particles.Species); % All species in dataset
    X.Cyl     = oData.Config.Simulation.Cylindrical;
    X.Dim     = oData.Config.Simulation.Dimensions;

    if isempty(X.Species)
        fprintf(2,'Error: Dataset contains no species.\n');
        return;
    end % if

    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(2);
    

    
end % end GUI function
