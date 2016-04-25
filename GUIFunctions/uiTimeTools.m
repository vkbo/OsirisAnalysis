
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
    
    % Get Time Axis
    X.TAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
    
    % Tracking
    X.Plot.Time = [X.Limits(2) X.Limits(3)];

    %
    %  Figure
    % ********
    %
    
    %fMain = figure('IntegerHandle', 'Off'); clf;
    fMain = figure(1); clf;
    aFPos = get(fMain, 'Position');
    iH    = 610;
    
    % Set Figure Properties
    fMain.Units        = 'Pixels';
    fMain.MenuBar      = 'None';
    fMain.Position     = [aFPos(1:2) 1170 iH];
    fMain.Name         = 'OsirisAnalysis: Time Tools';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-TT';
    
end % end GUI function
