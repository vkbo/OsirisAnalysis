
%
%  Function: fPlotRawTime
% ************************
%  Plots Raw Data Time Evolution
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sSpecies :: Which species to look at
%
%  Options:
% ==========
%  Lim        :: Axis limts. Must be 4 columns and either
%                1 row or End-Start+1. Default empty
%  Start      :: Default first dump
%  End        :: Default last dump
%  Value      :: What raw variable to plot. Default charge
%  Method     :: What method to use: sum, mean, min or max. Default sum
%  FigureSize :: Default [750 450]
%  HideDump   :: Default No
%  IsSubplot  :: Default No
%  AutoResize :: Default On
%

function stReturn = fPlotRawTime(oData, sSpecies, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotRawTime\n');
        fprintf(' **********************\n');
        fprintf('  Plots Raw Data Time Evolution\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sSpecies :: Which species to look at\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Lim        :: Axis limts. Must be 4 columns and either\n');
        fprintf('                1 row or End-Start+1. Default empty\n');
        fprintf('  Start      :: Default first dump\n');
        fprintf('  End        :: Default last dump\n');
        fprintf('  Value      :: What raw variable to plot. Default charge\n');
        fprintf('  Method     :: What method to use: sum, mean, min or max. Default sum\n');
        fprintf('  FigureSize :: Default [750 450]\n');
        fprintf('  HideDump   :: Default No\n');
        fprintf('  IsSubplot  :: Default No\n');
        fprintf('  AutoResize :: Default On\n');
        fprintf('\n');
        return;
    end % if
    
    vSpecies = oData.Translate.Lookup(sSpecies,'Species');

    oOpt = inputParser;
    addParameter(oOpt, 'Lim',        []);
    addParameter(oOpt, 'Start',      'Start');
    addParameter(oOpt, 'End',        'End');
    addParameter(oOpt, 'Value',      'Charge');
    addParameter(oOpt, 'Method',     'Sum');
    addParameter(oOpt, 'Style',      'Shaded');
    addParameter(oOpt, 'Fit',        'fourier8');
    addParameter(oOpt, 'FigureSize', [750 450]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;
    
    iStart  = oData.StringToDump(stOpt.Start);
    iEnd    = oData.StringToDump(stOpt.End);
    iDumps  = iEnd-iStart+1;
    vValue  = oData.Translate.Lookup(stOpt.Value);
    sMethod = capitalise(stOpt.Method);

    if ~isempty(stOpt.Lim)
        if size(stOpt.Lim,2) ~= 4
            fprintf(2, 'Error: Lim specified, but must have 4 columns.\n');
            return;
        end % if
        if ~(size(stOpt.Lim,1) == 1 || size(stOpt.Lim,1) == iDumps)
            fprintf(2, 'Error: Lim specified, but must have 1 or End-Start+1 rows.\n');
            return;
        end % if
    end % if
    iLims = size(stOpt.Lim,1);

    % Data
    oDN    = Density(oData,vSpecies.Name,'Units','SI','X1Scale','mm','X2Scale','mm');
    stData = oDN.EvolveRaw('Start',iStart,'End',iEnd,'Value',vValue.Name,'Method',sMethod);
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        stReturn.Error = 'No data';
        return;
    end % if

    aData  = stData.Data;
    aAxis  = stData.Axis;
    aSigma = stData.Sigma;

    dMax = max(abs(aData));
    [dVal,sUnit] = fAutoScale(dMax,stData.Unit);
    dScale = dVal/dMax;
    aData  = aData*dScale;

    %stReturn.AxisRange = stData.AxisRange;
    %stReturn.AxisScale = stData.AxisScale*dAScale;
    stReturn.Error = '';
    
    switch(sMethod)
        case 'Sum'
            sAxis = sprintf('\\Sigma(%s)',vValue.Tex);
        case 'Mean'
            sAxis = sprintf('\\langle %s \\rangle',vValue.Tex);
        case 'Min'
            sAxis = sprintf('min(%s)',vValue.Tex);
        case 'Max'
            sAxis = sprintf('max(%s)',vValue.Tex);
    end % switch
    

    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Raw Time Evolution (%s)',oData.Config.Name))
    else
        cla;
    end % if

    if strcmpi(stOpt.Style, 'Stairs')
        stairs(aAxis, aData, 'Color', [0.0 0.0 0.6], 'LineWidth', 1.5);
    elseif strcmpi(stOpt.Style, 'Fitted')
        plot(aAxis, aData, '+', 'Color', [0.0 0.0 0.6]);

        oFit = fit(double(aAxis)',double(aData)',stOpt.Fit);
        aFAx = linspace(aAxis(1),aAxis(end),iDumps*4);
        aFit = feval(oFit,aFAx);

        hold on;
        plot(aFAx, aFit, 'Color', [0.6 0.0 0.0]);
        hold off;
    else
        shadedErrorBar(aAxis, aData, aSigma*dScale, {'-b', 'LineWidth', 1.5});
    end % if

    if aAxis(end) > aAxis(1)
        xlim([aAxis(1) aAxis(end)]);
    end % if


    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s %s (%s)',vSpecies.Full,sMethod,vValue.Full,oData.Config.Name);
    else
        sTitle = sprintf('%s %s %s',vSpecies.Full,sMethod,vValue.Full);
    end % if

    title(sTitle);
    xlabel('z [m]');
    ylabel(sprintf('%s [%s]',sAxis,sUnit));
    

    % Return

    stReturn.Species = vSpecies.Name;
    stReturn.Value   = vValue.Name;
    stReturn.XLim    = xlim;
    stReturn.YLim    = ylim;

end % function
