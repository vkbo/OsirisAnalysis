%
%  Function: isInteger
% *********************
%  Checks if a string represents an integer
%

function iBool = isInteger(sString)

    aNum = isstrprop(sString, 'digit');

    if sum(aNum) == length(aNum)
        iBool = 1;
    else
        iBool = 0;
    end % if

end
