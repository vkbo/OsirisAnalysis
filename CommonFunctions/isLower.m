%
%  isLower
% *********
%  Returns 1 if character is lower case, otherwise 0
%

function bReturn = isLower(sChar)

    bReturn = ismember(sChar(1), {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'});

end

