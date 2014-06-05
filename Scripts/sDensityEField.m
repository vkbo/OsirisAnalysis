
for i=12:116
    fPlotDensityEField(od, i, 3, 'PB', 'EB');
    axis([183,189,-1.05,1.05]);
    saveas(figure(1), sprintf('Temp/Plot-%d',i),'png');
end % for