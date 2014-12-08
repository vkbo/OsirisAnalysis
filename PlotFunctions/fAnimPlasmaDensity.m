%
%  Function: fAnimBeamDensity
% ****************************
%  Plots density plot as animation
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sDrive   :: Drive beam
%  sWitness :: Witness beam (optional)
%
%  Options:
% ==========
%  FigureSize  :: Default [900 500]
%  DriveCut    :: Drive beam limits
%  WitnessCut  :: Witness beam limits
%  Start       :: First dump (default = 0)
%  End         :: Last dump (default = end)
%

function stReturn = fAnimPlasmaDensity(oData, sDrive, sWitness, varargin)

    % Input/Output

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fAnimBeamDensity\n');
       fprintf(' ****************************\n');
       fprintf('  Plots density plot as animation\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  sDrive   :: Drive beam\n');
       fprintf('  sWitness :: Witness beam (optional)\n');
       fprintf('\n');
       fprintf('  Options:\n');
       fprintf(' ==========\n');
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  Limits      :: Limits\n');
       fprintf('  Start       :: First dump (default = 0)\n');
       fprintf('  End         :: Last dump (default = end)\n');
       fprintf('\n');
       return;
    end % if
    
    stReturn   = {};
    sMovieFile = 'AnimPlasmaDensity';

    oOpt = inputParser;
    addParameter(oOpt, 'FigureSize',  [1100 600]);
    addParameter(oOpt, 'Limits',      [216.0, 220.0, -0.5, 0.5]);
    addParameter(oOpt, 'Start',       'Start');
    addParameter(oOpt, 'End',         'End');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    iStart  = fStringToDump(oData, stOpt.Start);
    iEnd    = fStringToDump(oData, stOpt.End);
    aDim    = stOpt.FigureSize;
    aLimits = stOpt.Limits;


    % Animation Loop

    figMain = figure;
    set(figMain, 'Position', [1800-aDim(1), 1000-aDim(2), aDim(1), aDim(2)]);

    for k=iStart:iEnd

        clf;
        i = k-iStart+1;

        % Call plot
        stB1Info = fPlotPlasmaDensity(oData, k, 'PE', 'Absolute', 'Yes', 'Limits', aLimits, 'CAxis', [0 5], ...
                                      'Overlay1', sWitness, 'Overlay2', sDrive, ...
                                      'Scatter1', sWitness, 'Sample1', 1000, ...
                                      'Scatter2', sDrive,   'Sample2', 2000);

        drawnow;

        set(figMain, 'PaperUnits', 'Inches', 'PaperPosition', [1 1 aDim(1)/96 aDim(2)/96]);
        set(figMain, 'InvertHardCopy', 'Off');
        print(figMain, '-dtiffnocompression', '-r96', '/tmp/osiris-print.tif');
        M(i).cdata    = imread('/tmp/osiris-print.tif');
        M(i).colormap = [];

    end % for

    movie2avi(M, '/tmp/osiris-temp.avi', 'fps', 6, 'Compression', 'None');
    [~,~] = system(sprintf('avconv -i /tmp/osiris-temp.avi -c:v libx264 -crf 1 -s %dx%d -b:v 50000k Movies/%s-%s.mp4', aDim(1), aDim(2), sMovieFile, fTimeStamp));
    [~,~] = system('rm /tmp/osiris-temp.avi');
    
    
    % Return values
    stReturn.Movie           = M;
    stReturn.DriveBeamInfo   = stB1Info;
    stReturn.WitnessBeamInfo = stB2Info;

end % function
