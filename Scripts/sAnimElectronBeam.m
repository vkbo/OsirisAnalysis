
%
% Script to generate an animation of the evolution of the ElectronBeam
%

iStart = 0;
iEnd   = fStringToDump(od, 'End');
aDim   = [1200, 700];
xMin   = 213;
xMax   = 221;

% Animation Loop

figMain = figure;
set(figMain, 'Position', [1800-aDim(1), 1000-aDim(2), aDim(1), aDim(2)]);

sMovieFile = 'AnimBeam';

clear M;

for k=iStart:iEnd
    
    clf;
    i = k-iStart+1;

    % Beam density lineout
    subplot(2,3,[1:2]);
    fPlotBeamDensityEField(od, k, [3,13], 'PB', 'EB');
    axis([xMin, xMax, -1.05, 1.05]);
    
    % Electron Beam x1p1
    subplot(2,3,3);
    colormap(gray);
    fPlotPhase2D(od, k, 'EB', 'x1', 'p1');
    title('Electron Beam x1p1', 'FontSize', 14);
    axis([xMin, xMax, -20, 2000]);
    caxis([0, 1e-5]);
    freezeColors;
    
    % ElectronBeam Density
    subplot(2,3,4);
    fPlotBeamDensity(od, k, 'EB', [xMin, xMax, -0.2, 0.2]);
    title('Electron Beam Density', 'FontSize', 14);
    %axis([xMin, xMax, -0.2, 0.2]);

    % ProtonBeam Density
    subplot(2,3,5);
    fPlotBeamDensity(od, k, 'PB', [xMin, xMax, -0.2, 0.2]);
    title('Proton Beam Density', 'FontSize', 14);
    %axis([xMin, xMax, -0.2, 0.2]);

    % E-Field
    subplot(2,3,6);
    fPlotField(od, k, 'e1');
    title('Ez-Field', 'FontSize', 14);
    axis([xMin, xMax, -0.7, 0.7]);
    
    drawnow;
    
    set(figMain, 'PaperPosition', [1 1 aDim(1)/96 aDim(2)/96]);
    set(figMain, 'InvertHardCopy', 'Off');
    print(figMain, '-dtiffnocompression', '-r96', '/tmp/osiris-print.tif');
    M(i).cdata    = imread('/tmp/osiris-print.tif');
    M(i).colormap = [];

end % for

movie2avi(M, '/tmp/osiris-temp.avi', 'fps', 6, 'Compression', 'None');
[~,~] = system(sprintf('avconv -i /tmp/osiris-temp.avi -c:v libx264 -crf 1 -s %dx%d -b:v 50000k Movies/%s-%s.mp4', aDim(1), aDim(2), sMovieFile, fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

clear i;
clear k;
clear iEnd;
clear iStart;
clear xMin;
clear xMax;
clear aDim;
