
%
%  Function: fPlotRaw1D
% **********************
%  Plots 1D Raw Data
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Which dump to look at
%  sSpecies :: Which species to look at
%  sAxis    :: Which axis to plot
%
%  Options:
% ==========
%  Lim         :: Horizontal axis limits
%  Method      :: Weighted deposit ob grid, or use bins. Default Deposit
%  Grid        :: Grid cells or bins. Default 100
%  GaussFit    :: Default No
%  FitRange    :: Default []
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%

function stReturn = fPlotRaw1D(oData, sTime, sSpecies, sAxis, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotRaw1D\n');
        fprintf(' **********************\n');
        fprintf('  Plots 1D Raw Data\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sTime    :: Which dump to look at\n');
        fprintf('  sSpecies :: Which species to look at\n');
        fprintf('  sAxis    :: Which axis to plot\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Lim         :: Horizontal axis limits\n');
        fprintf('  Method      :: Weighted deposit ob grid, or use bins. Default Deposit\n');
        fprintf('  Grid        :: Grid cells or bins. Default 100\n');
        fprintf('  GaussFit    :: Default No\n');
        fprintf('  FitRange    :: Default []\n');
        fprintf('  FigureSize  :: Default [900 500]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('\n');
        return;
    end % if
    
    vSpecies = oData.Translate.Lookup(sSpecies,'Species');
    iTime    = oData.StringToDump(num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Lim',        []);
    addParameter(oOpt, 'Method',     'Deposit');
    addParameter(oOpt, 'Grid',       100);
    addParameter(oOpt, 'GaussFit',   'No');
    addParameter(oOpt, 'FitRange',   []);
    addParameter(oOpt, 'FixedLim',   []);
    addParameter(oOpt, 'FigureSize', [900 500]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    addParameter(oOpt, 'ForceFig',   0);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Lim) && length(stOpt.Lim) ~= 2
        fprintf(2, 'Error: Lim specified, but must be of dimension 2.\n');
        return;
    end % if

    % Data
    oPha      = Phase(oData,vSpecies.Name,'Units','SI');
    oPha.Time = iTime;
    stData    = oPha.RawHist1D(sAxis,'Grid',stOpt.Grid,'Lim',stOpt.Lim,'Method',stOpt.Method,'FixedLim',stOpt.FixedLim);
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        stReturn.Error = 'No data';
        return;
    end % if

    aData = stData.Data*100;
    aAxis = stData.Axis;
    vAxis = oData.Translate.Lookup(sAxis);

    dAMax = max(abs(aAxis));
    [dAVal,sAUnit] = fAutoScale(dAMax,stData.AxisUnit);
    dAScale = dAVal/dAMax;
    aAxis   = aAxis*dAScale;

    stReturn.Data      = aData;
    stReturn.HAxis     = aAxis;
    stReturn.AxisRange = stData.AxisRange;
    stReturn.AxisScale = stData.AxisScale*dAScale;
    stReturn.Error     = '';

    % Curve Fitting
    if strcmpi(stOpt.GaussFit,'Yes')
        
        if isempty(stOpt.FitRange)
            aFitA = aAxis;
            aFitD = aData;
        else
            iS = fGetIndex(aAxis,stOpt.FitRange(1));
            iE = fGetIndex(aAxis,stOpt.FitRange(2));
            aFitA = aAxis(iS:iE);
            aFitD = aData(iS:iE);
        end % if

        if isempty(stOpt.Lim)
            aFAxis = aAxis;
        else
            aFAxis = stOpt.Lim(1)*dAScale:(aAxis(2)-aAxis(1)):stOpt.Lim(2)*dAScale;
        end % if
    
        try
            [oFit,oGOF] = fit(double(aFitA)',double(aFitD)','Gauss1');
            aFit        = feval(oFit,aFAxis);
            dAmp        = oFit.a1;
            dMu         = oFit.b1;
            dSigma      = oFit.c1/sqrt(2);

            if abs(max(aFit))/abs(min(aFit)) < 2
                fprintf('Warning: Gauss1 failed, trying Gauss2\n');
                [oFit,oGOF] = fit(double(aFitA)',double(aFitD)','Gauss2');
                aFit        = feval(oFit,aFAxis);
                dAmp        = oFit.a2;
                dMu         = oFit.b2;
                dSigma      = oFit.c2/sqrt(2);
            end % if

            [dSSigma,sSUnit] = fAutoScale(dSigma/dAScale,stData.AxisUnit, 1e-6);
            
            stReturn.Fit      = oFit;
            stReturn.Goodness = oGOF;
        catch
            stReturn.Error    = 'Curve fitting failed';
        end % try
        
    end % if
    

    % Plot
    if stOpt.ForceFig > 0
        figure(stOpt.ForceFig);
    end % if
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Raw Data 1D (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if
    
    if stOpt.ForceFig > 0
        figure(stOpt.ForceFig);
    end % if
    stairs(aAxis, aData, 'Color', [0.0 0.0 0.6], 'LineWidth', 1.5);
    
    dYMax = max(aData);
    if dYMax > 0
        ylim([0 dYMax*1.1]);
    end % if
    if aAxis(end) > aAxis(1)
        xlim([aAxis(1) aAxis(end)]);
    end % if
    
    if ~isempty(stOpt.Lim)
        xlim(stOpt.Lim*dAScale);
    end % if
    
    % Curve Fitting
    if strcmpi(stOpt.GaussFit,'Yes')
    
        try
            if stOpt.ForceFig > 0
                figure(stOpt.ForceFig);
            end % if
            hold on;
            plot(aFAxis, aFit, 'Color', 'Red');

            sAmp   = sprintf('\\leftarrow A = %.2f%%',dAmp);
            sMu    = sprintf('\\mu = %.2f %s \\rightarrow',dMu,sAUnit);
            sSigma = sprintf('\\leftarrow \\sigma = %.2f %s',dSSigma,sSUnit);
            
            text(dMu+dSigma*0.4,dAmp,sAmp);
            text(dMu-dSigma*0.4,dAmp,sMu,'HorizontalAlignment','Right');
            text(dMu+dSigma*1.4,dAmp*exp(-0.5),sSigma);

            line([dMu dMu],ylim,'Color',[0.0 0.4 0.0],'LineStyle','--');
            line([dMu-dSigma dMu+dSigma],[1 1]*dAmp*exp(-0.5),'Color',[0.0 0.4 0.0],'LineStyle','-');

            hold off;
        catch
        end % try
        
    end % if

    % Add mean and std info
    dMean = stData.Mean*dAScale;
    dStd  = stData.Std*dAScale;
    dMax  = max(aData);

    [dMVal,sMUnit] = fAutoScale(stData.Mean,stData.AxisUnit,1e-6);
    [dSVal,sSUnit] = fAutoScale(stData.Std, stData.AxisUnit,1e-6);

    hold on;

    sMean = sprintf('Mean: %.2f %s',dMVal,sMUnit);
    sStd  = sprintf('Std: %.2f %s',dSVal,sSUnit);

    aXLim = xlim();
    aYLim = ylim();
    set(gca,'Units','Pixels');
    aSize = get(gca,'Position');
    dDX   = aSize(3)/(aXLim(2)-aXLim(1));
    dDY   = aSize(4)/(aYLim(2)-aYLim(1));
    dX    = aXLim(1)+8/dDX;
    dY1   = aYLim(2)-15/dDY;
    dY2   = aYLim(2)-30/dDY;

    text(dX,dY1,sMean);
    text(dX,dY2,sStd);

    hold off;
    
    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s %s (%s #%d)',vSpecies.Full,vAxis.Full,oPha.PlasmaPosition,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s %s %s',vSpecies.Full,vAxis.Full,oPha.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('%s [%s]',vAxis.Tex,sAUnit));
    ylabel('% Per Bin');
    

    % Return

    stReturn.Species = vSpecies.Name;
    stReturn.Axis    = vAxis.Name;
    stReturn.XLim    = xlim;
    stReturn.YLim    = ylim;

end % function
