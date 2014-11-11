%
%  Function: wstd
% ****************
%  Calculates weighted standard deviation by using the var() function that
%  accepts weights as input. Weights must be positive.
%
%  Written by Veronica Berglyd Olsen
%

function dReturn = wstd(aData, aWeights)

    aWeights = aWeights/sum(aWeights);
    dReturn  = sqrt(var(aData, aWeights));

end
