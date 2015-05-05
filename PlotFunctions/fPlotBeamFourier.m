%
%  Function: fPlotBeamFourier
% ****************************
%  Plots the fourier transform of the beam density
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Time dump
%  sBeam    :: Beam
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  FigureSize  :: Default [900 500]
%  IsSubplot   :: Default No
%  HideDump    :: Default No
%  Legend      :: Default 'Beam'
%  RefData     :: Reference OsirisData object
%  RefTime     :: Reference time dump
%  RefBeam     :: Reference beam
%  RefLegend   :: Default 'Reference Beam'
%  RRange      :: Radial range to sum over. Default is all
%

function stReturn = fPlotBeamFourier(oData, sTime, sBeam, varargin)

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
       fprintf('  sTime    :: Time dump\n');
       fprintf('  sBeam    :: Beam\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  Limits      :: Axis limits\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('  HideDump    :: Default No\n');
       fprintf('  Legend      :: Default ''Beam''\n');
       fprintf('  RefData     :: Reference OsirisData object\n');
       fprintf('  RefTime     :: Reference time dump\n');
       fprintf('  RefBeam     :: Reference beam\n');
       fprintf('  RefLegend   :: Default ''Reference Beam''\n');
       fprintf('  RRange      :: Radial range to sum over. Default is all\n');
       fprintf('\n');
       return;
    end % if

    sBeam    = fTranslateSpecies(sBeam);
    iTime    = fStringToDump(oData, num2str(sTime));
    stRefFFT = {};

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'Legend',      'Beam');
    addParameter(oOpt, 'RefData',     []);
    addParameter(oOpt, 'RefTime',     0);
    addParameter(oOpt, 'RefBeam',     '');
    addParameter(oOpt, 'RefLegend',   'Reference Beam');
    addParameter(oOpt, 'RRange',      []);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data
    oCH      = Charge(oData, sBeam);
    oCH.Time = iTime;
    stFFT    = oCH.Fourier(stOpt.RRange);
    clear oCH;

    if ~isempty(stOpt.RefData)
        sRefBeam = fTranslateSpecies(stOpt.RefBeam);
        iRefTime = fStringToDump(stOpt.RefData, num2str(stOpt.RefTime));
        oCH      = Charge(stOpt.RefData, sRefBeam);
        oCH.Time = iRefTime;
        stRefFFT = oCH.Fourier(stOpt.RRange);
        clear oCH;
    end % if


    % Plot
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Beam Fourier (Dump %d)',iTime))
    else
        cla;
    end % if

    hold on;

    iLegend = 1;
    if ~isempty(stOpt.RefData)
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
        sTitle = sprintf('%s Fourier Transform %s (%s #%d)', fTranslateSpecies(sBeam,'Readable'), fPlasmaPosition(oData, iTime), oData.Config.Name, iTime);
    else
        sTitle = sprintf('%s Fourier Transform %s', fTranslateSpecies(sBeam,'Readable'), fPlasmaPosition(oData, iTime));
    end % if

    legend(stLegend, 'Location', 'NE');
    title(sTitle);
    xlabel('k_p/2\pi [\omega_p/c]');
    ylabel('Amplitude');

    hold off;


    % Return

    stReturn.BeamFFT    = stFFT;
    stReturn.RefBeamFFT = stRefFFT;

end % function
