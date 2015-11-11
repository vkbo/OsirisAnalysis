
%
%  Function: fPlotParticleTrack
% ******************************
%  Track particles
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sSpecies :: Which species
%  sTrack   :: What axis to track (x1,x2,x3,p1,p2,p3,energy,charge)
%
%  Options:
% ==========
%  Limits      :: Axis limits (x1 and x2)
%  FigureSize  :: Default [750 450]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  Start       :: Default Plasma Start
%  End         :: Default Plasma End
%  Sample      :: Number of particles. Default 10
%  Filter      :: Random, WRandom, W2Random, Top, Bottom
%  Weights     :: Charge, X1, X2, X3, P1, P2, P3, Energy
%

function stReturn = fPlotParticleTrack(oData, sSpecies, sTrack, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotESigmaMean\n');
        fprintf(' ***************************\n');
        fprintf('  Plots the evolution of mean energy of a beam\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sSpecies :: Which species\n');
        fprintf('  sTrack   :: What axis to track (x1,x2,x3,p1,p2,p3,energy,charge)\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Limits      :: Axis limits (x1 and x2)\n');
        fprintf('  FigureSize  :: Default [750 450]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  Start       :: Default Plasma Start\n');
        fprintf('  End         :: Default Plasma End\n');
        fprintf('  Sample      :: Number of particles. Default 10\n');
        fprintf('  Filter      :: Random, WRandom, W2Random, Top, Bottom\n');
        fprintf('  Weights     :: Charge, X1, X2, X3, P1, P2, P3, Energy\n');
        fprintf('\n');
        return;
    end % if

    vSpecies = oData.Translate.Lookup(sSpecies);
    iTrack   = fRawAxisToIndex(sTrack);
    if iTrack > 6
        iTrack = 4;
    end % if

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',     []);
    addParameter(oOpt, 'FigureSize', [750 450]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    addParameter(oOpt, 'Start',      'PStart');
    addParameter(oOpt, 'End',        'PEnd');
    addParameter(oOpt, 'Sample',     5);
    addParameter(oOpt, 'Filter',     'Top');
    addParameter(oOpt, 'Weights',    'P1');
    addParameter(oOpt, 'Average',    'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    
    % Data
    oCH = Charge(oData,vSpecies.Name,'Units','SI','X1Scale','mm','X2Scale','mm');
    if length(stOpt.Limits) == 4
        oCH.X1Lim = stOpt.Limits(1:2);
        oCH.X2Lim = stOpt.Limits(3:4);
    end % if

    stData = oCH.Tracking(stOpt.Start,stOpt.End,'Sample',stOpt.Sample,'Filter',stOpt.Filter,'Weights',stOpt.Weights);

    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        return;
    end % if
    
    stTags = fieldnames(stData.Data);
    iTags  = length(stTags);
    
    dMax = 0;
    for t=1:iTags
        iCount = length(stData.TAxis);
        stPlot.(stTags{t}).Time = [];
        stPlot.(stTags{t}).Data = [];
        for i=1:iCount
            if stData.Data.(stTags{t})(i,12)
                stPlot.(stTags{t}).Time(end+1) = stData.TAxis(i);
                stPlot.(stTags{t}).Data(end+1) = stData.Data.(stTags{t})(i,iTrack);
                if stData.Data.(stTags{t})(i,iTrack) > dMax
                    dMax = stData.Data.(stTags{t})(i,iTrack);
                end % if
            end % if
        end % for
    end % for
    
    aMean = stData.WMean(:,iTrack);
    aErr  = [stData.Max(:,iTrack)-aMean aMean-stData.Min(:,iTrack)];

    dScale = 1.0;
    if iTrack < 4
        sUnit = oCH.AxisUnits{iTrack};
    else
        sUnit = 'eV/c';
        [dTemp,sUnit] = fAutoScale(dMax,sUnit);
        dScale = dTemp/dMax;
    end % if
    
    % Plot

    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Particle Tracking (%s)',oData.Config.Name))
    else
        cla;
    end % if
    
    hold on;
    
    if strcmpi(stOpt.Average, 'no')
        for t=1:iTags
            plot(stPlot.(stTags{t}).Time, stPlot.(stTags{t}).Data*dScale);
        end % for
    else
        shadedErrorBar(stData.TAxis, aMean*dScale, aErr*dScale, {'-b', 'LineWidth', 2});
    end % if
    xlim([stData.TAxis(1) stData.TAxis(end)]);
    
    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('Tracking %s (%s)',vSpecies.Full,oData.Config.Name);
    else
        sTitle = sprintf('Tracking %s',vSpecies.Full);
    end % if

    title(sTitle);
    xlabel('z [m]');
    ylabel(sprintf('%s [%s]',oData.Translate.Lookup(sTrack).Tex,sUnit));
    
    hold off;


    % Returns
    stReturn.Species = vSpecies.Name;
    stReturn.XLim    = get(gca, 'XLim');
    stReturn.YLim    = get(gca, 'YLim');
    stReturn.Data    = stData;
    stReturn.Plot    = stPlot;
    
end

