%
%  Function: fPlotBeamSlip
% *************************
%  Plots the slippage of a beam through the simulation
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sBeam    :: Beam
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  FigureSize  :: Default [900 500]
%  IsSubplot   :: Default No
%

function stReturn = fPlotBeamSlip(oData, sBeam, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotBeamSlip\n');
       fprintf(' *************************\n');
       fprintf('  Plots the slippage of a beam through the simulation\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  sBeam    :: Beam\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  Limits      :: Axis limits\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('\n');
       return;
    end % if

    sBeam = fTranslateSpecies(sBeam);

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'IsSubPlot',   'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data

    oM        = Momentum(oData, sBeam);
    stData    = oM.BeamSlip();
    
    aTAxis    = stData.TAxis;
    aActual   = stData.Position.Median;
    aASpread  = [abs(aActual-stData.Position.FirstQuartile); ...
                 abs(aActual-stData.Position.ThirdQuartile)];
    aExpected = stData.ExpectedPos.Average;
    
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        fFigureSize(gcf, stOpt.FigureSize);
    else
        cla;
    end % if

    hold on;

    hA(1) = shadedErrorBar(aTAxis, aActual,   aASpread, {'-b', 'LineWidth', 2});
    hE    = plot(aTAxis, aExpected, 'Red', 'LineWidth', 1, 'LineStyle', '--');
    
    legend([hA(1).mainLine, hA.patch, hE], 'Median Position', 'Quartiles', 'Expected Slip', 'Location', 'NorthEast');
    
    xlim([aTAxis(1), aTAxis(end)]);
    
    sTitle = sprintf('%s Slipping', fTranslateSpeciesReadable(sBeam));
    title(sTitle,'FontSize',14);

    xlabel('z [m]',    'FontSize', 12);
    ylabel('\xi [mm]', 'FontSize', 12);
    
    hold off;

end

