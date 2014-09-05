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

function stReturn = fPlotESigmaMeanRatio(oData, sSpecies)

    % Defaults
    stReturn = {};

    
    % Handle inputs
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
       return;
    end % if

    sSpecies = fTranslateSpecies(sSpecies); 


    % Data
    oMom   = Momentum(oData, sSpecies);
    stData = oMom.SigmaEToEMean('PStart','PEnd');
    

    % Plot
    cla
    
    hold on;
    
    H(1) = plot(stData.TimeAxis, stData.Data, '-b', 'LineWidth', 2);
    
    %legend(H(1), '<E>/\sigma_E', 'Location', 'SouthEast');
    aXLim = [stData.TimeAxis(1),stData.TimeAxis(end)];
    xlim(aXLim);
    aYLim = get(gca,'YLim');

    sTitle = sprintf('%s Energy Mean to Sigma Ratio', sSpecies);
    title(sTitle, 'FontSize', 16);
    xlabel('$$\zeta [\mbox{m}]$$', 'Interpreter', 'LaTex', 'FontSize', 14);
    ylabel('$$\langle E \rangle / \sigma_E$$', 'Interpreter', 'LaTex', 'FontSize', 14);
    
    hold off;


    % Returns
    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = aXLim;
    stReturn.YLim  = aYLim;
    
end

