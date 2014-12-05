%
%  Returns a string that can be used as a field name
%

function sReturn = structname(sInput)

    sReplace = '_';

    sReturn = sInput;
    sReturn = strrep(sReturn, '-', sReplace);
    sReturn = strrep(sReturn, '+', sReplace);
    sReturn = strrep(sReturn, '.', sReplace);
    sReturn = strrep(sReturn, '*', sReplace);
    sReturn = strrep(sReturn, '#', sReplace);

end

