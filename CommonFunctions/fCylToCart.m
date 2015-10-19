
%
%  Function: Cylindrical to Cartesian
% ************************************
%

function [aX, aY, aZ] = fCylToCart(aR, aT, aZ)
    aX = aR.*cos(aT);
    aY = aR.*sin(aT);
end
