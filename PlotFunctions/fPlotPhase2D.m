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
%  Optional Inputs:
% ==================
%  sCAxis   :: Scale of CAxis: 'lin' or 'log'
%

function fPlotPhase2D(oData, iTime, sSpecies, sAxis1, sAxis2, sCAxis)

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
        fprintf('  Optional Inputs:\n');
        fprintf(' ==================\n');
        fprintf('  sCAxis   :: Scale of CAxis: ''lin'' or ''log''\n');
        fprintf('\n');
        return;
    end % if
    
    if nargin < 6
        sCAxis = 'lin';
    end % if
    
    sSpecies = fTranslateSpecies(sSpecies);
    aAllowed = {'p1','p2','p3','x1','x2','x3'};
    if ~ismember(sAxis1, aAllowed) || ~ismember(sAxis2, aAllowed)
        fprintf('Error: Unknown axes\n');
        return;
    end % if
    sAxis = sprintf('%s%s', sAxis1, sAxis2);


    %
    %  Extracting Simulation Data
    % ****************************
    %

    % Beam diag
    iNX1   = oData.Config.Variables.Beam.(sSpecies).DiagNX1;
    iNX2   = oData.Config.Variables.Beam.(sSpecies).DiagNX2;
    iNX3   = oData.Config.Variables.Beam.(sSpecies).DiagNX3;
    iNP1   = oData.Config.Variables.Beam.(sSpecies).DiagNP1;
    iNP2   = oData.Config.Variables.Beam.(sSpecies).DiagNP2;
    iNP3   = oData.Config.Variables.Beam.(sSpecies).DiagNP3;

    dX1Min = oData.Config.Variables.Beam.(sSpecies).DiagX1Min;
    dX2Min = oData.Config.Variables.Beam.(sSpecies).DiagX2Min;
    dX3Min = oData.Config.Variables.Beam.(sSpecies).DiagX3Min;
    dP1Min = oData.Config.Variables.Beam.(sSpecies).DiagP1Min;
    dP2Min = oData.Config.Variables.Beam.(sSpecies).DiagP2Min;
    dP3Min = oData.Config.Variables.Beam.(sSpecies).DiagP3Min;

    dX1Max = oData.Config.Variables.Beam.(sSpecies).DiagX1Max;
    dX2Max = oData.Config.Variables.Beam.(sSpecies).DiagX2Max;
    dX3Max = oData.Config.Variables.Beam.(sSpecies).DiagX3Max;
    dP1Max = oData.Config.Variables.Beam.(sSpecies).DiagP1Max;
    dP2Max = oData.Config.Variables.Beam.(sSpecies).DiagP2Max;
    dP3Max = oData.Config.Variables.Beam.(sSpecies).DiagP3Max;
    
    % Beam
    dRQM   = oData.Config.Variables.Beam.(sSpecies).RQM;
    dEMass = oData.Config.Variables.Constants.ElectronMassMeV;
    
    % Factors
    dLFac  = oData.Config.Variables.Convert.SI.LengthFac;
    dTFac  = oData.Config.Variables.Convert.SI.TimeFac;
    dPFac  = abs(dRQM)*dEMass;
    dSign  = dRQM/abs(dRQM);
    
    % Plasma
    dPS    = oData.Config.Variables.Plasma.PlasmaStart;
    dPE    = oData.Config.Variables.Plasma.PlasmaEnd;
    dTime  = iTime*dTFac;
    dS     = dTime*dLFac;
    dSP    = (dTime-dPS)*dLFac;

    
    %
    %  Axis Conditions
    % *****************
    %

    switch(sAxis1)
        case 'p1'
            if abs(dRQM) < 1000.0
                sXUnit  = 'MeV';
                sXLabel = '$p_z \mbox{[MeV/c]}$';
                dXScale = 1.0;
            else
                sXUnit  = 'GeV';
                sXLabel = '$p_z \mbox{[GeV/c]}$';
                dXScale = 1.0e-3;
            end % if
        case 'p2'
            if abs(dRQM) < 1000.0
                sXUnit  = 'keV';
                sXLabel = '$p_r \mbox{[keV/c]}$';
                dXScale = 1.0e3;
            else
                sXUnit  = 'MeV';
                sXLabel = '$p_r \mbox{[MeV/c]}$';
                dXScale = 1.0;
            end % if
        case 'p3'
            if abs(dRQM) < 1000.0
                sXUnit  = 'keV';
                sXLabel = '$p_{\theta} \mbox{[MeV/c]}$';
                dXScale = 1.0e3;
            else
                sXUnit  = 'MeV';
                sXLabel = '$p_{\theta} \mbox{[MeV/c]}$';
                dXScale = 1.0;
            end % if
        case 'x1'
            sXUnit  = 'mm';
            sXLabel = '$z \mbox{[mm]}$';
            dXScale = 1.0e3;
        case 'x2'
            sXUnit  = 'mm';
            sXLabel = '$r \mbox{[mm]}$';
            dXScale = 1.0e3;
        case 'x3'
            sXUnit  = 'mm';
            sXLabel = '$\theta$';
            dXScale = 1.0e3;
    end % switch

    switch(sAxis2)
        case 'p1'
            if abs(dRQM) < 1000.0
                sYUnit  = 'MeV';
                sYLabel = '$p_z \mbox{[MeV/c]}$';
                dYScale = 1.0;
            else
                sYUnit  = 'GeV';
                sYLabel = '$p_z \mbox{[GeV/c]}$';
                dYScale = 1.0e-3;
            end % if
        case 'p2'
            if abs(dRQM) < 1000.0
                sYUnit  = 'keV';
                sYLabel = '$p_r \mbox{[keV/c]}$';
                dYScale = 1.0e3;
            else
                sYUnit  = 'MeV';
                sYLabel = '$p_r \mbox{[MeV/c]}$';
                dYScale = 1.0;
            end % if
        case 'p3'
            if abs(dRQM) < 1000.0
                sYUnit  = 'keV';
                sYLabel = '$p_{\theta} \mbox{[MeV/c]}$';
                dYScale = 1.0e3;
            else
                sYUnit  = 'MeV';
                sYLabel = '$p_{\theta} \mbox{[MeV/c]}$';
                dYScale = 1.0;
            end % if
        case 'x1'
            sYUnit  = 'mm';
            sYLabel = '$z \mbox{[mm]}$';
            dYScale = 1.0e3;
        case 'x2'
            sYUnit  = 'mm';
            sYLabel = '$r \mbox{[mm]}$';
            dYScale = 1.0e3;
        case 'x3'
            sYUnit  = 'mm';
            sYLabel = '$\theta$';
            dYScale = 1.0e3;
    end % switch

    switch(sAxis1)
        case 'x1'
            dXMin  = dX1Min;
            dXMax  = dX1Max;
            iNX    = iNX1;
        case 'x2'
            dXMin  = dX2Min;
            dXMax  = dX2Max;
            iNX    = iNX2;
        case 'x3'
            dXMin  = dX3Min;
            dXMax  = dX3Max;
            iNX    = iNX3;
        otherwise
            return;
    end % switch

    switch(sAxis2)
        case 'p1'
            dYMin  = dP1Min;
            dYMax  = dP1Max;
            iNY    = iNP1;
        case 'p2'
            dYMin  = dP2Min;
            dYMax  = dP2Max;
            iNY    = iNP2;
        case 'p3'
            dYMin  = dP3Min;
            dYMax  = dP3Max;
            iNY    = iNP3;
        otherwise
            return;
    end % switch
    
    aMomenta = {'p1','p2','p3'};
    if ismember(sAxis1, aMomenta)
        if abs(dXMin) > 0.0
            dXMin = sqrt(abs(dXMin)^2 + 1)*dPFac*(dXMin/abs(dXMin))*dXScale;
        end % if
        if abs(dXMax) > 0.0
            dXMax = sqrt(abs(dXMax)^2 + 1)*dPFac*(dXMax/abs(dXMax))*dXScale;
        end % if
    end % if
    if ismember(sAxis2, aMomenta)
        if abs(dYMin) > 0.0
            dYMin = sqrt(abs(dYMin)^2 + 1)*dPFac*(dYMin/abs(dYMin))*dYScale;
        end % if
        if abs(dYMax) > 0.0
            dYMax = sqrt(abs(dYMax)^2 + 1)*dPFac*(dYMax/abs(dYMax))*dYScale;
        end % if
    end % if

    aSpace = {'x1','x2','x3'};
    if ismember(sAxis1, aSpace)
        if abs(dXMin) > 0.0
            dXMin = dXMin*dLFac*dXScale;
        end % if
        if abs(dXMax) > 0.0
            dXMax = dXMax*dLFac*dXScale;
        end % if
    end % if
    if ismember(sAxis2, aSpace)
        if abs(dYMin) > 0.0
            dYMin = dYMin*dLFac*dYScale;
        end % if
        if abs(dYMax) > 0.0
            dYMax = dYMax*dLFac*dYScale;
        end % if
    end % if

    aXAxis = linspace(dXMin,dXMax,iNX);
    aYAxis = linspace(dYMin,dYMax,iNY);


    %
    %  Data Processing
    % *****************
    %

    h5Data = oData.Data(iTime, 'PHA', sAxis, sSpecies);
    dSum   = sum(h5Data(:));
    h5Data = h5Data/dSum;
    if strcmpi(sCAxis, 'log')
        h5Data = real(log10(h5Data));
    end % if

    
    %
    %  Plot
    % ******
    %
    
    imagesc(aXAxis, aYAxis, h5Data);
    %colorbar;
    set(gca,'YDir','Normal');

    sTitle = sprintf('2D Phase Plot for %s after %.2f m of Plasma', sAxis, dSP);
    title(sTitle,'FontSize',16);
    xlabel(sXLabel,'interpreter','LaTex','FontSize',14);
    ylabel(sYLabel,'interpreter','LaTex','FontSize',14);

end
