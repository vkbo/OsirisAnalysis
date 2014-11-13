%
%  Function: fAnimBeamWavelet
% ****************************
%  Plots wavelet plot as animation
%
%  Inputs:
% =========
%  oData  :: OsirisData object
%  sBeam  :: Beam
%
%  Options:
% ==========
%  FigureSize  :: Default [1400 900]
%  Start       :: First dump (default = 0)
%  End         :: Last dump (default = end)
%

function stReturn = fAnimBeamWavelet(oData, sBeam, varargin)

    % Input/Output

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fAnimBeamWavelet\n');
       fprintf(' ****************************\n');
       fprintf('  Plots wavelet plot as animation\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData  :: OsirisData object\n');
       fprintf('  sBeam  :: Beam\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  FigureSize  :: Default [1400 900]\n');
       fprintf('  Start       :: First dump (default = 0)\n');
       fprintf('  End         :: Last dump (default = end)\n');
       fprintf('\n');
       return;
    end % if
    
    stReturn   = {};
    sBeam      = fTranslateSpecies(sBeam);
    sMovieFile = 'AnimPBWavelet';

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize',  [1400 900]);
    addParameter(oOpt, 'Start',       'Start');
    addParameter(oOpt, 'End',         'End');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    iStart = fStringToDump(oData, stOpt.Start);
    iEnd   = fStringToDump(oData, stOpt.End);
    aDim   = stOpt.FigureSize;


    % Animation Loop

    figMain = figure;
    set(figMain, 'Position', [1800-aDim(1), 1000-aDim(2), aDim(1), aDim(2)]);

    for k=iStart:iEnd

        clf;
        i = k-iStart+1;

        stBeamInfo = fPlotBeamWavelet(oData, k, sBeam, 'IsSubPlot', 'Yes', 'RRange', [3 425]);

        drawnow;

        set(figMain, 'PaperUnits', 'Inches', 'PaperPosition', [1 1 aDim(1)/96 aDim(2)/96]);
        set(figMain, 'InvertHardCopy', 'Off');
        print(figMain, '-dtiffnocompression', '-r96', '/tmp/osiris-print.tif');
        M(i).cdata    = imread('/tmp/osiris-print.tif');
        M(i).colormap = [];

    end % for

    movie2avi(M, '/tmp/osiris-temp.avi', 'fps', 6, 'Compression', 'None');
    [~,~] = system(sprintf('avconv -i /tmp/osiris-temp.avi -c:v libx264 -crf 1 -s %dx%d -b:v 50000k Movies/%s-%s.mp4', aDim(1), aDim(2), sMovieFile, fTimeStamp));
    [~,~] = system('rm Movies/Temp.avi');
    
    
    % Return values
    stReturn.Movie      = M;
    stReturn.BeamInfo   = stBeamInfo;

end % function
