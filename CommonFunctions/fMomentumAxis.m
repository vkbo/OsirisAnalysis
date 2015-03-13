%
%  Function: fMomentumAxis
% *************************
%  Convert axis type to Osiris type
%

function sReturn = fMomentumAxis(sAxis)

    switch(lower(sAxis))
        
        % Longitudinal
        case 'x1'
            sReturn = 'p1';
        case 'p1'
            sReturn = 'p1';
        case 'z'
            sReturn = 'p1';
        case 's'
            sReturn = 'p1';
        case 'l'
            sReturn = 'p1';
        case 'longitudinal'
            sReturn = 'p1';

        % Radial or vertical
        case 'x2'
            sReturn = 'p2';
        case 'p2'
            sReturn = 'p2';
        case 'r'
            sReturn = 'p2';
        case 'radial'
            sReturn = 'p2';
        case 'y'
            sReturn = 'p2';

        % Azimuthal or horizontal
        case 'x3'
            sReturn = 'p3';
        case 'p3'
            sReturn = 'p3';
        case 'x'
            sReturn = 'p3';
        case 'az'
            sReturn = 'p3';
        case 'a'
            sReturn = 'p3';
        case 'th'
            sReturn = 'p3';
        case 'theta'
            sReturn = 'p3';

        otherwise
            sReturn = 'p1';

    end % switch

end

