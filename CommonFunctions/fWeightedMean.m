%
%  fWeightedMean
% ***************
%  Calculates a weighted mean value. Wights must be positive.

function dReturn = fWeightedMean(aData, aWeights)

    dReturn = sum(aData.*aWeights)/sum(aWeights);

end
