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
%  RRange      :: Radial range to sum over. Default is all
%

function stReturn = fPlotBeamFourier(oData, oRefData, sTime, sRefTime, sBeam, sRefBeam, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotBeamFourier\n');
       fprintf(' ****************************\n');
       fprintf('  Plots the fourier transform of the beam density\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  oRefData :: Reference OsirisData object\n');
       fprintf('  sTime    :: Time dump\n');
       fprintf('  sRefTime :: Reference time dump\n');
       fprintf('  sBeam    :: Beam\n');
       fprintf('  sRefBeam :: Reference beam\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  Limits      :: Axis limits\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('  HideDump    :: Default No\n');
       fprintf('  Legend      :: Default ''Beam''\n');
       fprintf('  RefLegend   :: Default ''Reference Beam''\n');
       fprintf('  RRange      :: Radial range to sum over. Default is all\n');
       fprintf('\n');
       return;
    end % if

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
    addParameter(oOpt, 'RRange',      []);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data

    oCH      = Charge(oData, sBeam);
    oCH.Time = iTime;
    stFFT    = oCH.Fourier(stOpt.RRange);
    clear oCH;

    if ~isempty(oRefData)
        oCH      = Charge(oRefData, sRefBeam);
        oCH.Time = iRefTime;
        stRefFFT = oCH.Fourier(stOpt.RRange);
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
