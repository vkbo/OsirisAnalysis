
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
    addParameter(oOpt, 'StatInfo',   'Yes');
    addParameter(oOpt, 'FigureSize', [900 500]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Lim) && length(stOpt.Lim) ~= 2
        fprintf(2, 'Error: Lim specified, but must be of dimension 2.\n');
        return;
    end % if

    % Data
    oPha      = Phase(oData,vSpecies.Name,'Units','SI');
    oPha.Time = iTime;
    stData    = oPha.RawHist1D(sAxis,'Grid',stOpt.Grid,'Lim',stOpt.Lim,'Method',stOpt.Method);
    
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

    stReturn.AxisRange = stData.AxisRange;
    stReturn.AxisScale = stData.AxisScale*dAScale;
    stReturn.Error     = '';
    

    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Raw Data 1D (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if
    
    stairs(aAxis, aData, 'Color', [0.0 0.0 0.6], 'LineWidth', 1.5);

    dYMax = max(aData);
    if dYMax > 0
        ylim([0 dYMax*1.1]);
    end % if
    if aAxis(end) > aAxis(1)
        xlim([aAxis(1) aAxis(end)]);
    end % if
    
    % Curve Fitting
    if strcmpi(stOpt.GaussFit,'Yes')
    
        try
            oFit   = fit(double(aAxis)',double(aData)','Gauss1','StartPoint',rand(1,3));
            aFit   = feval(oFit,aAxis);
            dAmp   = oFit.a1;
            dMu    = oFit.b1;
            dSigma = oFit.c1/sqrt(2);

            [dSSigma,sSUnit] = fAutoScale(dSigma/dAScale,stData.AxisUnit);

            hold on;
            plot(aAxis, aFit, 'Color', 'Red');

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
            stReturn.Error = 'Curve fitting failed';
        end % try
        
    end % if

    % Statistical Info
    if strcmpi(stOpt.StatInfo,'Yes')
        
        dMean = stData.Mean*dAScale;
        dStd  = stData.Std*dAScale;
        dMax  = max(aData);
        
        [dMVal,sMUnit] = fAutoScale(stData.Mean,stData.AxisUnit);
        [dSVal,sSUnit] = fAutoScale(stData.Std, stData.AxisUnit);

        hold on;
        
        sMean = sprintf('Mean: %.2f %s',dMVal,sMUnit);
        sStd  = sprintf('Std: %.2f %s',dSVal,sSUnit);

        dX = interp1([0 1], xlim(), 0.02);
        dY = interp1([0 1], ylim(), 0.95);

        text(dX,dY,sMean);
        text(dX,0.95*dY,sStd);
        
        hold off;
        
    end % if
    
    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s %s (%s #%d)',vSpecies.Full,vAxis.Full,oPha.PlasmaPosition,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s %s %s',vSpecies.Full,vAxis.Full,oPha.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('%s [%s]',vAxis.Tex,sAUnit));
    ylabel('Ratio [%]');
    

    % Return

    stReturn.Species = vSpecies.Name;
    stReturn.Axis    = vAxis.Name;
    stReturn.XLim    = xlim;
    stReturn.YLim    = ylim;

end % function
