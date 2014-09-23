
%
% Script to generate an animation of the evolution of the ElectronBeam
%

figMain = figure;
set(figMain, 'Position', [200 200 1200 700]);

clear M;

iStart = 0;
iEnd   = 110;

xMin   = 213;
xMax   = 221;
%xMin   = 185;
%xMax   = 189;

clear M;

for k=iStart:iEnd
    
    clf;
    i = k-iStart+1;

    % Beam density lineout
    subplot(2,3,[1:2]);
    fPlotDensityEField(od, k, [3,13], 'PB', 'EB');
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
    fPlotDensity(od, k, 'EB', [xMin, xMax, -0.2, 0.2]);
    title('Electron Beam Density', 'FontSize', 14);
    %axis([xMin, xMax, -0.2, 0.2]);

    % ProtonBeam Density
    subplot(2,3,5);
    fPlotDensity(od, k, 'PB', [xMin, xMax, -0.2, 0.2]);
    title('Proton Beam Density', 'FontSize', 14);
    %axis([xMin, xMax, -0.2, 0.2]);

    % E-Field
    subplot(2,3,6);
    fPlotField(od, k, 'e1');
    title('Ez-Field', 'FontSize', 14);
    axis([xMin, xMax, -0.7, 0.7]);
    
    drawnow;
    
    set(figMain, 'PaperPosition', [1 1 1200/96 700/96]);
    set(figMain, 'InvertHardCopy', 'Off');
    print(figMain, '-dtiffnocompression', '-r96', 'Temp/print.tif');
    M(i).cdata    = imread('Temp/print.tif');
    M(i).colormap = [];

end % for

movie2avi(M, 'Movies/Temp.avi', 'fps', 2);
[~,~] = system(sprintf('avconv -i Movies/Temp.avi -s 1200x700 -b:v 5000k Movies/AnimElectronBeam-%s.mp4', fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

clear i;
clear k;
clear iEnd;
clear iStart;
clear xMin;
clear xMax;