
%
%  Function: wmean
% *****************
%  Calculates a weighted mean value. Wights must be positive.
%
%  Written by Veronica Berglyd Olsen
%

function dReturn = wmean(aData, aWeights)

    dReturn = sum(aData.*aWeights)/sum(aWeights);

end
