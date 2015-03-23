
%
%  GUI :: Analyse Beamlets
% *************************
%

function AnalyseBeamlets(oData, sTime, sBeam)

    % Input
    sBeam = fTranslateSpecies(sBeam);
    iTime = fStringToDump(oData, num2str(sTime));

    % Figure
    fMain = gcf; clf;
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

        % Get values
        aSpan    = stData.Span;
        aX1Axis  = stData.X1Axis(aSpan(1,iBeamlet):aSpan(2,iBeamlet));
        aX2Axis  = stData.X2Axis;

        dX1Start = stData.Beamlets(iBeamlet).X1Start;
        dX1Stop  = stData.Beamlets(iBeamlet).X1Stop;
        aX1Proj  = stData.Beamlets(iBeamlet).X1Proj;
        aX2Proj  = stData.Beamlets(iBeamlet).X2Proj;
        dMeanX1  = stData.Beamlets(iBeamlet).X1Mean;
        dStdX1   = stData.Beamlets(iBeamlet).X1Std;
        dMeanX2  = stData.Beamlets(iBeamlet).X2Mean;
        dStdX2   = stData.Beamlets(iBeamlet).X2Std;


        %  X1 Projection
        % ***************
        
        % Curve fitting with Gaussian 2
        oFitX1 = fit(aX1Axis.',aX1Proj.','gauss2');
        aCfX1  = coeffvalues(oFitX1);
        dAmX1a = aCfX1(1);
        dMuX1a = aCfX1(2);
        dSiX1a = aCfX1(3)/sqrt(2);
        dAmX1b = aCfX1(4);
        dMuX1b = aCfX1(5);
        dSiX1b = aCfX1(6)/sqrt(2);

        % Generate fit curve
        aX1Fit = dAmX1a*exp(-(aX1Axis-dMuX1a).^2./(2*dSiX1a^2)) + dAmX1b*exp(-(aX1Axis-dMuX1b).^2./(2*dSiX1b^2));

        % Plot
        set(fMain,'CurrentAxes',axPrjX);
        plot(aX1Axis, aX1Proj);
        hold on;
        plot(aX1Axis, aX1Fit, 'r--');
        hold off;
        
        xlim([aX1Axis(1) aX1Axis(end)]);
        

        %  X2 Projection
        % ***************

        % Curve fitting with Gaussian
        oFitX2 = fit(aX2Axis.',aX2Proj.','gauss2');
        aCfX2  = coeffvalues(oFitX2);
        dAmX2a = aCfX2(1);
        dMuX2a = aCfX2(2);
        dSiX2a = aCfX2(3)/sqrt(2)
        dAmX2b = aCfX2(4);
        dMuX2b = aCfX2(5);
        dSiX2b = aCfX2(6)/sqrt(2)
        
        % Generate fit curve
        aX2Fit = dAmX2a*exp(-(aX2Axis-dMuX2a).^2./(2*dSiX2a^2)) + dAmX2b*exp(-(aX2Axis-dMuX2b).^2./(2*dSiX2b^2));

        % Plot
        set(fMain,'CurrentAxes',axPrjY);
        plot(aX2Axis, aX2Proj);
        hold on;
        plot(aX2Axis, aX2Fit, 'r--');
        hold off;
        xlim([-5*(dSiX2a+dSiX2b) 5*(dSiX2a+dSiX2b)]);


        %  Density Plot
        % **************
        
        % Calculate limits
        dWidth  = dX1Stop-dX1Start;
        dHeight = 10*(dSiX2a+dSiX2b);
        aLimits = [dX1Start-dWidth dX1Stop+dWidth -dHeight dHeight];

        % Plot
        set(fMain,'CurrentAxes',axDens);
        fPlotBeamDensity(oData,iTime,sBeam,'IsSubPlot','Yes','Absolute','Yes','ShowOverlay','No','HideDump','Yes','Limits',aLimits);
        set(axDens,'FontSize',9);
        rectangle('Position',[dX1Start -0.5*dHeight dWidth dHeight],'EdgeColor',[1.0 1.0 1.0],'LineStyle','--');

    end % function
    
end % function
