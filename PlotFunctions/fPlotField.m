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

function fPlotField(oData, iTime, sAxis)

    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotField\n');
       fprintf(' **********************\n');
       fprintf('  Plots a field from OsirisData\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  iTime    :: Which dump to look at\n');
       fprintf('  sAxis    :: Which axis to plot\n');
       fprintf('\n');
       return;
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
    aData = oData.Data(iTime, 'FLD', sAxis, '');
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
    sTitle    = sprintf('Field %s in GeV after %0.2f metres of plasma (Dump %d)',sAxis,dPosition,iTime);
    
    title(sTitle,'FontSize',16);
    xlabel('$z \;\mbox{[mm]}$',   'interpreter','LaTex','FontSize',14);
    ylabel('$r \;\mbox{[mm]}$',   'interpreter','LaTex','FontSize',14);

end

