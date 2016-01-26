
%
%  GUI :: Track Species
% **********************
%

function uiTrackSpecies(oData)

    %
    %  Data Struct
    % *************
    %
    
    X.Name  = oData.Config.Name; % Name of dataset

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
    
    fMain = gcf; clf;
    aFPos = get(fMain, 'Position');
    iH    = 770;
    
    % Set Figure Properties
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'MenuBar', 'None');
    set(fMain, 'Position', [aFPos(1:2) 915 iH]);
    set(fMain, 'Name', 'Track Species');
    

end % function
