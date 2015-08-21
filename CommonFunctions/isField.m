
%
%  Function: isField
% *******************
%  Checks if field exists
%

function iBool = isField(sField)

    iBool = 0;

    if ismember(sField, {'e1','e2','e3','b1','b2','b3'}) == 1
        iBool = 1;
    end % if

end

