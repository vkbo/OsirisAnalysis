
%
%  GUI :: Analyse Beamlets
% *************************
%

function AnalyseBeamlets(oData, iFig)

    % Input
    sBeam = 'EB';
    sTime = 'PStart';
    
    sBeam = fTranslateSpecies(sBeam);
    iTime = fStringToDump(oData, num2str(sTime));

    % Figure
    fMain = figure(iFig); clf;
    aFPos = get(fMain, 'Position');
    
    % Set figure properties
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'Position', [aFPos(1:2) 900 900]);
    set(fMain, 'Name', 'Osiris Beamlet Analysis');
    
    % Data class
    oCH      = Charge(oData, sBeam, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    oCH.Time = iTime;
    stData   = oCH.Beamlets;
    

    %  Controls
    % **********
    
    % Axes
    axDens = axes('Units','Pixels','Position',[ 60 600 600 250]);
    axPrjX = axes('Units','Pixels','Position',[ 60 300 350 250]);
    axPrjY = axes('Units','Pixels','Position',[500 300 350 250]);
    
    fRefreshPlots(1);
    
    
    % Plot

    function fRefreshPlots(iBeamlet)

        % Define colours
        cDistCol  = [0.4 0.6 0.4];
        cPeakCol  = [0.6 0.4 0.4];
        cGaussCol = [0.4 0.4 0.6];

        % Get values
        aSpan    = stData.Span;
        aX1Axis  = stData.X1Axis(aSpan(1,iBeamlet):aSpan(2,iBeamlet));
        aX2Axis  = stData.X2Axis;

        dX1Start = stData.Beamlets(iBeamlet).X1Start;
        dX1Stop  = stData.Beamlets(iBeamlet).X1Stop;
        aX1Proj  = stData.Beamlets(iBeamlet).X1Proj;
        aX1Peak  = stData.Beamlets(iBeamlet).X1Peak;
        aX1FWHM  = stData.Beamlets(iBeamlet).X1FWHM;
        dX1Mean  = stData.Beamlets(iBeamlet).X1Mean;
        dX1Std   = stData.Beamlets(iBeamlet).X1Std;

        dX2Start = stData.Beamlets(iBeamlet).X2Start;
        dX2Stop  = stData.Beamlets(iBeamlet).X2Stop;
        aX2Proj  = stData.Beamlets(iBeamlet).X2Proj;
        aX2Peak  = stData.Beamlets(iBeamlet).X2Peak;
        aX2FWHM  = stData.Beamlets(iBeamlet).X2FWHM;
        dX2Mean  = stData.Beamlets(iBeamlet).X2Mean;
        dX2Std   = stData.Beamlets(iBeamlet).X2Std;


        %  X1 Projection
        % ***************
        
        % Curve fitting
        stReturn  = fAutoGaussian(aX1Axis, aX1Proj, 2);
        [~,iMain] = max(stReturn.Amp);
        dGMean    = stReturn.Mean(iMain);
        dGSigma   = stReturn.Sigma(iMain);

        % Line values
        dHalfMax  = max(aX1Proj)/2;
        aEndLine  = 0.08*[-dHalfMax dHalfMax];

        % Plot
        set(fMain,'CurrentAxes',axPrjX);
        plot(aX1Axis, aX1Proj);
        hold on;
        plot(aX1Axis, stReturn.Fit, 'r--');
        hold off;
        
        dOffset = dHalfMax;
        line([aX1Peak aX1Peak],      aEndLine+dOffset, 'Color',cPeakCol);
        line([aX1FWHM(1) aX1FWHM(2)],[dOffset dOffset],'Color',cPeakCol);
        line([aX1FWHM(1) aX1FWHM(1)],aEndLine+dOffset, 'Color',cPeakCol);
        line([aX1FWHM(2) aX1FWHM(2)],aEndLine+dOffset, 'Color',cPeakCol);
 
        dOffset = 0.8*dHalfMax;
        line([dX1Mean dX1Mean],              aEndLine+dOffset, 'Color',cDistCol);
        line([dX1Mean-dX1Std dX1Mean+dX1Std],[dOffset dOffset],'Color',cDistCol);
        line([dX1Mean-dX1Std dX1Mean-dX1Std],aEndLine+dOffset, 'Color',cDistCol);
        line([dX1Mean+dX1Std dX1Mean+dX1Std],aEndLine+dOffset, 'Color',cDistCol);

        dOffset = 1.2*dHalfMax;
        line([dGMean dGMean],                aEndLine+dOffset, 'Color',cGaussCol);
        line([dGMean-dGSigma dGMean+dGSigma],[dOffset dOffset],'Color',cGaussCol);
        line([dGMean-dGSigma dGMean-dGSigma],aEndLine+dOffset, 'Color',cGaussCol);
        line([dGMean+dGSigma dGMean+dGSigma],aEndLine+dOffset, 'Color',cGaussCol);

        xlim([aX1Axis(1) aX1Axis(end)]);
        

        %  X2 Projection
        % ***************

        % Curve fitting
        stReturn  = fAutoGaussian(aX2Axis, aX2Proj, 2);
        [~,iMain] = max(stReturn.Amp);
        dGMean    = stReturn.Mean(iMain);
        dGSigma   = stReturn.Sigma(iMain);

        % Line values
        dHalfMax  = max(aX1Proj)/2;
        aEndLine  = 0.08*[-dHalfMax dHalfMax];

        % Plot
        set(fMain,'CurrentAxes',axPrjY);
        plot(aX2Axis, aX2Proj);
        hold on;
        plot(aX2Axis, stReturn.Fit, 'r--');
        hold off;

        dOffset = dHalfMax;
        line([aX2Peak aX2Peak],      aEndLine+dOffset, 'Color',cPeakCol);
        line([aX2FWHM(1) aX2FWHM(2)],[dOffset dOffset],'Color',cPeakCol);
        line([aX2FWHM(1) aX2FWHM(1)],aEndLine+dOffset, 'Color',cPeakCol);
        line([aX2FWHM(2) aX2FWHM(2)],aEndLine+dOffset, 'Color',cPeakCol);
 
        dOffset = 0.8*dHalfMax;
        line([dX2Mean dX2Mean],              aEndLine+dOffset, 'Color',cDistCol);
        line([dX2Mean-dX2Std dX2Mean+dX2Std],[dOffset dOffset],'Color',cDistCol);
        line([dX2Mean-dX2Std dX2Mean-dX2Std],aEndLine+dOffset, 'Color',cDistCol);
        line([dX2Mean+dX2Std dX2Mean+dX2Std],aEndLine+dOffset, 'Color',cDistCol);

        dOffset = 1.2*dHalfMax;
        line([dGMean dGMean],                aEndLine+dOffset, 'Color',cGaussCol);
        line([dGMean-dGSigma dGMean+dGSigma],[dOffset dOffset],'Color',cGaussCol);
        line([dGMean-dGSigma dGMean-dGSigma],aEndLine+dOffset, 'Color',cGaussCol);
        line([dGMean+dGSigma dGMean+dGSigma],aEndLine+dOffset, 'Color',cGaussCol);

        xlim(3*aX2FWHM);


        %  Density Plot
        % **************
        
        % Calculate limits
        dWidth  = dX1Stop-dX1Start;
        dHeight = 3*(aX2FWHM(2) - aX2FWHM(1));
        aLimits = [dX1Start-dWidth dX1Stop+dWidth 5*aX2FWHM];

        % Plot
        set(fMain,'CurrentAxes',axDens);
        fPlotBeamDensity(oData,iTime,sBeam,'IsSubPlot','Yes','Absolute','Yes','ShowOverlay','No','HideDump','Yes','Limits',aLimits);
        set(axDens,'FontSize',9);
        rectangle('Position',[dX1Start -0.5*dHeight dWidth dHeight],'EdgeColor',[1.0 1.0 1.0],'LineStyle','--');

    end % function

    
end % function
