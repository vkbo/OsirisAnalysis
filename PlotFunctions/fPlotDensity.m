%
%  Function: fPlotDensity
% ************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Time dump
%  sSpecies :: Which species to look at
%
%  Optional Inputs:
% ==================
%  sSave    :: 'save' will save plot to file
%
%  Outputs:
% ==========
%  None
%

function fPlotDensity(oData, iTime, sSpecies, sSave)

    % Input
    if nargin < 4
        sSave = '';
    end % if

    % Simulation
    dBoxLength  = oData.Config.Variables.Simulation.BoxX1Max;
    iBoxNZ      = oData.Config.Variables.Simulation.BoxNX1;
    dBoxRadius  = oData.Config.Variables.Simulation.BoxX2Max;
    iBoxNR      = oData.Config.Variables.Simulation.BoxNX2;

    % Factors
    dTFactor    = oData.Config.Variables.Convert.SI.TimeFac;
    dLFactor    = oData.Config.Variables.Convert.SI.LengthFac;
    dE0         = oData.Config.Variables.Convert.SI.E0;

    % Prepare axes
    aXAxis      = linspace(0,dBoxLength*dLFactor*1e3,iBoxNZ);
    aYAxis      = linspace(-dBoxRadius*dLFactor*1e3,dBoxRadius*dLFactor*1e3,2*iBoxNR);

    % Get data
    h5Data      = oData.Data(iTime, oData.Elements.DENSITY.(sSpecies).charge);

    % Plot
    fig1 = figure(1);

    imagesc(aXAxis, aYAxis, dE0*transpose([fliplr(h5Data),h5Data]));
    colorbar();

    sTitle = sprintf('%s - Dump %d - S=%0.2f m', sSpecies, iTime, iTime*dTFactor*dLFactor);
    title(sTitle,'FontSize',18);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',16);
    ylabel('$r \;\mbox{[mm]}$','interpreter','LaTex','FontSize',16);
    
    % Save plot
    if strcmp(sSave, 'save')
        [sPath, ~, ~] = fileparts(mfilename('fullpath'));
        saveas(fig1, sprintf('%s/../Plots/PlotDensityFigure1.eps',sPath),'epsc');
    end % if

end
