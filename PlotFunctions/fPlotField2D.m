%
%  Function: fPlotField2D
% ************************
%  Plots a field from OsirisData in 2D
%
%  Inputs:
% =========
%  oData  :: OsirisData object
%  sTime  :: Time dump
%  sField :: Which field to look at
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%

function stReturn = fPlotField2D(oData, sTime, sField, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotField2D\n');
       fprintf(' ************************\n');
       fprintf('  Plots a field from OsirisData in 2D\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData  :: OsirisData object\n');
       fprintf('  sTime  :: Time dump\n');
       fprintf('  sField :: Which field to look at\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  Limits      :: Axis limits\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  HideDump    :: Default No\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('  AutoResize  :: Default On\n');
       fprintf('  CAxis       :: Color axis limits\n');
       fprintf('  ShowOverlay :: Default Yes\n');
       fprintf('\n');
       return;
    end % if

    sField = fTranslateField(sField);
    iTime = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if
    
    if ~isField(sField)
        fprintf(2, 'Error: Non-existent field specified.\n');
    end % if

    
    % Simulation
    dBoxZ  = oData.Config.Variables.Simulation.BoxX1Max;
    dBoxR  = oData.Config.Variables.Simulation.BoxX2Max;
    iBoxNZ = oData.Config.Variables.Simulation.BoxNX1;
    iBoxNR = oData.Config.Variables.Simulation.BoxNX2;
    
    % Factors
    dTFac = oData.Config.Variables.Convert.SI.TimeFac;
    dLFac = oData.Config.Variables.Convert.SI.LengthFac;
    dE0   = oData.Config.Variables.Convert.SI.E0;
    
    % Plasma
    dPSt  = oData.Config.Variables.Plasma.PlasmaStart;
    
    % Colormap
    aCDec = linspace(1,0,256);
    aCInc = linspace(0,1,256);
    aCMid = linspace(1,1,256);
    aCMap = [transpose([aCInc;aCInc;aCMid]);transpose([aCMid;aCDec;aCDec])];

    % Data
    aData = oData.Data(iTime, 'FLD', sField, '');
    aData = aData.*dE0*1e-9;
    aPlot = transpose([fliplr(aData), aData]);
    
    % Limits
    dAMax = max(abs(aData(:)));
    
    % Axes
    aXAxis = linspace(0,dBoxZ*dLFac,iBoxNZ).*1e3;
    aYAxis = linspace(-dBoxR*dLFac,dBoxR*dLFac,2*iBoxNR).*1e3;

    % Plot
    
    imagesc(aXAxis, aYAxis, aPlot);
    caxis([-dAMax,dAMax]);
    %colormap(aCMap);
    colorbar;

    dPosition = (iTime*dTFac - dPSt)*dLFac;
    sTitle    = sprintf('Field %s in GeV after %0.2f metres of plasma (Dump %d)',sField,dPosition,iTime);
    
    title(sTitle,'FontSize',16);
    xlabel('$z \;\mbox{[mm]}$',   'interpreter','LaTex','FontSize',14);
    ylabel('$r \;\mbox{[mm]}$',   'interpreter','LaTex','FontSize',14);

end

