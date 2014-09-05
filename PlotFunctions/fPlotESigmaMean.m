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

function stReturn = fPlotESigmaMean(oData, sSpecies)

    % Defaults
    stReturn = {};

    
    % Handle inputs
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
       return;
    end % if

    sSpecies = fTranslateSpecies(sSpecies); 


    % Data
    oMom   = Momentum(oData, sSpecies);
    stData = oMom.SigmaEToEMean('PStart','PEnd');
    

    % Plot
    cla
    
    hold on;
    
    H(1) = shadedErrorBar(stData.TimeAxis, stData.Mean, stData.Sigma, {'-b', 'LineWidth', 2});
    %plot(stData.TimeAxis, stData.Mean+stData.Sigma, 'red--');
    %plot(stData.TimeAxis, stData.Mean-stData.Sigma, 'red--');
    
    legend([H(1).mainLine, H.patch], '<E>', '\sigma_E', 'Location', 'SouthEast');
    aXLim = [stData.TimeAxis(1),stData.TimeAxis(end)];
    xlim(aXLim);
    aYLim = get(gca,'YLim');

    sTitle = sprintf('%s Mean Energy', sSpecies);
    title(sTitle, 'FontSize', 16);
    xlabel('$$\zeta [\mbox{m}]$$', 'Interpreter', 'LaTex', 'FontSize', 14);
    ylabel('$$P_{z} [\mbox{MeV/c}]$$', 'Interpreter', 'LaTex', 'FontSize', 14);
    
    hold off;


    % Returns
    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = aXLim;
    stReturn.YLim  = aYLim;
    
end

