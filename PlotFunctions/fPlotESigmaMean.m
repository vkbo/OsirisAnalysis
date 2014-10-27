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
%

function stReturn = fPlotESigmaMean(oData, sSpecies, varargin)

    % Input/Output

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
    end % if
    
    hold on;
    
    H(1) = shadedErrorBar(stData.TimeAxis, stData.Mean, stData.Sigma, {'-b', 'LineWidth', 2});
    %plot(stData.TimeAxis, stData.Mean+stData.Sigma, 'red--');
    %plot(stData.TimeAxis, stData.Mean-stData.Sigma, 'red--');
    
    legend([H(1).mainLine, H.patch], '<E>', '\sigma_E', 'Location', 'SouthEast');
    xlim([stData.TimeAxis(1), stData.TimeAxis(end)]);

    sTitle = sprintf('%s Mean Energy', sSpecies);
    title(sTitle, 'FontSize', 16);
    xlabel('s [m]', 'FontSize', 12);
    ylabel('P_z [MeV/c]', 'FontSize', 12);
    
    hold off;


    % Returns
    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = get(gca, 'XLim');
    stReturn.YLim  = get(gca, 'YLim');
    
end

