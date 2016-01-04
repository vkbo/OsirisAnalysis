
%
%  Function: fGetIndex
% *********************
%  Returns the index on an axis vector corresponding to a value
%

function iIndex = fGetIndex(aVector, dValue)

    iIndex = 0;
    
    if isempty(dValue) || isempty(aVector)
        return;
    end % if

    for i=1:length(aVector)-1
        if dValue >= aVector(1) && dValue < aVector(i+1)
            if dValue-aVector(i) < aVector(i+1)-dValue
                iIndex = i;
                return;
            else
                iIndex = i+1;
                return;
            end % if
        end % if
    end % for
    
    if dValue >= aVector(end-1)-(aVector(end)-aVector(end-1))/2
        iIndex = length(aVector);
    end % if
    
    % Matlab matrix index cannot be less than 1
    if iIndex < 1
        iIndex = 1;
    end % if

end

