
%
%  GUI :: Track Species
% **********************
%

function uiTrackSpecies(oData)

    %
    %  Data Struct
    % *************
    %
    
    % Check Input
    if nargin < 1
        fprintf(2,'Error: Please provide an OsirisData object.\n');
        return;
    end %if
    
    % Get DataSet Info
    X.Name = oData.Config.Name; % Name of dataset

    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(2);
    
    % Get Time Axis
    iDumps  = oData.Elements.FLD.e1.Info.Files-1;
    dPStart = oData.Config.Simulation.PlasmaStart;
    dTFac   = oData.Config.Convert.SI.TimeFac;
    dLFac   = oData.Config.Convert.SI.LengthFac;
    X.TAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
    

    %
    %  Figure
    % ********
    %
    
    fMain = figure('IntegerHandle', 'Off'); clf;
    aFPos = get(fMain, 'Position');
    iH    = 600;
    
    % Set Figure Properties
    fMain.Units        = 'Pixels';
    fMain.MenuBar      = 'None';
    fMain.Position     = [aFPos(1:2) 800 iH];
    fMain.Name         = 'OsirisAnalysis: Track Species';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-TS';
    
    
    

end % function
