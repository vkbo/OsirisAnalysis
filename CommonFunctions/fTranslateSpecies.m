%
%  Function: fTranslateSpecies
% *****************************
%  Translates Species name to the value the analysis code uses
%

function sReturn = fTranslateSpecies(sInput)

    switch(lower(sInput))
        case 'electrons'
            sSpecies = 'PlasmaElectrons';
        case 'proton_beam'
            sSpecies = 'ProtonBeam';
        case 'electron_beam'
            sSpecies = 'ElectronBeam';
        otherwise
            sReturn = sInput;
    end % switch

end

