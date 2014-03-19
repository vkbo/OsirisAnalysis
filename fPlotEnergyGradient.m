%
%  Function: fPlotEnergyGradient
% *******************************
%  Plot the energy gradient form OsirisData
%
%  Input:
% --------
%  oData      :: OsirisData object
%  aGradients :: Energy gradients
%  aRZ        :: Evolution in energy gradient
%
%  Output:
% ---------
%  None
%

function fPlotEnergyGradient(oData, aGradients, aRZ, aRValues, aZValues)

    % Constants
    dC          = oData.Config.Variables.Constants.SpeedOfLight;

    % Time
    dTimeStep   = oData.Config.Variables.Simulation.TimeStep;
    iNDump      = oData.Config.Variables.Simulation.NDump;

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    dPEnd       = oData.Config.Variables.Plasma.PlasmaEnd;
    dOmegaP     = oData.Config.Variables.Plasma.OmegaP;
    dE0         = oData.Config.Variables.Plasma.E0;

    % Simulation
    dBoxLength  = oData.Config.Variables.Simulation.BoxLength;
    iBoxNZ      = oData.Config.Variables.Simulation.BoxNZ;
    dBoxRadius  = oData.Config.Variables.Simulation.BoxRadius;
    iBoxNR      = oData.Config.Variables.Simulation.BoxNR;

    % Runtime variables
    dTFactor    = dTimeStep*iNDump;
    dLFactor    = dC / dOmegaP;
    iDumpPS     = ceil(dPStart/dTFactor);
    iDumpPE     = floor(dPEnd/dTFactor);
    iTSteps     = iDumpPE-iDumpPS+1;

    % Prepare axes
    aXAxis1     = 1e3*linspace(0,dBoxLength*dLFactor,iBoxNZ);
    aXAxis2     = dTFactor*dLFactor*linspace(iDumpPS,iDumpPE,iTSteps);
    
    
    % Plot 1

    fig1 = figure(1);
    clf;

    cMap  = hsv(length(aRValues));
    dMax  = 1.1*max(abs(aGradients(:)));
    dRFac = (dBoxRadius/iBoxNR)*dLFactor*1e6;
    dZFac = (dBoxLength/iBoxNZ)*dLFactor*1e3;

    hold on;
    for r=1:length(aRValues)
        plot(aXAxis1, aGradients(:,r),'color',cMap(r,:));
        stLegend{r} = sprintf('$\\mbox{R}=%0.2f \\; \\mu m$',dRFac*aRValues(r));
    end % for
    axis([0, dBoxLength*dLFactor*1e3, -dMax, dMax]);

    title('Energy Gain at End of Plasma','FontSize',22);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',16);
    ylabel('$\Delta E = e\int E_z(s)\;ds \quad \mbox{[GeV]}$','interpreter','LaTex','FontSize',16);
    legend(stLegend,'interpreter','LaTex');
    
    pbaspect([1.0,0.5,1.0]);
    hold off;
    
    saveas(fig1, 'Plots/PlotEnergyGradientFigure1.eps','epsc');


    % Plot 2

    fig2 = figure(2);
    clf;
    
    stMMZ = {'Min','Max','Zero'};

    hold on;
    for i=1:3
        plot(aXAxis2, squeeze(aRZ(i,1,:)),'color',cMap(i,:));
        stLegend{i} = sprintf('$\\mbox{%s at Z}=%0.2f \\; mm$',stMMZ{i}, dZFac*aZValues(i));
    end % for
    hold off;

    title('Energy Gain as Function of s','FontSize',22);
    xlabel('$s \;\mbox{[m]}$','interpreter','LaTex','FontSize',16);
    ylabel('$\Delta E = e\int E_z(s)\;ds \quad \mbox{[GeV]}$','interpreter','LaTex','FontSize',16);
    legend(stLegend,'interpreter','LaTex','Location','NW');
    
    pbaspect([1.0,0.5,1.0]);
    hold off;

    saveas(fig2, 'Plots/PlotEnergyGradientFigure2.eps','epsc');

end

