
%
%  Function: fPlotESigmaMeanRatio
% ********************************
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
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  Start       :: Default Plasma Start
%  End         :: Default Plasma End
%

function stReturn = fPlotESigmaMeanRatio(oData, sSpecies, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotESigmaMeanRatio\n');
        fprintf(' ********************************n');
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
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  Start       :: Default Plasma Start\n');
        fprintf('  End         :: Default Plasma End\n');
        fprintf('\n');
        return;
    end % if

    sSpecies = fTranslateSpecies(sSpecies);

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize', [900 500]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    addParameter(oOpt, 'Start',      'PStart');
    addParameter(oOpt, 'End',        'PEnd');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data
    oMom   = Momentum(oData, sSpecies);
    stData = oMom.SigmaEToEMean('PStart','PEnd');
    

    % Plot

    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Sigma E to E Mean Ratio (%s)',oData.Config.Name))
    else
        cla;
    end % if
    
    hold on;
    
    H(1) = plot(stData.TimeAxis, stData.Data, '-b', 'LineWidth', 2);
    
    xlim([stData.TimeAxis(1),stData.TimeAxis(end)]);

    if strcmpi(oMom.Coords, 'cylindrical')
        sRType = 'ReadableCyl';
    else
        sRType = 'Readable';
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Energy Sigma to Mean Ratio (%s #%d)',fTranslateSpecies(sSpecies,sRType),oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s Energy Sigma to Mean Ratio',fTranslateSpecies(sSpecies,sRType));
    end % if

    title(sTitle);
    xlabel('z [m]');
    ylabel('\sigma_E/<E>');
    
    hold off;


    % Returns
    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = get(gca, 'XLim');
    stReturn.YLim  = get(gca, 'YLim');
    
end

