%
%  Function: fPlotBeamDensityEField
% **********************************
%  Plots the density for a given t and r
%
%  Inputs:
% =========
%  oData     :: OsirisData object
%  iTime     :: Dump number
%  vR        :: R-value as integer or 2-vector
%  sSpecies1 :: Beam 1
%  sSpecies2 :: Beam 2
%  sEField   :: E-field
%
%  Outputs:
% ==========
%  None
%

function fPlotBeamDensityEField(oData, iTime, vR, sSpecies1, sSpecies2, sEField)


    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotBeamDensityEField\n');
       fprintf(' **********************************\n');
       fprintf('  Plots the density for a given t and r\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData     :: OsirisData object\n');
       fprintf('  iTime     :: Dump number\n');
       fprintf('  vR        :: R-value as integer or 2-vector\n');
       fprintf('  iAverage  :: Number of cells to average\n');
       fprintf('  sSpecies1 :: Beam 1\n');
       fprintf('  sSpecies2 :: Beam 2\n');
       fprintf('  sEField   :: E-field (default e1)\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 5
        sSpecies2 = '';
    end % if

    if nargin < 6
        sEField = 'e1';
    end % if
    
    if isvector(vR)
        iRMin = vR(1);
        iRMax = vR(2);
    else
        iRMin = vR;
        iRMax = vR;
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

    hold on

    % EField
    h5Data = oData.Data(iTime, 'FLD', sEField, '');
    aEField = mean(h5Data(:,iRMin:iRMax),2)*dE0*1e-6;
    dScale  = max(abs(aEField));
    aEField = aEField/dScale;
    clear h5Data;

    area(aXAxis, aEField, 'FaceColor', cEField, 'EdgeColor', cEField);
    stLegend{1} = sprintf('E-Field [Max = %.2f MeV]', dScale);

    % Beam 1
    h5Data  = oData.Data(iTime, 'DENSITY', 'charge', sSpecies1);
    aCharge = mean(abs(h5Data(:,iRMin:iRMax)),2);
    dScale  = max(aCharge);
    aCharge = aCharge/dScale;
    clear h5Data;

    plot(aXAxis, aCharge, 'color', cBeam1);

    sSpecies1   = strrep(sSpecies1, '_', ' ');
    sSpecies1   = regexprep(sSpecies1,'(\<[a-z])','${upper($1)}');
    stLegend{2} = sprintf('%s [Scale = 1:%.2f]', sSpecies1, 1/dScale);
    
    % Beam 2
    if ~strcmp(sSpecies2, '')
        h5Data  = oData.Data(iTime, 'DENSITY', 'charge', sSpecies2);
        aCharge = mean(abs(h5Data(:,iRMin:iRMax)),2);
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
    title(sTitle,'FontSize',14);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',12);
    ylabel('$|Q/Q_{max}|\mbox{ or }E/E_{max}$','interpreter','LaTex','FontSize',12);
    legend(stLegend,'Location','SE');
    
    axis([0.0, dBoxLength*dLFactor*1e3, -1.05, 1.05]);
    if dPStart > iTime*dTFactor && dPStart < iTime*dTFactor+dBoxLength
        dPlasma = (dPStart-iTime*dTFactor)*dLFactor*1e3;
        line([dPlasma dPlasma], [-1.05 1.05], 'LineStyle', '--', 'Color', [0.8 0 0.8]);
    end % if
    
    hold off;

    %saveas(fig1, 'Plots/PlotDensityLineoutFigure1.eps','epsc');

end

