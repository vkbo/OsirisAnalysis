
%
%  Function: capitalise
% **********************
%  Makes first character upper case and rest lower case
%
%  Written by Veronica Berglyd Olsen
%

function sReturn = capitalise(sString)

    sReturn = sString;

    if ~isempty(sString)
        sReturn = [upper(sString(1)) lower(sString(2:end))];
    end % if

end % function
