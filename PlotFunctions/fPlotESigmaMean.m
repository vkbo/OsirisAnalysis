%
%  Function: fPlotESigmaMean
% ***************************
%  Plots the evolution of mean energy of a beam
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sSpecies :: Which species
%
%  Options:
% ==========
%  FigureSize  :: Default [900 500]
%  IsSubplot   :: Default No
%  Start       :: Default Plasma Start
%  End         :: Default Plasma End
%

function stReturn = fPlotESigmaMean(oData, sSpecies, varargin)

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
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('  Start       :: Default Plasma Start\n');
       fprintf('  End         :: Default Plasma End\n');
       fprintf('\n');
       return;
    end % if

    sSpecies = fTranslateSpecies(sSpecies); 

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'Start',      'PStart');
    addParameter(oOpt, 'End',        'PEnd');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data
    oMom   = Momentum(oData, sSpecies);
    stData = oMom.SigmaEToEMean(stOpt.Start, stOpt.End);
    
    dPeak  = max(abs(stData.Mean+stData.Sigma));
    [dTemp, sPUnit] = fAutoScale(dPeak, 'eV');
    dScale = dTemp/dPeak;

    % Plot

    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Sigma E to E Mean (%s)',oData.Config.Name))
    else
        cla;
    end % if
    
    hold on;
    
    H(1) = shadedErrorBar(stData.TimeAxis, stData.Mean*dScale, stData.Sigma*dScale, {'-b', 'LineWidth', 2});
    
    legend([H(1).mainLine, H.patch], '<E>', '\sigma_E', 'Location', 'SouthEast');
    xlim([stData.TimeAxis(1), stData.TimeAxis(end)]);

    if strcmpi(oMom.Coords, 'cylindrical')
        sRType = 'ReadableCyl';
    else
        sRType = 'Readable';
    end % of

    sTitle = sprintf('%s Mean Energy', fTranslateSpecies(sSpecies,sRType));
    title(sTitle);
    xlabel('z [m]');
    ylabel(sprintf('P_z [%s/c]', sPUnit));
    
    hold off;


    % Returns
    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = get(gca, 'XLim');
    stReturn.YLim  = get(gca, 'YLim');
    
end

