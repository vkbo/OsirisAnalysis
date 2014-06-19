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

function stInfo = fPlotDensity(oData, iTime, sSpecies)

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
    
    % Prepare output
    stInfo = struct;

    % Constants
    dC          = oData.Config.Variables.Constants.SpeedOfLight;
    dE          = oData.Config.Variables.Constants.ElementaryCharge;

    % Simulation
    dBoxLength  = oData.Config.Variables.Simulation.BoxX1Max;
    iBoxNZ      = oData.Config.Variables.Simulation.BoxNX1;
    dDeltaZ     = dBoxLength/double(iBoxNZ);
    dBoxRadius  = oData.Config.Variables.Simulation.BoxX2Max;
    iBoxNR      = oData.Config.Variables.Simulation.BoxNX2;
    dDeltaR     = dBoxRadius/double(iBoxNR);
    
    % Factors
    dTFactor    = oData.Config.Variables.Convert.SI.TimeFac;
    dLFactor    = oData.Config.Variables.Convert.SI.LengthFac;
    dE0         = oData.Config.Variables.Convert.SI.E0;

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    dOmegaP     = oData.Config.Variables.Plasma.NormOmegaP;
    
    % Prepare axes
    aXAxis      = linspace(0,dBoxLength*dLFactor*1e3,iBoxNZ);
    aYAxis      = linspace(-dBoxRadius*dLFactor*1e3,dBoxRadius*dLFactor*1e3,2*iBoxNR);

    % Get data
    h5Data      = oData.Data(iTime, oData.Elements.DENSITY.(sSpecies).charge);
    
    % Find peak
    aProjZ = zeros(iBoxNZ,1);
    aProjR = zeros(iBoxNR,1);
    for i=1:iBoxNZ
        aProjZ(i) = sum(h5Data(i,:));
    end % for
    for i=1:iBoxNR
        aProjR(i) = sum(h5Data(:,i));
    end % for
    
    [dZMax, iZMax] = max(abs(aProjZ));
    [dRMax, iRMax] = max(abs(aProjR));
    
    stInfo.ZPeakVal = dZMax;
    stInfo.ZPeakInd = iZMax;
    stInfo.RPeakVal = dRMax;
    stInfo.RPeakInd = iRMax;
    
    % Integrate beam
    dBeam = 0.0;
    for i=1:iBoxNR
        %dBeam = dBeam + double(i)*sum(h5Data(:,i));
        %dBeam = dBeam + (double(i)^2-(double(i)-1)^2)*sum(h5Data(:,i));
        dBeam = dBeam + double(i)*sum(h5Data(:,i));
    end % for
    %dBeam = dBeam*2*pi*dLFactor*dE*dBoxRScale*1e9;
    %dBeam = dBeam*2*pi*dDeltaZ*dDeltaR^2*dE*1e9*dOmegaP^3/dC^3;
    %dBeam = dBeam*2*pi;
    fprintf('Sum: %d\n', dBeam);

    % Plot

    imagesc(aXAxis, aYAxis, transpose([fliplr(h5Data),h5Data]));
    colormap(jet);
    colorbar();

    dPosition = (iTime*dTFactor - dPStart)*dLFactor;
    sTitle    = sprintf('Density after %0.2f metres of plasma (Dump %d)',dPosition,iTime);

    title(sTitle,'FontSize',14);
    xlabel('$z \;\mbox{[mm]}$','interpreter','LaTex','FontSize',12);
    ylabel('$r \;\mbox{[mm]}$','interpreter','LaTex','FontSize',12);
    
end
