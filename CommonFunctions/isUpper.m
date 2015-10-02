%
%  isUpper
% *********
%  Returns 1 if character is upper case, otherwise 0
%

function bReturn = isUpper(sChar)

    bReturn = ismember(sChar(1), {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});

end

