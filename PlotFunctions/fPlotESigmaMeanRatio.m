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
%  IsSubplot   :: Default No
%

function stReturn = fPlotESigmaMeanRatio(oData, sSpecies, varargin)

    % Input/Output

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
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('\n');
       return;
    end % if

    stReturn = {};
    sSpecies = fTranslateSpecies(sSpecies);

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize', [900 500]);
    addParameter(oOpt, 'IsSubPlot',  'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data
    oMom   = Momentum(oData, sSpecies);
    stData = oMom.SigmaEToEMean('PStart','PEnd');
    

    % Plot

    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        fFigureSize(gcf, stOpt.FigureSize);
    else
        cla;
    end % if
    
    hold on;
    
    H(1) = plot(stData.TimeAxis, stData.Data, '-b', 'LineWidth', 2);
    
    xlim([stData.TimeAxis(1),stData.TimeAxis(end)]);

    sTitle = sprintf('%s Energy Mean to Sigma Ratio', fTranslateSpeciesReadable(sSpecies));
    title(sTitle, 'FontSize', 16);
    xlabel('z [m]', 'FontSize', 12);
    ylabel('<E> / \sigma_E', 'FontSize', 12);
    
    hold off;


    % Returns
    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = get(gca, 'XLim');
    stReturn.YLim  = get(gca, 'YLim');
    
end

