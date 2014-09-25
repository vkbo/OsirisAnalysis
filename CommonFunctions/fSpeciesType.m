%
%  Function: fSpeciesType
% ************************
%  Returns the species type
%

function sReturn = fSpeciesType(sInput)

    sInput  = fTranslateSpecies(sInput);
    sReturn = 'Unknown';
    
    if strcmpi(sInput(1:6), 'Plasma')
        sReturn = 'Plasma';
    end % if

    if strcmpi(sInput(end-3:end), 'Beam')
        sReturn = 'Beam';
    end % if

end

