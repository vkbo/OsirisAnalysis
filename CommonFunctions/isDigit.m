%
%  isDigit
% *********
%  Returns 1 if character is a digit, otherwise 0
%

function bReturn = isDigit(sChar)

    bReturn = ismember(sChar(1), {'0','1','2','3','4','5','6','7','8','9'});

end

