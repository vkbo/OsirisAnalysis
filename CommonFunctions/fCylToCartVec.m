
%
%  Function: Cylindrical to Cartesian Vector
% *******************************************
%

function [vX, vY, vZ] = fCylToCartVec(vR, vT, vZ, aT)
    vX = vR.*cos(aT) - vT.*sin(aT);
    vY = vR.*sin(aT) + vT.*cos(aT);
end
