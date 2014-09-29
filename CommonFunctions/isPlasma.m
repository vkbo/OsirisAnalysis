%
%  Function: isPlasma
% ********************
%  Checks if species is a plasma species
%

function iBool = isPlasma(sSpecies)

    iBool = 0;

    if strcmpi(fSpeciesType(sSpecies), 'Plasma')
        iBool = 1;
    end % if

end

