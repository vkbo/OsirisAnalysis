
%
%  Calculates maximum delta t for given grid resolutions
%

function dReturn = fMaxDeltaT(aRes)

    dReturn = 1/sqrt(2) * 1/sqrt(sum(1./aRes.^2));

end

