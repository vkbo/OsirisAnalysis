
%
%  Function: Cartesian to Cylindrical
% ************************************
%

function [aR, aT, aZ] = fCartToCyl(aX, aY, aZ)
    aR = sqrt(aX.^2 + aY.^2);
    aT = atan2(aY,aX);
end
