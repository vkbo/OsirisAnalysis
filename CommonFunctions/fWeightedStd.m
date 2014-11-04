%
%  fWeightedStd
% **************
%  Calculates weighted standard deviation by using the var() function that
%  accepts weights as input. Weights must be positive.
%

function dReturn = fWeightedStd(aData, aWeights)

    aWeights = aWeights/sum(aWeights);
    dReturn  = sqrt(var(aData, aWeights));

end
