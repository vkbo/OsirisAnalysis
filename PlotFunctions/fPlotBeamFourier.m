%
%  Function: fPlotBeamFourier
% ****************************
%  Plots the fourier transform of the beam density
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  oRefData :: Reference OsirisData object
%  sTime    :: Time dump
%  sRefTime :: Reference time dump
%  sBeam    :: Beam
%  sRefBeam :: Reference beam
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  FigureSize  :: Default [900 500]
%  IsSubplot   :: Default No
%  HideDump    :: Default No
%  Legend      :: Default 'Beam'
%  RefLegend   :: Default 'Reference Beam'
%

function stReturn = fPlotBeamFourier(oData, oRefData, sTime, sRefTime, sBeam, sRefBeam, varargin)

    stReturn = {};
    sBeam    = fTranslateSpecies(sBeam);
    sRefBeam = fTranslateSpecies(sRefBeam);
    iTime    = fStringToDump(oData, num2str(sTime));
    iRefTime = fStringToDump(oRefData, num2str(sRefTime));
    stRefFFT = {};

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'Legend',      'Beam');
    addParameter(oOpt, 'RefLegend',   'Reference Beam');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;
    
    % Data
    
    oCH      = Charge(oData, sBeam);
    oCH.Time = iTime;
    stFFT    = oCH.Fourier();
    dZPos    = stFFT.ZPos;
    clear oCH;
    
    if ~isempty(oRefData)
        oCH      = Charge(oRefData, sRefBeam);
        oCH.Time = iRefTime;
        stRefFFT = oCH.Fourier();
        clear oCH;
    end % if
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        fFigureSize(gcf, stOpt.FigureSize);
        set(gcf,'Name',sprintf('Beam Fourier (Dump %d)',iTime),'NumberTitle','off')
    else
        cla;
    end % if

    hold on;

    iLegend = 1;
    if ~isempty(oRefData)
        area(stRefFFT.XAxis, stRefFFT.Data, 'FaceColor', [1.0, 0.8, 0.8], 'EdgeColor', [1.0, 0.0, 0.0]);
        stLegend{iLegend} = stOpt.RefLegend;
        iLegend = iLegend + 1;
    end % if
    
    plot(stFFT.XAxis, stFFT.Data, 'Color', 'Blue', 'LineWidth', 2.0);
    stLegend{iLegend} = stOpt.Legend;

    if ~isempty(stOpt.Limits)
        axis(stOpt.Limits);
    end % if
    
    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('Fourier Transform of %s Density %s (Dump %d)', fTranslateSpeciesReadable(sBeam), fPlasmaPosition(oData, iTime), iTime);
    else
        sTitle = sprintf('Fourier Transform of %s Density %s', fTranslateSpeciesReadable(sBeam), fPlasmaPosition(oData, iTime));
    end % if

    legend(stLegend, 'Location', 'NE');
    title(sTitle,'FontSize',14);
    xlabel('1/k [c/\omega_p]', 'FontSize',12);
    ylabel('Amplitude', 'FontSize',12);
    
    hold off;

    
    % Return

    stReturn.BeamFFT    = stFFT;
    stReturn.RefBeamFFT = stRefFFT;

end % function
