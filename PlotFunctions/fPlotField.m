%
%  Function: fPlotField
% **********************
%  Plots a field from OsirisData
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  iTime    :: Which dump to look at
%  sAxis    :: Which axis to plot
%
%  Optional Inputs:
% ==================
%  sSave    :: 'save' will save plot to file
%
%  Outputs:
% ==========
%  None
%

function fPlotField(oData, iTime, sAxis, sSave)

    % Input
    if nargin < 4
        sSave = '';
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
    aData = oData.Data(iTime, oData.Elements.FLD.(sAxis));
    aData = aData.*dE0*1e-9;
    aPlot = transpose([fliplr(aData), aData]);
    
    % Limits
    dAMax = max(abs(aData(:)));
    
    % Axes
    aXAxis = linspace(0,dBoxZ*dLFac,iBoxNZ).*1e3;
    aYAxis = linspace(-dBoxR*dLFac,dBoxR*dLFac,2*iBoxNR).*1e3;

    % Plot
    fig1 = figure(1);
    clf;
    
    imagesc(aXAxis, aYAxis, aPlot);
    caxis([-dAMax,dAMax]);
    colormap(aCMap);
    colorbar;

    dPosition = (iTime*dTFac - dPSt)*dLFac;
    sTitle    = sprintf('Field %s in GeV after %0.2f metres of plasma (Dump %d)',sAxis,dPosition,iTime);
    
    title(sTitle,'FontSize',18);
    xlabel('$z \;\mbox{[mm]}$',   'interpreter','LaTex','FontSize',16);
    ylabel('$r \;\mbox{[mm]}$',   'interpreter','LaTex','FontSize',16);

    % Save
    if strcmp(sSave, 'save')
        pbaspect([1.0,0.5,1.0]);
        [sPath, ~, ~] = fileparts(mfilename('fullpath'));
        saveas(fig1, sprintf('%s/../Plots/PloFieldFigure1',sPath),'epsc');
        pbaspect('auto');
    end % if

end

