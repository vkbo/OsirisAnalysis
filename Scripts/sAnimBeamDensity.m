
%
% Script to generate an animation of the evolution of the proton beam
%

iStart = 0;
iEnd   = 110;
aDim   = [1300, 500];
sBeam1 = 'PB';
sBeam2 = 'EB';
aB1Cut = [  0.0, 315.0, -2.0, 2.0];
aB2Cut = [217.0, 220.0, -0.3, 0.3];


% Animation Loop

figMain = figure;
set(figMain, 'Position', [1800-aDim(1), 1000-aDim(2), aDim(1), aDim(2)]);

clear M;

sBeam1     = fTranslateSpecies(sBeam1);
sBeam2     = fTranslateSpecies(sBeam2);
sMovieFile = 'AnimPBDensity';

for k=iStart:iEnd
    
    clf;
    i = k-iStart+1;

    % Beam 1
    if ~strcmpi(sBeam2, '')
        subplot(1,3,[1:2]);
    end % if
    stB1Info = fPlotBeamDensity(od, k, sBeam1, 'Limits', aB1Cut, 'CAxis', [0.0 0.01], 'IsSubPlot', 'Yes');
    colorbar('off');

    % Beam 2
    if ~strcmpi(sBeam2, '')
        subplot(1,3,3);
        stB2Info = fPlotBeamDensity(od, k, sBeam2, 'Limits', aB2Cut, 'IsSubPlot', 'Yes', 'Absolute', 'Yes');
        title(sprintf('%s Density', fTranslateSpeciesReadable(sBeam2)), 'FontSize', 14);
        colorbar('off');
        sMovieFile = 'AnimPBEBDensity';
    end % if

    drawnow;
    
    set(figMain, 'PaperPosition', [1 1 aDim(1)/96 aDim(2)/96]);
    set(figMain, 'InvertHardCopy', 'Off');
    print(figMain, '-dtiffnocompression', '-r96', 'Temp/print.tif');
    M(i).cdata    = imread('Temp/print.tif');
    M(i).colormap = [];

end % for

movie2avi(M, 'Movies/Temp.avi', 'fps', 6, 'Compression', 'None');
[~,~] = system(sprintf('avconv -i Movies/Temp.avi -c:v libx264 -crf 1 -s %dx%d -b:v 50000k Movies/%s-%s.mp4', aDim(1), aDim(2), sMovieFile, fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

% Variable cleanup

clear i;
clear k;
clear iEnd;
clear iStart;
clear aDim;
clear aB1Cut;
clear aB2Cut;
clear sBeam1;
clear sBeam2;
clear sMovieFile;
