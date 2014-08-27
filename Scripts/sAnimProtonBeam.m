
%
% Script to generate an animation of the evolution of the ElectronBeam
%

figMain = figure;
set(figMain, 'Position', [200 200 1200 700]);

iStart = 0;
iEnd   = 122;

xMin   = 0;
xMax   = 320;

clear M;

for k=iStart:iEnd
    
    clf;
    i = k-iStart+1;

    % Beam density lineout
    subplot(2,6,[1:4]);
    fPlotDensityEField(od, k, [3, 22], 'PB', '', 'e1');
    axis([xMin, xMax, -1.05, 1.05]);
    
    % Proton Beam x1p1
    subplot(2,6,[5:6]);
    colormap(gray);
    fPlotPhase2D(od, k, 'PB', 'x1', 'p1');
    title('Proton Beam x1p1', 'FontSize', 14);
    axis([xMin, xMax, 380, 420]);
    caxis([0, 1e-3]);
    freezeColors;
    
    % ProtonBeam Density
    subplot(2,6,[7:8]);
    stPInfo = fPlotDensity(od, k, 'PB');
    title('Proton Beam Density', 'FontSize', 14);
    axis([xMin, xMax, -0.2, 0.2]);

    % E-Field
    subplot(2,6,[9:10]);
    fPlotField(od, k, 'e1');
    title('Ez-Field', 'FontSize', 14);
    axis([xMin, xMax, -0.7, 0.7]);

    % E-Field
    subplot(2,6,[11:12]);
    fPlotField(od, k, 'e2');
    title('Er-Field', 'FontSize', 14);
    axis([xMin, xMax, -2, 2]);
    
    drawnow;
    
    M(i) = getframe_nosteal_focus(figMain,[1200 700]);

end % for

movie2avi(M, 'Movies/Temp.avi', 'fps', 2);
[~,~] = system(sprintf('avconv -i Movies/Temp.avi -vcodec msmpeg4v2 -s 1200x700 -b 2000k Movies/AnimProtonBeam-%s.avi', fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

clear i;
clear k;
clear iEnd;
clear iStart;
clear xMin;
clear xMax;