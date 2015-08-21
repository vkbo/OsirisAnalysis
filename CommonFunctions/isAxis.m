
%
%  Function: isAxis
% *******************
%  Checks if axis exists
%

function bBool = isAxis(sAxis)

    bBool = false;

    if ismember(sAxis, {'x1','x2','x3','p1','p2','p3'})
        bBool = true;
    end % if

end

