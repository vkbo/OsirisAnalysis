%
%  Function: fTranslateSpecies
% *****************************
%  Translates Species name to the value the analysis code uses
%

function sReturn = fTranslateSpecies(sInput)

    switch(lower(sInput))
        case 'electrons'
            sReturn = 'PlasmaElectrons';
        case 'proton_beam'
            sReturn = 'ProtonBeam';
        case 'electron_beam'
            sReturn = 'ElectronBeam';
        case 'pe'
            sReturn = 'PlasmaElectrons';
        case 'pp'
            sReturn = 'PlasmaProtons';
        case 'pi'
            sReturn = 'PlasmaIons';
        case 'pb'
            sReturn = 'ProtonBeam';
        case 'eb'
            sReturn = 'ElectronBeam';
        otherwise
            sReturn = sInput;
    end % switch

end

