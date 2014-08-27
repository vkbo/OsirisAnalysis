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
%  Optional Inputs:
% ==================
%  aCount   :: Array of energies to count between (in MeV)
%  dMin     :: Lower cutoff
%  dMax     :: Upper cutoff
%

function fPlotPhase1D(oData, iTime, sSpecies, sAxis, aCount, dMin, dMax)


    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotPhase1D\n');
       fprintf(' ************************\n');
       fprintf('  Plots 1D Phase Data\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  iTime    :: Which dump to look at\n');
       fprintf('  sSpecies :: Which species to look at\n');
       fprintf('  sAxis    :: Which axis to plot\n');
       fprintf('\n');
       fprintf('  Optional Inputs:\n');
       fprintf(' ==================\n');
       fprintf('  aCount   :: Array of energies to count between (in MeV)\n');
       fprintf('  dMin     :: Lower cutoff\n');
       fprintf('  dMax     :: Upper cutoff\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 5
        aCount = [0];
    end % if
    
    if nargin < 6
        dMin = -1.0e1000;
    end % if

    if nargin < 7
        dMax = 1.0e1000;
    end % if
    
    sSpecies = fTranslateSpecies(sSpecies);
    aAllowed = {'p1','p2','p3','x1','x2','x3'};
    if ~ismember(sAxis, aAllowed)
        fprintf('Error: Unknown axis\n');
        return;
    end % if
    

    %
    %  Extracting Simulation Data
    % ****************************
    %

    % Beam diag
    iNP1    = oData.Config.Variables.Beam.(sSpecies).DiagNP1;
    iNP2    = oData.Config.Variables.Beam.(sSpecies).DiagNP2;
    iNP3    = oData.Config.Variables.Beam.(sSpecies).DiagNP3;
    dP1Min  = oData.Config.Variables.Beam.(sSpecies).DiagP1Min;
    dP2Min  = oData.Config.Variables.Beam.(sSpecies).DiagP2Min;
    dP3Min  = oData.Config.Variables.Beam.(sSpecies).DiagP3Min;
    dP1Max  = oData.Config.Variables.Beam.(sSpecies).DiagP1Max;
    dP2Max  = oData.Config.Variables.Beam.(sSpecies).DiagP2Max;
    dP3Max  = oData.Config.Variables.Beam.(sSpecies).DiagP3Max;

    iNX1    = oData.Config.Variables.Beam.(sSpecies).DiagNX1;
    iNX2    = oData.Config.Variables.Beam.(sSpecies).DiagNX2;
    iNX3    = oData.Config.Variables.Beam.(sSpecies).DiagNX3;
    dX1Min  = oData.Config.Variables.Beam.(sSpecies).DiagX1Min;
    dX2Min  = oData.Config.Variables.Beam.(sSpecies).DiagX2Min;
    dX3Min  = oData.Config.Variables.Beam.(sSpecies).DiagX3Min;
    dX1Max  = oData.Config.Variables.Beam.(sSpecies).DiagX1Max;
    dX2Max  = oData.Config.Variables.Beam.(sSpecies).DiagX2Max;
    dX3Max  = oData.Config.Variables.Beam.(sSpecies).DiagX3Max;

    % Beam
    dRQM    = oData.Config.Variables.Beam.(sSpecies).RQM;
    dEMass  = oData.Config.Variables.Constants.ElectronMassMeV;
    dCharge = oData.Config.Variables.Constants.ElementaryCharge;
    dPFac   = abs(dRQM)*dEMass;
    dP1Init = oData.Config.Variables.Beam.(sSpecies).Momentum1*dPFac;
    dP2Init = oData.Config.Variables.Beam.(sSpecies).Momentum2*dPFac;
    dP3Init = oData.Config.Variables.Beam.(sSpecies).Momentum3*dPFac;

    % Factors
    dSign  = dRQM/abs(dRQM);
    

    %
    %  Axis Conditions
    % *****************
    %

    switch(sAxis)
        case 'p1'
            if abs(dRQM) < 1000.0
                sXUnit  = 'MeV';
                sXLabel = '$p_z \mbox{[MeV/c]}$';
                dScale  = 1.0;
            else
                sXUnit  = 'GeV';
                sXLabel = '$p_z \mbox{[GeV/c]}$';
                dScale  = 1.0e-3;
            end % if
        case 'p2'
            if abs(dRQM) < 1000.0
                sXUnit  = 'keV';
                sXLabel = '$p_r \mbox{[keV/c]}$';
                dScale  = 1.0e3;
            else
                sXUnit  = 'MeV';
                sXLabel = '$p_r \mbox{[MeV/c]}$';
                dScale  = 1.0;
            end % if
        case 'p3'
            if abs(dRQM) < 1000.0
                sXUnit  = 'keV';
                sXLabel = '$p_{\theta} \mbox{[MeV/c]}$';
                dScale  = 1.0e3;
            else
                sXUnit  = 'MeV';
                sXLabel = '$p_{\theta} \mbox{[MeV/c]}$';
                dScale  = 1.0;
            end % if
        case 'x1'
            sXUnit  = 'mm';
            sXLabel = '$z \mbox{[mm]}$';
        case 'x2'
            sXUnit  = 'mm';
            sXLabel = '$r \mbox{[mm]}$';
        case 'x3'
            sXUnit  = 'mm';
            sXLabel = '$\theta$';
    end % switch

    switch(sAxis)
        case 'p1'
            dPMin  = dP1Min;
            dPMax  = dP1Max;
            dPInit = dP1Init*dScale;
            iNP    = iNP1;
        case 'p2'
            dPMin  = dP2Min;
            dPMax  = dP2Max;
            dPInit = dP2Init*dScale;
            iNP    = iNP2;
        case 'p3'
            dPMin  = dP3Min;
            dPMax  = dP3Max;
            dPInit = dP3Init*dScale;
            iNP    = iNP3;
        case 'x1'
            dXMin = dX1Min;
            dXMax = dX1Max;
            iNX   = iNX1;
        case 'x2'
            dXMin = dX2Min;
            dXMax = dX2Max;
            iNX   = iNX2;
        case 'x3'
            dXMin = dX3Min;
            dXMax = dX3Max;
            iNX   = iNX3;
    end % switch
    

    %
    %  Data Processing
    % *****************
    %

    % Data
    h5Data = oData.Data(iTime, 'PHA', sAxis, sSpecies);
    h5Data = h5Data/sum(abs(h5Data));
    iLen   = length(h5Data);

    if strcmpi(sAxis, 'p1') || strcmpi(sAxis, 'p2') || strcmpi(sAxis, 'p3')
        
        if abs(dPMin) > 0.0
            dPMin = sqrt(abs(dPMin)^2 + 1)*dPFac*(dPMin/abs(dPMin))*dScale;
        end % if
        if abs(dPMax) > 0.0
            dPMax = sqrt(abs(dPMax)^2 + 1)*dPFac*(dPMax/abs(dPMax))*dScale;
        end % if
    
        % Axes
        aXAxis = linspace(dPMin,dPMax,iNP);

        % X-axis spread
        dYMin = min(abs(h5Data));
        dYMax = max(abs(h5Data));

        iXMin = 1;
        iXMax = iLen;
        
        dSum   = sum(abs(h5Data));
        dLInit = 0.0;
        dAInit = 0.0;
        dMInit = 0.0;
        
        if aCount(end) < aXAxis(iXMax)
            aCount(end+1) = aXAxis(iXMax);
        end % if
        aTCount = zeros(length(aCount)-1,1);

        % Find lower and upper limit of data between min and max
        for i=1:length(h5Data)
            if iXMin == 1 && abs(h5Data(i)) > dYMin
                iXMin = i;
            end % if
            if iXMax == iLen && abs(h5Data(iLen-i+1)) > dYMin
                iXMax = iLen-i+1;
            end % if
        end % for
        dXMin = aXAxis(iXMin)*0.9;
        dXMax = aXAxis(iXMax)*1.1;
        
        fprintf('\n');
        fprintf('Momentum spread, min:   %6.1f %s\n', aXAxis(iXMin), sXUnit);
        fprintf('Momentum spread, max:   %6.1f %s\n', aXAxis(iXMax), sXUnit);
        fprintf('Initial beam momentum:  %6.1f %s\n', dPInit, sXUnit);
        fprintf('\n');

        % Find cuttoff index
        iMin = -1;
        iMax = 1e10;
        for i=1:length(h5Data)
            if iMin == -1 && aXAxis(i) >= dMin
                iMin = i;
            end % if
            if iMax == 1e10 && aXAxis(i) >= dMax
                iMax = i;
            end % if
        end % for
        
        % Update range
        if iXMin < iMin
            iXMin = iMin;
            dXMin = aXAxis(iXMin);
            dYMin = min(dSign*h5Data(iXMin:iXMax));
        end % if
        if iXMax > iMax
            iXMax = iMax;
            dXMax = aXAxis(iXMax);
            dYMax = max(dSign*h5Data(iXMin:iXMax));
        end % if

        % Calculate range for initial momentum
        if dPInit == 0
            dXSpan = aXAxis(iXMax)-aXAxis(iXMin);
            dXPM   = dXSpan/500.0;
        else
            dXPM   = dPInit/20.0;
        end % if

        for i=1:length(h5Data)

            if aXAxis(i) < dPInit-dXPM
                dLInit = dLInit + abs(h5Data(i));
            end % if
            if aXAxis(i) >= dPInit-dXPM && aXAxis(i) <= dP1Init+dXPM
                dAInit = dAInit + abs(h5Data(i));
            end % if
            if aXAxis(i) > dPInit+dXPM
                dMInit = dMInit + abs(h5Data(i));
            end % if
            
            for j=2:length(aCount)
                if aXAxis(i) >= aCount(j-1) && aXAxis(i) < aCount(j)
                    aTCount(j-1) = aTCount(j-1) + abs(h5Data(i));
                end % if
            end % for
            
        end % for
        
        fprintf('Fraction below initial: %6.2f %%\n', 100*dLInit/dSum);
        fprintf('Fraction at initial:    %6.2f %% (±%.2f %s)\n', 100*dAInit/dSum, dXPM, sXUnit);
        fprintf('Fraction above initial: %6.2f %%\n', 100*dMInit/dSum);
        fprintf('\n');

        fprintf('    From    |     To     |  Fraction\n');
        fprintf('––––––––––––+––––––––––––+–––––––––––\n');
        for j=2:length(aCount)
            fprintf(' %6.1f %s | %6.1f %s | %7.3f %%\n', aCount(j-1), sXUnit, aCount(j), sXUnit, 100*aTCount(j-1)/dSum);
        end % for
        fprintf('\n');
        
    else % For x1, x2 or x3
        
        aXAxis = linspace(dXMin,dXMax,iNX);

    end % if
    

    %
    %  Plotting
    % **********
    %

    fig1 = figure(1);
    clf;
    
    area(aXAxis, dSign*h5Data, 'FaceColor', 'blue', 'EdgeColor', 'blue');
    
    %xlim([dXMin, dXMax]);
    %ylim([dYMin, dYMax*1.05]);

    %sSpecies = strrep(sSpecies, '_', ' ');
    %sSpecies = regexprep(sSpecies,'(\<[a-z])','${upper($1)}');
    %title(sprintf('1D Phase Plot for %s for %s',sSpecies,sAxis),'FontSize',16);
    %xlabel(sXLabel,'interpreter','LaTex','FontSize',14);
    %ylabel('$R/\sum R$','interpreter','LaTex','FontSize',14);


end

