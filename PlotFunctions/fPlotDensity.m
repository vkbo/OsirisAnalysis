%
%  Function: fPlotDensity
% ************************
%  Plot density
%

function fPlotDensity(oData, iTime, sSpecies, iSave)

    % Help output

    if nargin == 0
        fprintf('\n');
        fprintf(' Usage: fPlotDensity(oData, sTime, sSpecies)\n');
        fprintf('\n');
        fprintf(' Input:\n');
        fprintf(' oData    :: OsirisData object\n');
        fprintf(' sTime    :: Time dump.\n');
        fprintf(' sSpecies :: Which species to look at\n');
        fprintf(' iSave    :: Optional. 1 will save\n');
        fprintf('\n');
        fprintf(' Output:\n');
        fprintf(' None\n');
        fprintf('\n');
        return;
    end % if
    
    if nargin < 4
        iSave = 0;
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
    
    if iSave
        saveas(fig1, 'Plots/PlotDensityFigure1.eps','epsc');
    end % if

end
