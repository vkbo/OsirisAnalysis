%
%  Function: fPlotDensityEField
% ******************************
%  Plots the density for a given t and r
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  iTime    :: Dump number
%  sSpecies :: Which species
%  iR       :: R-value
%
%  Outputs:
% ==========
%  None
%

function fPlotDensityEField(oData, iTime, iR, sSpecies1, sSpecies2)


    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotDensityEField\n');
       fprintf(' ******************************\n');
       fprintf('  Plots the density for a given t and r\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  iTime    :: Dump number\n');
       fprintf('  sSpecies :: Which species\n');
       fprintf('  iR       :: R-value\n');
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
    cEField     = [0.5,0.8,0.5];
    cBeam1      = 'blue';
    cBeam2      = 'red';

    fig1 = figure(1);
    clf;
    hold on

    % EField
    h5Data = oData.Data(iTime, 'FLD', 'e1', '');
    aEField = h5Data(:,iR)*dE0*1e-9;
    aEField = fSmoothVector(aEField, 5);
    dScale  = abs(max(aEField));
    aEField = aEField/dScale;
    clear h5Data;

    area(aXAxis, aEField, 'FaceColor', cEField, 'EdgeColor', cEField);
    stLegend{1} = sprintf('E-Field [Max = %.3f GeV]', dScale);

    % Beam 1
    h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies1);
    aCharge = abs(h5Data(:,iR));
    aCharge = fSmoothVector(aCharge, 5);
    dScale  = max(aCharge);
    aCharge = aCharge/dScale;
    clear h5Data;

    plot(aXAxis, aCharge, 'color', cBeam1);

    sSpecies1   = strrep(sSpecies1, '_', ' ');
    sSpecies1   = regexprep(sSpecies1,'(\<[a-z])','${upper($1)}');
    stLegend{2} = sprintf('%s [Scale = 1:%.2f]', sSpecies1, 1/dScale);
    
    % Beam 2
    if ~strcmp(sSpecies2, '')
        h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies2);
        aCharge = abs(h5Data(:,iR));
        aCharge = fSmoothVector(aCharge, 5);
        dScale  = max(aCharge);
        aCharge = aCharge/dScale;
        clear h5Data;

        plot(aXAxis, aCharge, 'color', cBeam2);

        sSpecies2   = strrep(sSpecies2, '_', ' ');
        sSpecies2   = regexprep(sSpecies2,'(\<[a-z])','${upper($1)}');
        stLegend{3} = sprintf('%s [Scale = 1:%.2f]', sSpecies2, 1/dScale);
    end % if

    dPosition = (iTime*dTFactor - dPStart)*dLFactor;
    sTitle = sprintf('Beam density and E-field after %0.2f metres of plasma (Dump %d)', dPosition, iTime);
    %sTitle = sprintf('Beam Density at R = %d cells and S = %0.2f m', iR, iTime*dTFactor*dLFactor);
    title(sTitle,'FontSize',16);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',14);
    ylabel('$|Q/Q_{max}|\mbox{ or }E/E_{max}$','interpreter','LaTex','FontSize',14);
    legend(stLegend,'Location','SE');
    
    axis([0.0, dBoxLength*dLFactor*1e3, -1.05, 1.05]);
    
    pbaspect([1.0,0.4,1.0]);
    hold off;

    %saveas(fig1, 'Plots/PlotDensityLineoutFigure1.eps','epsc');

end

