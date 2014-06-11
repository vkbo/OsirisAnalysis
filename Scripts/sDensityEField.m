clear M;
clf;
for i=12:20
    fPlotDensityEField(od, i, 3, 'PB', 'EB');
    axis([182,190,-1.05,1.05]);
    M(i-11) = getframe(gcf);
    %saveas(figure(1), sprintf('Temp/Plot-%d',i),'png');
end % for