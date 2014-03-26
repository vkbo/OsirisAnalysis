%
%  Function: fGetEnergyGradient
% ******************************
%  Extracts the energy gradient form OsirisData
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sField   :: What field to analyse. Ex 'e1'
%  aRValues :: Array of R-coordinates to extract
%  aZValues :: Array of Z-coordinates to extraxt
%              [0] generates an array of min, max and zero
%
%  Outputs:
% ==========
%  aGradients :: Matrix of integrated vectors along all R-values
%  aRZ        :: The evolution of each specified R and Z coordinate
%  aRValues   :: A return of the R-values
%  aZValues   :: A retunr of the Z-values
%

function [aGradients, aRZ, aRValues, aZValues] = fGetEnergyGradient(oData, sField, aRValues, aZValues)

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
    
    dBoxRFac    = dBoxRadius/iBoxNR * dLFactor;
    dBoxZFac    = dBoxLength/iBoxNZ * dLFactor;

    iDumpPS     = ceil(dPStart/dTFactor);
    iDumpPE     = floor(dPEnd/dTFactor);
    iTSteps     = iDumpPE-iDumpPS+1;
    
    
    % Extracting data for specified values of r
    
    fprintf('\n');
    fprintf('Extraxting data from dump %d (t=%0.1f) to dump %d (t=%0.1f) ... ', ...
        iDumpPS, iDumpPS*dTFactor, iDumpPE, iDumpPE*dTFactor);
    
    if aZValues(1) ~= 0
        aZValues = [0,0];
    end % if

    aEnergy    = zeros(iBoxNZ, length(aRValues), iTSteps);
    aGradients = zeros(iBoxNZ, length(aRValues));
    
    dScaleFac = dE0*dTFactor*dLFactor*1e-9;  % Gives results in GV/m

    for t=1:iTSteps
        h5Data = oData.Data(t+iDumpPS-1, oData.Elements.FLD.(sField));
        for r=1:length(aRValues)
            aEnergy(:,r,t) = h5Data(:,aRValues(r));
        end % for
    end % for

    fprintf('Done\n');

    fprintf('Calculating integrals ... ');

    for z=1:iBoxNZ
        for r=1:length(aRValues)
            aGradients(z,r) = dScaleFac*trapz(aEnergy(z,r,:));
        end % for
    end % for

    fprintf('Done\n');


    % If no Z-values are provided, use min/max and zero between min and max
    % for all R instead.
    
    if aZValues(1) == 0
        
        fprintf('\n');
        aTemp = [];
    
        for r=1:length(aRValues)

            fprintf('Min/Max/Zero at R = %d cells\n',aRValues(r));
            
            [dMin, idxMin] = min(aGradients(:,r));
            fprintf('Min  : %+7.3f at %d\n', dMin, idxMin);
            aTemp(end+1) = idxMin;
            
            [dMax, idxMax] = max(aGradients(:,r));
            fprintf('Max  : %+7.3f at %d\n', dMax, idxMax);
            aTemp(end+1) = idxMax;
            
            if idxMax > idxMin
                [~, idxZero] = min(abs(aGradients(idxMin:idxMax,r)));
                idxZero = idxMin + idxZero - 1;
            else
                [~, idxZero] = min(abs(aGradients(idxMax:idxMin,r)));
                idxZero = idxMax + idxZero - 1;
            end % if
            fprintf('Zero : %+7.3f at %d\n', aGradients(idxZero,r), idxZero);
            aTemp(end+1) = idxZero;

            fprintf('\n');

        end % for

        aZValues = aTemp;
    end % if

    aRZ = zeros(length(aZValues), length(aRValues), iTSteps);
    

    % Integrating gradients for given values of z and r
    
    if aZValues(1) ~= 0
        for z=1:length(aZValues)
            for r=1:length(aRValues)
                for t=1:iTSteps
                    aRZ(z,r,t) = dScaleFac*trapz(aEnergy(aZValues(z),r,1:t));
                end % for
            end % for
        end % for
    end % if


    % Clean-up
    
    clear aEnergy;
    clear h5Data;

end % function