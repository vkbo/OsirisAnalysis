%
%  Function: fLengthScale
% ************************
%  Converts length scale to value

function dScale = fLengthScale(sToUnit, sFromUnit)

    dScale = 1.0;
    
    if nargin < 2
        sFromUnit = 'm';
    end % if

    switch(lower(sFromUnit))
        case 'pm'
            dScale = dScale * 1.0e-12;
        case 'å'
            dScale = dScale * 1.0e-10;
        case 'nm'
            dScale = dScale * 1.0e-9;
        case 'µm'
            dScale = dScale * 1.0e-6;
        case 'mm'
            dScale = dScale * 1.0e-3;
        case 'cm'
            dScale = dScale * 1.0e-2;
        case 'm'
            dScale = dScale * 1.0;
        case 'km'
            dScale = dScale * 1.0e3;
    end % switch

    switch(lower(sToUnit))
        case 'pm'
            dScale = dScale * 1.0e12;
        case 'å'
            dScale = dScale * 1.0e10;
        case 'nm'
            dScale = dScale * 1.0e9;
        case 'µm'
            dScale = dScale * 1.0e6;
        case 'mm'
            dScale = dScale * 1.0e3;
        case 'cm'
            dScale = dScale * 1.0e2;
        case 'm'
            dScale = dScale * 1.0;
        case 'km'
            dScale = dScale * 1.0e-3;
    end % switch

end

