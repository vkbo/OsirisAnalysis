%
%  Function: fPlotDensityLineout
% *******************************
%  Plot the density for a given t and r
%
%  Input:
% --------
%  oData    :: OsirisData object
%  sSpecies :: Which species
%  iTime    :: Dump number
%  iR       :: R-value
%
%  Output:
% ---------
%  None
%

function fPlotDensityLineout(oData, sSpecies, iTime, iR)

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
    
    % Prepare axes
    aXAxis      = 1e3*linspace(0,dBoxLength*dLFactor,iBoxNZ);

    h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies);
    aCharge = h5Data(:,iR);
    clear h5Data;

    fig1 = figure(1);
    clf;
    
    hold on
    plot(aXAxis, aCharge);

    sSpecies = strrep(sSpecies, '_', ' ');
    sSpecies = regexprep(sSpecies,'(\<[a-z])','${upper($1)}');
    
    sTitle = sprintf('%s Density at R = %d cells and S = %0.2f m', sSpecies, iR, iTime*dTFactor*dLFactor);
    title(sTitle,'FontSize',18);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',16);
    ylabel('Density','FontSize',16);
    
    %axis([92.1, 95.6, 0.0, 0.18]);
    
    pbaspect([1.0,0.4,1.0]);
    hold off;

    saveas(fig1, 'Plots/PlotDensityLineoutFigure1.eps','epsc');

end

