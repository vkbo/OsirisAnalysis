
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
%  FigureSize  :: Default [750 450]
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
        fprintf('  FigureSize  :: Default [750 450]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  Start       :: Default Plasma Start\n');
        fprintf('  End         :: Default Plasma End\n');
        fprintf('\n');
        return;
    end % if

    vSpecies = oData.Translate.Lookup(sSpecies,'Species');

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize', [750 450]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    addParameter(oOpt, 'Relative',   'Yes');
    addParameter(oOpt, 'Start',      'PStart');
    addParameter(oOpt, 'End',        'PEnd');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    % Variables
    

    % Data
    oMom   = Momentum(oData, vSpecies.Name);
    stData = oMom.SigmaEToEMean(stOpt.Start,stOpt.End,'Relative',stOpt.Relative);
    
    aTAxis = stData.TAxis;
    aData  = stData.Data*100;
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        stReturn.Error = 'No data';
        return;
    end % if

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
    
    H(1) = plot(aTAxis, aData, '-b', 'LineWidth', 2);
    
    xlim([aTAxis(1),aTAxis(end)]);

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Energy Sigma to Mean Ratio (%s #%d)',vSpecies.Full,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s Energy Sigma to Mean Ratio',vSpecies.Full);
    end % if

    title(sTitle);
    xlabel('z [m]');
    if strcmpi(stOpt.Relative,'Yes')
        ylabel('\sigma_E/\langleE\rangle-E_0 [%]');
    else
        ylabel('\sigma_E/\langleE\rangle [%]');
    end % if
    
    hold off;


    % Returns
    stReturn.Beam1 = vSpecies.Name;
    stReturn.XLim  = get(gca, 'XLim');
    stReturn.YLim  = get(gca, 'YLim');
    
end % function
