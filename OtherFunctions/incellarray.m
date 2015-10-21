
%
%  Function: incellarray
% ***********************
%  Check if string exists in cell array
%
%  Written by Veronica Berglyd Olsen
%

function [bReturn, iIndex] = incellarray(sValue, stArray)

    bReturn = 0;
    iIndex  = 0;

    for i=1:length(stArray)
        if strcmpi(sValue, stArray{i})
            bReturn = 1;
            iIndex  = i;
        end % if
    end % for

end

