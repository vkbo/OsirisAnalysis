
%
% Script to generate an animation of the evolution of the ElectronBeam
%

figMain = figure;
set(figMain, 'Position', [200 200 600 400]);

iStart = 80;
iEnd   = 120;

clear M;

for k=iStart:iEnd
    
    clf;
    i = k-iStart+1;

    % ElectronBeam Density
    stEInfo = fPlotDensity(od, k, 'EB');
    xlim([214,220.5]);
    ylim([-0.6,0.6]);
    caxis([-0.5,0]);

    drawnow;

    M(i) = getframe_nosteal_focus(figMain,[1200 700]);

end % for

movie2avi(M, 'Movies/Temp.avi', 'fps', 2);
[~,~] = system(sprintf('avconv -i Movies/Temp.avi -vcodec msmpeg4v2 -s 1200x700 -b 2000k Movies/AnimElectronBeamDensity-%s.avi', fTimeStamp));
[~,~] = system('rm Movies/Temp.avi');

clear i;
clear k;
clear iEnd;
clear iStart;
