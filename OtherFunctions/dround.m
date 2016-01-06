
%
%  Function: dround
% ******************
%  Rounds a number to a specific number of decimal points.
%
%  Written by Veronica Berglyd Olsen
%

function dReturn = dround(dNumber, dPrecision)

    dReturn = round(dNumber*10^dPrecision)/10^dPrecision;

end

