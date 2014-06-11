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
%  Outputs:
% ==========
%  None
%

function fPlotDensity(oData, iTime, sSpecies)

    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotDensity\n');
       fprintf(' ************************\n');
       fprintf('  Plots density plot\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  sTime    :: Time dump\n');
       fprintf('  sSpecies :: Which species to look at\n');
       fprintf('\n');
       return;
    end % if

    % Check input variables
    sSpecies = fTranslateSpecies(sSpecies);
    iTMax    = oData.Elements.DENSITY.(sSpecies).charge.Info.Files - 1;
    if iTime > iTMax
        if iTMax == -1
            fprintf('There is no data in this dataset.\n');
            return;
        else
            fprintf('Specified time step is too large. Changed to %d\n', iTMax);
            iTime = iTMax;
        end % if
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

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    
    % Prepare axes
    aXAxis      = linspace(0,dBoxLength*dLFactor*1e3,iBoxNZ);
    aYAxis      = linspace(-dBoxRadius*dLFactor*1e3,dBoxRadius*dLFactor*1e3,2*iBoxNR);

    % Get data
    h5Data      = oData.Data(iTime, oData.Elements.DENSITY.(sSpecies).charge);

    % Plot

    imagesc(aXAxis, aYAxis, dE0*transpose([fliplr(h5Data),h5Data]));
    colormap(jet);
    colorbar();

    dPosition = (iTime*dTFactor - dPStart)*dLFactor;
    sTitle    = sprintf('Density after %0.2f metres of plasma (Dump %d)',dPosition,iTime);

    title(sTitle,'FontSize',16);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',14);
    ylabel('$r \;\mbox{[mm]}$','interpreter','LaTex','FontSize',14);
    
end
