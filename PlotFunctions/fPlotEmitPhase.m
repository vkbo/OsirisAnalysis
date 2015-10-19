
%
%  Function: fPlotEmitPhase
% **************************
%  Plots a X X' phasespace from OsirisData
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Time dump
%  sSpecies :: Which species to look at
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  Axis        :: Lin or log
%  CAxis       :: Color axis limits
%  Sample      :: Samples per macro particle. Default is 1
%  Grid        :: Histogram grid size. Defailt is 400x400
%

function stReturn = fPlotEmitPhase(oData, sTime, sSpecies, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotEmitPhase\n');
        fprintf(' **************************\n');
        fprintf('  Plots a X X'' phasespace from OsirisData\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sTime    :: Time dump\n');
        fprintf('  sSpecies :: Which species to look at\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Limits      :: Axis limits\n');
        fprintf('  FigureSize  :: Default [900 500]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  Axis        :: Lin or log\n');
        fprintf('  CAxis       :: Color axis limits\n');
        fprintf('  Sample      :: Samples per macro particle. Default is 1\n');
        fprintf('  Grid        :: Histogram grid size. Defailt is 400x400\n');
        fprintf('\n');
        return;
    end % if

    sSpecies = fTranslateSpecies(sSpecies);
    iTime    = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'Axis',        'Log');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'Sample',      1);
    addParameter(oOpt, 'Grid',        [400 400]);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if
    
    % Prepare Data
    
    oM = Momentum(oData,sSpecies,'Units','SI','X1Scale','mm','X2Scale','mm');
    oM.Time = iTime;
    stData = oM.Emittance('Sample',stOpt.Sample,'Histogram','Yes','Grid',stOpt.Grid);
    
    if strcmpi(stOpt.Axis, 'Log')
        aData = log10(stData.Hist);
        sUnit = 'log(Q) [nC]';
    else
        aData = stData.Hist;
        sUnit = 'Q [nC]';
    end % if

    stReturn.X1Axis    = stData.X1Axis;
    stReturn.X2Axis    = stData.X2Axis;
    %stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oM.AxisFac;
    stReturn.AxisRange = oM.AxisRange;
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Field Density (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if

    imagesc(stData.X1Axis, stData.X2Axis, aData);
    set(gca,'YDir','Normal');
    colormap('hot');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('XX'' Phase Space %s (%s #%d)', fPlasmaPosition(oData, iTime), oData.Config.Name, iTime);
    else
        sTitle = sprintf('XX'' Phase Space %s', fPlasmaPosition(oData, iTime));
    end % if

    title(sTitle);
    xlabel(sprintf('x [%s]',stData.XUnit));
    ylabel(sprintf('x'' [%s]',stData.XPrimeUnit));
    title(hCol,sUnit);
    
    % Return

    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;

end

