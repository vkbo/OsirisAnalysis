%
%  Function: fRawAxisToIndex
% ***************************
%  Returns index value of axis in RAW output
%
%  Inputs:
% =========
%  sAxis :: Axis label
%
%  Outputs:
% ==========
%  iAxis :: Axis index
%

function iAxis = fRawAxisToIndex(sAxis)

    switch(sAxis)
        case 'x1'
            iAxis = 1;
        case 'x2'
            iAxis = 2;
        case 'x3'
            iAxis = 3;
        case 'p1'
            iAxis = 4;
        case 'p2'
            iAxis = 5;
        case 'p3'
            iAxis = 6;
        case 'ene'
            iAxis = 7;
        case 'energy'
            iAxis = 7;
        case 'q'
            iAxis = 8;
        case 'charge'
            iAxis = 8;
        case 'tag1'
            iAxis = 9;
        case 'tag2'
            iAxis = 10;
        otherwise
            iAxis = 0;
    end % switch

end

