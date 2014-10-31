
function aReturn = fPeak(aVector, aLimits, iInclusive)

    if nargin < 3
        iInclusive = 0;
    end % if

    if nargin < 2
        aLimits = [0.01, 0.01];
    end % if

    iStart = 1;
    iStop  = length(aVector);
    
    [dMax, iMax] = max(aVector);
    
    iLimit = iStop;
    for i=iMax:iStop
        if aVector(i) <= dMax*aLimits(2)
            iLimit = i;
            break;
        end % if
    end % for
    iStop = iLimit;

    iLimit = iStart;
    for i=iStart:iMax
        if aVector(iMax-i+1) <= dMax*aLimits(1)
            iLimit = iMax-i+1;
            break;
        end % if
    end % for
    iStart = iLimit;
    
    aReturn = [iMax, iStart, iStop];
    
end

