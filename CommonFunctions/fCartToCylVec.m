
%
%  Function: Cartesian to Cylindrical Vector
% *******************************************
%

function [vR, vT, vZ] = fCartToCylVec(vX, vY, vZ, aX, aY)
    vR = ( aX.*vX + aY.*vY)./sqrt(aX.^2 + aY.^2);
    vT = (-aY.*vX + aX.*vY)./sqrt(aX.^2 + aY.^2);
end
