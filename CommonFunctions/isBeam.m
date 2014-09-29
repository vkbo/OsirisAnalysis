%
%  Function: isBeam
% ******************
%  Checks if species is a beam speacies
%

function iBool = isBeam(sSpecies)

    iBool = 0;

    if strcmpi(fSpeciesType(sSpecies), 'Beam')
        iBool = 1;
    end % if

end

