%
%  Function: fPlotPhase2D
% ************************
%  Plots 2D Phase Data
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  iTime    :: Which dump to look at
%  sSpecies :: Which species to look at
%  sAxis1   :: Which axis to plot
%  sAxis2   :: Which axis to plot
%
%  Outputs:
% ==========
%  None
%

function fPlotPhase2D(oData, iTime, sSpecies, sAxis1, sAxis2)

    % Help output
    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotPhase2D\n');
        fprintf(' ************************\n');
        fprintf('  Plots 2D Phase Data\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  iTime    :: Which dump to look at\n');
        fprintf('  sSpecies :: Which species to look at\n');
        fprintf('  sAxis1   :: Which axis to plot\n');
        fprintf('  sAxis2   :: Which axis to plot\n');
        fprintf('\n');
        return;
    end % if

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
    



end

