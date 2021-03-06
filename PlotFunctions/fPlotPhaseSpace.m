
%
%  Function: fPlotPhaseSpace
% ***************************
%  Plots a X X' phase space from OsirisData
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Time dump
%  sSpecies :: Which species to look at
%
%  Options:
% ==========
%  Limits       :: Axis limits
%  FigureSize   :: Default [900 500]
%  HideDump     :: Default No
%  IsSubplot    :: Default No
%  AutoResize   :: Default On
%  Axis         :: Lin or log
%  CAxis        :: Color axis limits
%  Sample       :: Samples per macro particle. Default is 1
%  MinParticles :: Minimum number of particles to sample
%                  (This option may modify "Sample")
%  Grid         :: Histogram grid size. Defailt is 400x400
%

function stReturn = fPlotPhaseSpace(oData, sTime, sSpecies, varargin)

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
        fprintf('  Limits       :: Axis limits\n');
        fprintf('  FigureSize   :: Default [900 500]\n');
        fprintf('  HideDump     :: Default No\n');
        fprintf('  IsSubplot    :: Default No\n');
        fprintf('  AutoResize   :: Default On\n');
        fprintf('  Axis         :: Lin or log\n');
        fprintf('  CAxis        :: Color axis limits\n');
        fprintf('  Sample       :: Samples per macro particle. Default is 1\n');
        fprintf('  MinParticles :: Minimum number of particles to sample\n');
        fprintf('                  (This option may modify "Sample")\n');
        fprintf('  Grid         :: Histogram grid size. Defailt is 400x400\n');
        fprintf('\n');
        return;
    end % if

    vSpecies = oData.Translate.Lookup(sSpecies,'Species');
    iTime    = oData.StringToDump(num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',       []);
    addParameter(oOpt, 'FigureSize',   [900 500]);
    addParameter(oOpt, 'HideDump',     'No');
    addParameter(oOpt, 'IsSubPlot',    'No');
    addParameter(oOpt, 'AutoResize',   'On');
    addParameter(oOpt, 'Axis',         '');
    addParameter(oOpt, 'CAxis',        []);
    addParameter(oOpt, 'Sample',       1);
    addParameter(oOpt, 'MinParticles', 100000);
    addParameter(oOpt, 'Grid',         [400 400]);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if
    
    % Prepare Data
    oM = Momentum(oData,vSpecies.Name,'Units','SI','Scale','mm');
    oM.Time = iTime;
    stData = oM.PhaseSpace('Sample',stOpt.Sample, ...
                           'MinParticles',stOpt.MinParticles, ...
                           'Histogram','Yes','Grid',stOpt.Grid);
    
    if strcmpi(stOpt.Axis, 'Log')
        aData = log10(stData.Hist);
        sUnit = 'log(Q) [nC]';
    else
        aData = stData.Hist;
        sUnit = 'Q [nC]';
    end % if
    
    aX1Axis = stData.HAxis;
    aX2Axis = stData.VAxis;

    stReturn.HAxis     = aX1Axis;
    stReturn.VAxis     = aX2Axis;
    %stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oM.AxisFac;
    stReturn.AxisRange = [aX1Axis(1) aX1Axis(end) aX2Axis(1) aX2Axis(end) 0.0 0.0];
    stReturn.Count     = stData.Count;
    stReturn.ERMS      = stData.ERMS;

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

    imagesc(aX1Axis, aX2Axis, aData);
    set(gca,'YDir','Normal');
    colormap('hot');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if
    
    hold on;
    
    plot(0,0,'LineStyle','None');
    plot(0,0,'LineStyle','None');
    
    cLegend{1} = sprintf('ε_{g} = %.3f µm',stData.ERMS);
    cLegend{2} = sprintf('ε_{N} = %.3f µm',stData.ENorm);
    
    hold off;
    
    hL = legend(cLegend,'Location','NE');
    set(hL,'Box','Off');
    set(hL,'TextColor', 'White');

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('XX'' Phase Space %s (%s #%d)', oM.PlasmaPosition, oData.Config.Name, iTime);
    else
        sTitle = sprintf('XX'' Phase Space %s', oM.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('x [%s]',stData.XUnit));
    ylabel(sprintf('x'' [%s]',stData.XPrimeUnit));
    title(hCol,sUnit);
    
    % Return

    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;
    
    %figure(30);
    %plot(aX1Axis, stData.Hist(200,:));
    %figure(31);
    %plot(aX2Axis, stData.Hist(:,201));

end % function
