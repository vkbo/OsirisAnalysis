%
%  Function: fSpaceAxis
% **********************
%  Convert axis type to Osiris type
%

function sReturn = fSpaceAxis(sAxis)

    switch(lower(sAxis))
        
        % Longitudinal
        case 'x1'
            sReturn = 'x1';
        case 'p1'
            sReturn = 'x1';
        case 'z'
            sReturn = 'x1';
        case 's'
            sReturn = 'x1';
        case 'l'
            sReturn = 'x1';
        case 'longitudinal'
            sReturn = 'x1';

        % Radial or vertical
        case 'x2'
            sReturn = 'x2';
        case 'p2'
            sReturn = 'x2';
        case 'r'
            sReturn = 'x2';
        case 'radial'
            sReturn = 'x2';
        case 'y'
            sReturn = 'x2';

        % Azimuthal or horizontal
        case 'x3'
            sReturn = 'x3';
        case 'p3'
            sReturn = 'x3';
        case 'x'
            sReturn = 'x3';
        case 'az'
            sReturn = 'x3';
        case 'a'
            sReturn = 'x3';
        case 'th'
            sReturn = 'x3';
        case 'theta'
            sReturn = 'x3';

        otherwise
            sReturn = 'x1';

    end % switch

end

