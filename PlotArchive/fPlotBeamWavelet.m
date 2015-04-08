%
%  Function: fPlotBeamWavelet
% ****************************
%  Plots a wavelet analysis of the beam density
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
%  RRange      :: Radial range to sum over. Default is all
%  Octaves     :: Number of octaves to compute. Default is 10
%  Data        :: Real, Imaginary, Power. Default is Real
%

function stReturn = fPlotBeamWavelet(oData, sTime, sBeam, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotBeamWavelet\n');
       fprintf(' ****************************\n');
       fprintf('  Plots a wavelet analysis of the beam density\n');
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
       fprintf('  RRange      :: Radial range to sum over. Default is all\n');
       fprintf('  Octaves     :: Number of octaves to compute. Default is 10\n');
       fprintf('  Data        :: Real, Imaginary, Power. Default is Real\n');
       fprintf('\n');
       return;
    end % if

    sBeam    = fTranslateSpecies(sBeam);
    iTime    = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'Legend',      'Beam');
    addParameter(oOpt, 'RRange',      []);
    addParameter(oOpt, 'Octaves',     12);
    addParameter(oOpt, 'Data',        'Real');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;


    % Data

    oCH        = Charge(oData, sBeam);
    oCH.Time   = iTime;
    oCH.Units  = 'SI';
    oCH.ZScale = 'mm';
    stWL       = oCH.Wavelet(stOpt.RRange, 'Octaves', stOpt.Octaves);
    clear oCH;

    % Plot

    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        fFigureSize(gcf, stOpt.FigureSize);
        set(gcf,'Name',sprintf('Beam Fourier (Dump %d)',iTime),'NumberTitle','off')
    else
        cla;
        caxis auto;
    end % if
    
    % Input data plot
    
    ah1 = subplot(4,1,1);
    plot(stWL.XAxis, stWL.Input);
    xlim([stWL.XAxis(1) stWL.XAxis(end)]);
    ylim([0 1.02*max(stWL.Input)]);

    xlabel('\xi [mm]', 'FontSize', 12);
    ylabel('Amplitude', 'FontSize', 12);
    title(sprintf('Wavelet Analysis of Proton Beam at Dump %d', iTime), 'FontSize', 14);
    
    % Wavelet plot
    
    ah2 = subplot(4,1,2:4);
    
    switch(lower(stOpt.Data))
        case 'real'
            aData = stWL.Real;
        case 'imaginary'
            aData = stWL.Imaginary;
        case 'power'
            aData = stWL.Power;
        otherwise
            aData = stWL.Real;
    end % switch

    imagesc(stWL.XAxis, log2(stWL.Period), aData);

    xlim([stWL.XAxis(1) stWL.XAxis(end)]);

    aYTicks = 2.^(fix(log2(min(stWL.Period))):fix(log2(max(stWL.Period))));
    set(gca, 'YDir',  'Reverse');
    set(gca, 'YLim',  log2([min(stWL.Period),max(stWL.Period)]));
	set(gca, 'YTick', log2(aYTicks(:)), 'YTickLabel', aYTicks);
    
    colorbar;
    polarmap(128);
    caxis([-0.1, 0.1]);
    

    hold on;
    plot(stWL.XAxis, log2(stWL.COI), 'Black', 'LineWidth', 2);
    hold off;

    xlabel('\xi [mm]', 'FontSize', 12);
    ylabel('Period [\lambda_p]', 'FontSize', 12);

    aPos2 = get(ah2,'Position');
    aPos1 = get(ah1,'Position');
    aPos1(3) = aPos2(3);
    set(ah1,'Position',aPos1);
    

    % Return

    stReturn.BeamWL = stWL.Data;
    stReturn.XAxis  = stWL.XAxis;

end % function
