function dReturn = fWeightedMean(aData, aWeights)

    dReturn = sum(aData.*aWeights)/sum(aWeights);

end
