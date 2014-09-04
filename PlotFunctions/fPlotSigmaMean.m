
function fPlotSigmaMean(oData, sSpecies)

    sSpecies = fTranslateSpecies(sSpecies); 

    oMom = Momentum(oData, sSpecies);
    
    stData = oMom.SigmaEToEMean('PStart','PEnd');
    
    hold on;
    plot(stData.TimeAxis, stData.Mean, 'blue');
    plot(stData.TimeAxis, stData.Mean+stData.Sigma, 'red--');
    plot(stData.TimeAxis, stData.Mean-stData.Sigma, 'red--');
    xlim([stData.TimeAxis(1),stData.TimeAxis(end)]);
    hold off;

end

