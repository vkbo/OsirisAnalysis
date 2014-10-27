%
%  Function: fPlotBeamDensityLineout
% ***********************************
%  Plots the density for a given t and r
%
%  Inputs:
% =========
%  oData     :: OsirisData object
%  iTime     :: Dump number
%  iR        :: R-value
%  sSpecies1 :: Which species
%  sSpecies2 :: Which species (optional)
%

function fPlotBeamDensityLineout(oData, iTime, iR, sSpecies1, sSpecies2)


    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotBeamDensityLineout\n');
       fprintf(' ***********************************\n');
       fprintf('  Plots the density for a given t and r\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData     :: OsirisData object\n');
       fprintf('  iTime     :: Dump number\n');
       fprintf('  iR        :: R-value\n');
       fprintf('  sSpecies1 :: Which species\n');
       fprintf('  sSpecies2 :: Which species (optional)\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 5
        sSpecies2 = '';
    end % if
    
    % Check input variables
    sSpecies1 = fTranslateSpecies(sSpecies1);
    sSpecies2 = fTranslateSpecies(sSpecies2);
    iTMax     = oData.Elements.DENSITY.(sSpecies1).charge.Info.Files - 1;
    if iTime > iTMax
        if iTMax == -1
            fprintf('There is no data in this dataset.\n');
            return;
        else
            fprintf('Specified time step is too large. Changed to %d\n', iTMax);
            iTime = iTMax;
        end % if
    end % if

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    dPEnd       = oData.Config.Variables.Plasma.PlasmaEnd;
    dE0         = oData.Config.Variables.Convert.SI.E0;

    % Simulation
    dBoxLength  = oData.Config.Variables.Simulation.BoxX1Max;
    iBoxNZ      = oData.Config.Variables.Simulation.BoxNX1;
    dBoxRadius  = oData.Config.Variables.Simulation.BoxX2Max;
    iBoxNR      = oData.Config.Variables.Simulation.BoxNX2;

    % Factors
    dTFactor    = oData.Config.Variables.Convert.SI.TimeFac;
    dLFactor    = oData.Config.Variables.Convert.SI.LengthFac;
    
    % Prepare axes
    aXAxis      = 1e3*linspace(0,dBoxLength*dLFactor,iBoxNZ);

    fig1 = figure(1);
    clf;
    hold on

    h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies1);
    aCharge = abs(h5Data(:,iR));
    aCharge = aCharge/max(aCharge);
    clear h5Data;

    plot(aXAxis, aCharge, 'color', 'blue');

    sSpecies1   = strrep(sSpecies1, '_', ' ');
    sSpecies1   = regexprep(sSpecies1,'(\<[a-z])','${upper($1)}');
    stLegend{1} = sprintf('$\\mbox{%s}$', sSpecies1);
    
    if ~strcmp(sSpecies2, '')
        h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies2);
        aCharge = abs(h5Data(:,iR));
        aCharge = aCharge/max(aCharge);
        clear h5Data;

        plot(aXAxis, aCharge, 'color', 'red');

        sSpecies2   = strrep(sSpecies2, '_', ' ');
        sSpecies2   = regexprep(sSpecies2,'(\<[a-z])','${upper($1)}');
        stLegend{2} = sprintf('$\\mbox{%s}$', sSpecies2);
    end % if

    sTitle = sprintf('Beam Density at R = %d cells and S = %0.2f m', iR, iTime*dTFactor*dLFactor);
    title(sTitle,'FontSize',16);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',14);
    ylabel('$|Q/Q_{max}|$','interpreter','LaTex','FontSize',14);
    legend(stLegend,'interpreter','LaTex','Location','NW');
    
    axis([0.0, dBoxLength*dLFactor*1e3, -0.05, 1.05]);
    
    pbaspect([1.0,0.4,1.0]);
    hold off;

    %saveas(fig1, 'Plots/PlotDensityLineoutFigure1.eps','epsc');

end

