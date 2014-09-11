
%
% Script to generate an animation of the evolution of the ElectronBeam
%

figMain = figure;
set(figMain, 'Position', [200 200 1200 700]);

iStart = 0;
iEnd   = 120;

%xMin   = 213;
%xMax   = 221;
xMin   = 185;
xMax   = 189;

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
    caxis([0, 1e-3]);
    freezeColors;
    
    % ElectronBeam Density
    subplot(2,3,4);
    stEInfo = fPlotDensity(od, k, 'EB');
    title('Electron Beam Density', 'FontSize', 14);
    axis([xMin, xMax, -0.2, 0.2]);

    % ProtonBeam Density
    subplot(2,3,5);
    stPInfo = fPlotDensity(od, k, 'PB');
    title('Proton Beam Density', 'FontSize', 14);
    axis([xMin, xMax, -0.2, 0.2]);

    % E-Field
    subplot(2,3,6);
    fPlotField(od, k, 'e1');
    title('Ez-Field', 'FontSize', 14);
    axis([xMin, xMax, -0.7, 0.7]);
    
    drawnow;
    
    M(i) = getframe_nosteal_focus(figMain,[1200 700]);

end % for

movie2avi(M, 'Movies/Temp.avi', 'fps', 2);
[~,~] = system(sprintf('avconv -i Movies/Temp.avi -vcodec msmpeg4v2 -s 1200x700 -b 2000k Movies/AnimElectronBeam-%s.avi', fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

clear i;
clear k;
clear iEnd;
clear iStart;
clear xMin;
clear xMax;