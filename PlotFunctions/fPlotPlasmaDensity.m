%
%  Function: fPlotPlasmaDensity
% ******************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData   :: OsirisData object
%  sTime   :: Time dump
%  sPlasma :: Which plasma to look at
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  Charge      :: Calculate charge in ellipse two inputs for peak
%  FigureSize  :: Default [900 500]
%  IsSubplot   :: Default No
%  HideDump    :: Default No
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%  Absolute    :: Absolute value, default No
%

function stReturn = fPlotPlasmaDensity(oData, sTime, sPlasma, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotPlasmaDensity\n');
       fprintf(' ******************************\n');
       fprintf('  Plots density plot\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData   :: OsirisData object\n');
       fprintf('  sTime   :: Time dump\n');
       fprintf('  sPlasma :: Which plasma to look at\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  Limits      :: Axis limits\n');
       fprintf('  Charge      :: Calculate charge in ellipse two inputs for peak\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('  HideDump    :: Default No\n');
       fprintf('  CAxis       :: Color axis limits\n');
       fprintf('  ShowOverlay :: Default Yes\n');
       fprintf('\n');
       return;
    end % if
    
    sPlasma  = fTranslateSpecies(sPlasma);
    iTime    = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'OverlayBeam', '');
    addParameter(oOpt, 'ScatterBeam', '');
    addParameter(oOpt, 'Absolute',    'Yes');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if

    
    % Prepare Data

    oCH      = Charge(oData, sPlasma, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    oCH.Time = iTime;

    if length(stOpt.Limits) == 4
        oCH.X1Lim = stOpt.Limits(1:2);
        oCH.X2Lim = stOpt.Limits(3:4);
    end % if

    stData  = oCH.Density;

    aData   = stData.Data;
    aZAxis  = stData.X1Axis;
    aRAxis  = stData.X2Axis;
    dZPos   = stData.ZPos;

    if strcmpi(stOpt.Absolute, 'Yes')
        aData = abs(aData);
    end % if


    % Get beam overlay data if a beam is selected
    
    if ~isempty(stOpt.OverlayBeam)
    
        oBeam      = Charge(oData, stOpt.OverlayBeam, 'Units', 'SI', 'X1Scale', oCH.AxisScale{1}, 'X2Scale', oCH.AxisScale{1});
        oBeam.Time = iTime;

        if length(stOpt.Limits) == 4
            oBeam.X1Lim = stOpt.Limits(1:2);
            oBeam.X2Lim = stOpt.Limits(3:4);
        end % if
        
        stBeam     = oBeam.Density;
        aProjZ     = abs(sum(stBeam.Data));
        aProjZ     = 0.15*(aRAxis(end)-aRAxis(1))*aProjZ/max(abs(aProjZ))+aRAxis(1);

        stQTot     = oBeam.BeamCharge;
        dQ         = stQTot.QTotal*1e9;

        if abs(dQ) < 1.0e-3
            sBeamCharge = sprintf('Q_{tot} = %.2f fC', dQ*1e6);
        elseif abs(dQ) < 1.0
            sBeamCharge = sprintf('Q_{tot} = %.2f pC', dQ*1e3);
        else
            sBeamCharge = sprintf('Q_{tot} = %.2f nC', dQ);
        end % if
    
    else
        
        dQ = 0.0;
        
    end % if
    

    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        fFigureSize(gcf, stOpt.FigureSize);
        set(gcf,'Name',sprintf('Beam Fourier (Dump %d)',iTime),'NumberTitle','off')
    else
        cla;
    end % if

    imagesc(aZAxis, aRAxis, aData);
    set(gca,'YDir','Normal');
    colormap('gray');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;

    if ~isempty(stOpt.OverlayBeam)
        plot(aZAxis, aProjZ, 'White');
        h = legend(sBeamCharge, 'Location', 'NE');
        legend(h, 'boxoff');
        set(h,'TextColor', [1 1 1]);
        set(findobj(h, 'type', 'line'), 'visible', 'off')
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Density %s (Dump %d)', fTranslateSpeciesReadable(sPlasma), fPlasmaPosition(oData, iTime), iTime);
    else
        sTitle = sprintf('%s Density %s', fTranslateSpeciesReadable(sPlasma), fPlasmaPosition(oData, iTime));
    end % if

    title(sTitle,'FontSize',14);
    xlabel('\xi [mm]', 'FontSize',12);
    ylabel('r [mm]', 'FontSize',12);
    title(hCol, 'n_{pe}/n_0');
    
    hold off;
    
    
    % Return

    stReturn.Plasma = sPlasma;
    stReturn.XLim   = xlim;
    stReturn.YLim   = ylim;
    stReturn.CLim   = caxis;
    
end
