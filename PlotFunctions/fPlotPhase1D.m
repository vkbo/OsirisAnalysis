%
%  Function: fPlotPhase1D
% ************************
%  Plots 1D Phase Data
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  iTime    :: Which dump to look at
%  sSpecies :: Which species to look at
%  sAxis    :: Which axis to plot
%
%  Outputs:
% ==========
%  None
%

function fPlotPhase1D(oData, iTime, sSpecies, sAxis)

    % Beam diag
    iNP1   = oData.Config.Variables.Beam.(sSpecies).DiagNP1;
    iNP2   = oData.Config.Variables.Beam.(sSpecies).DiagNP2;
    iNP3   = oData.Config.Variables.Beam.(sSpecies).DiagNP3;
    dP1Min = oData.Config.Variables.Beam.(sSpecies).DiagP1Min;
    dP2Min = oData.Config.Variables.Beam.(sSpecies).DiagP2Min;
    dP3Min = oData.Config.Variables.Beam.(sSpecies).DiagP3Min;
    dP1Max = oData.Config.Variables.Beam.(sSpecies).DiagP1Max;
    dP2Max = oData.Config.Variables.Beam.(sSpecies).DiagP2Max;
    dP3Max = oData.Config.Variables.Beam.(sSpecies).DiagP3Max;
    
    % Beam
    dRQM   = oData.Config.Variables.Beam.(sSpecies).RQM;
    dEMass = oData.Config.Variables.Constants.ElectronMassMeV;
    
    % Factors
    dPFac  = abs(dRQM)*dEMass;
    dPMin  = sqrt(abs(dP1Min)^2 + 1)*dPFac*(dP1Min/abs(dP1Min));
    dPMax  = sqrt(abs(dP1Max)^2 + 1)*dPFac*(dP1Max/abs(dP1Max));
    
    % Axes
    aXAxis = linspace(dPMin,dPMax,iNP1);

    
    h5Data = oData.Data(iTime, oData.Elements.PHA.(sAxis).(sSpecies));
    
    fig1 = figure(1);
    
    plot(aXAxis,h5Data);

end

