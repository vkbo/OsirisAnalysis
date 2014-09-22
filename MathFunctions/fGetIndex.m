
function iIndex = fGetIndex(aVector, dValue)

    for i=1:length(aVector)-1
        if dValue >= aVector(1) && dValue < aVector(i+1)
            if dValue-aVector(i) < aVector(i+1)-dValue
                iIndex = i;
                return;
            else
                iIndex = i+1;
                return;
            end % if
    end % for

end

