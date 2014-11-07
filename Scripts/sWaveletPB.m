% Settings

iDump = 200;

% Values

dLFactor = od.Config.Variables.Convert.SI.LengthFac;
dZ = dLFactor*680/18000;

% Data

aData  = od.Data(iDump, 'DENSITY', 'charge', 'PB');
aProj  = sum(aData,2);
aXAxis = linspace(0,680*dLFactor, 18000)*1e3;

% Wavelet

[aWL,aS,aC] = wavelet(aProj, sqrt(7)*dZ, 1, 0.02, dZ, 700, 'MORLET', 6);

% Plot

imagesc(aXAxis, aS, real(aWL));
set(gca,'YDir','Normal');
colorbar;
polarmap(128);
caxis([-0.2,0.2]);
%axis([15 315 0 600]);

xlabel('\xi [mm]', 'FontSize', 12);
ylabel('Scale', 'FontSize', 12);
title(sprintf('Wavelet Analysis of Proton Beam at Dump %d', iDump), 'FontSize', 14);