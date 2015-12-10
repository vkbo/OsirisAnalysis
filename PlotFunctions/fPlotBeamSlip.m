
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
%  FigureSize  :: Default [750 450]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  Start       :: Default Plasma Start
%  End         :: Default Plasma End
%  LambdaRel   :: Relative to start and lambda_p
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
        fprintf('  FigureSize  :: Default [750 450]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  Start       :: Default Plasma Start\n');
        fprintf('  End         :: Default Plasma End\n');
        fprintf('  LambdaRel   :: Relative to start and lambda_p\n');
        fprintf('\n');
        return;
    end % if

    vBeam = oData.Translate.Lookup(sBeam,'Beam');

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize', [750 450]);
    addParameter(oOpt, 'HideDump',   'No');
    addParameter(oOpt, 'IsSubPlot',  'No');
    addParameter(oOpt, 'AutoResize', 'On');
    addParameter(oOpt, 'Start',      'PStart');
    addParameter(oOpt, 'End',        'PEnd');
    addParameter(oOpt, 'LambdaRel',  'No');
    addParameter(oOpt, 'AddEnergy',  0);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data

    oMom      = Momentum(oData,vBeam.Name,'Units','SI','X1Scale','mm');
    stData    = oMom.BeamSlip(stOpt.Start,stOpt.End,stOpt.AddEnergy);
    
    aTAxis    = stData.TAxis;
    aActual   = stData.Position.Median;
    aASpread  = [abs(aActual-stData.Position.FirstQuartile); abs(aActual-stData.Position.ThirdQuartile)];
    aExpected = stData.ExpectedPos.Average;
    
    sXLabel   = 'z [m]';
    sYLabel   = '\xi [mm]';
    
    if stOpt.AddEnergy > 0
        aExpectedAdd = stData.ExpectedAdd.Average;
    end % if

    if strcmpi(stOpt.LambdaRel, 'Yes')
        
        dLambdaP  = oData.Config.Variables.Plasma.MaxLambdaP*1e3;
        
        aActual   = 100*(aActual   - aActual(1))*dLambdaP;
        aASpread  = 100*aASpread*dLambdaP;
        aExpected = 100*(aExpected - aExpected(1))*dLambdaP;

        if stOpt.AddEnergy > 0
            aExpectedAdd = 100*(aExpectedAdd - aExpectedAdd(1))*dLambdaP;
        end % if
        
        sYLabel   = '\xi_0\lambda_P [%]';

    end % if
    
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('%s Beam Slip (%s)',vBeam.Name,oData.Config.Name))
    else
        cla;
    end % if

    hold on;

    hA(1) = shadedErrorBar(aTAxis, aActual,   aASpread, {'-b', 'LineWidth', 2});
    hE    = plot(aTAxis, aExpected, 'Red', 'LineWidth', 1, 'LineStyle', '--');
    hL    = line([0 0], get(gca, 'YLim'), 'Color', [0.5 0.8 0.0], 'LineStyle', '--');

    if stOpt.AddEnergy > 0
        hB = plot(aTAxis, aExpectedAdd, 'Color', [0.5 0.5 0.5], 'LineWidth', 1, 'LineStyle', '--');
    end % if
    
    legend([hA(1).mainLine, hA.patch, hE, hL], 'Median Position', 'Quartiles', 'Expected Slip', 'Plasma Start', 'Location', 'NorthEast');
    
    xlim([aTAxis(1), aTAxis(end)]);
    
    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Slipping (%s #%d)',vBeam.Full,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s Slipping',vBeam.Full);
    end % if

    title(sTitle);
    xlabel(sXLabel);
    ylabel(sYLabel);
    
    hold off;
    
    % Returns
    stReturn.Beam  = vBeam.Name;
    stReturn.TAxis = aTAxis;
    stReturn.XLim  = get(gca, 'XLim');
    stReturn.YLim  = get(gca, 'YLim');

end % functions
