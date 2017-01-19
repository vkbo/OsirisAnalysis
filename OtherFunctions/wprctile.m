%
%  External Code: wprctile
% *************************
%

function dReturn = wprctile(aX, dP, aW)

    if length(aX) ~= length(aW)
        fprintf('Error: Data and weights must be the same length.\n')
        return
    end % if
    
    if dP < 0 || dP > 100
        fprintf('Error: Percentile must be between 0 and 100.\n')
        return
    end % if
    
    dP = dP/100;
    
    [~, aI] = sort(aX);
    
    aW = abs(aW(aI));
    aC = cumsum(aW)/sum(aW);
    aU = find(aC >= dP);
    iU = aU(1);
    aU = [];
    
    if iU == 1 || iU == length(aX)
        dReturn = aX(iU);
    else
        dD = aC(iU)-aC(iU-1);
        dR = (aC(iU)-dP)/dD;
        dReturn = aX(iU)-(aX(iU)-aX(iU-1))*dR;
    end % if
        
end % function
