%
%  Function: fPlotAverageEnergy
% ******************************
%  Find average beam energy
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sSpecies :: Which species to look at
%  sAxis    :: Which axis to follow
%

function aTrack = fPlotAverageEnergy(oData, sSpecies, sAxis)

    % Input
    
    sSpecies = fTranslateSpecies(sSpecies);

    % Beam
    dRQM        = oData.Config.Variables.Beam.(sSpecies).RQM;
    dEMass      = oData.Config.Variables.Constants.ElectronMassMeV;
    dCharge     = oData.Config.Variables.Constants.ElementaryCharge;
    dPFac       = abs(dRQM)*dEMass;

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    dPEnd       = oData.Config.Variables.Plasma.PlasmaEnd;

    % Factors
    dTFactor    = oData.Config.Variables.Convert.SI.TimeFac;
    dLFactor    = oData.Config.Variables.Convert.SI.LengthFac;
    iFiles      = oData.Elements.PHA.(sAxis).(sSpecies).Info.Files;
    
    % Dumps
    iDumpPS     = ceil(dPStart/dTFactor);
    iDumpPE     = floor(dPEnd/dTFactor);
    
    if iDumpPE >= iFiles
        iDumpPE = iFiles - 1;
    end % if

    iTSteps  = iDumpPE-iDumpPS+1;
    aAverage = zeros(1,iTSteps);
    
    for s=1:iTSteps
        aData = oData.Data(iDumpPE-s+1, oData.Elements.PHA.(sAxis).(sSpecies));
        %aAverage(s) = sqrt(abs(mean(aData))^2 + 1)*dPFac;
        aAverage(s) = abs(mean(aData))*dPFac;
    end % for

    % Plot
    fig1 = figure(1);
    clf;
    hold on;
    
    plot(aAverage);

    sTitle = sprintf('Average %s as a function of s', sAxis);
    
    title(sTitle,'FontSize',16);
    xlabel('$S \;\mbox{[m]}$','interpreter','LaTex','FontSize',14);
    ylabel('$\mbox{GeV}$',    'interpreter','LaTex','FontSize',14);
    
    hold off;
    
end

