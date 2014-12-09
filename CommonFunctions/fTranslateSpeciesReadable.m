%
%  Function: fTranslateSpeciesReadable
% *************************************
%  Translates Species name to print in titles
%

function sReturn = fTranslateSpecies(sInput)

    switch(sInput)
        
        case 'PlasmaElectrons'
            sReturn = 'Plasma Electron';
        case 'PlasmaProtons'
            sReturn = 'Plasma Proton';
        case 'PlasmaIons'
            sReturn = 'Plasma Ions';
        case 'ElectronBeam'
            sReturn = 'Electron Beam';
        case 'PositronBeam'
            sReturn = 'Positron Beam';
        case 'ProtonBeam'
            sReturn = 'Proton Beam';

        otherwise
            sReturn = sInput;

    end % switch

end

