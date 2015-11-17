
%
%  Function: fAccu1D
% *******************
%  Accumulate weighted data on a grid
%

function [aGrid, aAxis] = fAccu1D(aData, aWeights, iGrid)

    iGrid = 10;

    dMin = min(aData);
    dMax = max(aData);
    dDel = (dMax-dMin)/(iGrid-1);

    aGrid = zeros(1,iGrid);
    aAxis = linspace(dMin,dMax,iGrid);

    min(aData)
    max(aData)
    aData = (aData-dMin+0.5*dDel)/dDel;
    min(aData)
    max(aData)


end % function
