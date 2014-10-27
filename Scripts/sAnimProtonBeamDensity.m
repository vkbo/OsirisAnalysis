
%
% Script to generate an animation of the evolution of the ElectronBeam
%

iStart = 0;
iEnd   = 122;
aDim   = [900, 500];
aPBCut = [0.0, 315.0, -2.0, 2.0];

figMain = figure;
set(figMain, 'Position', [1800-aDim(1), 1000-aDim(2), aDim(1), aDim(2)]);


clear M;

for k=iStart:iEnd
    
    clf;
    i = k-iStart+1;

    % ProtonBeam Density
    stPBInfo = fPlotBeamDensity(od, k, 'PB', 'Limits', aPBCut, 'CAxis', [0.0 0.01]);
    colorbar('off');

    drawnow;
    
    set(figMain, 'PaperPosition', [1 1 aDim(1)/96 aDim(2)/96]);
    set(figMain, 'InvertHardCopy', 'Off');
    print(figMain, '-dtiffnocompression', '-r96', 'Temp/print.tif');
    M(i).cdata    = imread('Temp/print.tif');
    M(i).colormap = [];

end % for

movie2avi(M, 'Movies/Temp.avi', 'fps', 6, 'Compression', 'None');
[~,~] = system(sprintf('avconv -i Movies/Temp.avi -c:v libx264 -crf 1 -s %dx%d -b:v 50000k Movies/AnimPBDensity-%s.mp4', aDim(1), aDim(2), fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

clear i;
clear k;
clear iEnd;
clear iStart;
clear aDim;
clear aPBCut;

