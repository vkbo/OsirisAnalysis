%
%  Function: fTranslateSpecies
% *****************************
%  Translates Species name to the value the analysis code uses
%

function sReturn = fTranslateSpecies(sInput)

    switch(lower(sInput))
        
        % Plasma :: Elctrons
        case 'electrons'
            sReturn = 'PlasmaElectrons';
        case 'pe'
            sReturn = 'PlasmaElectrons';

        % Plasma :: Protons
        case 'pp'
            sReturn = 'PlasmaProtons';

        % Plasma :: Ions
        case 'ions'
            sReturn = 'PlasmaIons';
        case 'pi'
            sReturn = 'PlasmaIons';

        % Beam :: Electrons
        case 'electron_beam'
            sReturn = 'ElectronBeam';
        case 'eb'
            sReturn = 'ElectronBeam';
        case 'e-b'
            sReturn = 'ElectronBeam';

        % Beam :: Positrons
        case 'positron_beam'
            sReturn = 'PositronBeam';
        case 'e+b'
            sReturn = 'PositronBeam';
        case 'ptb'
            sReturn = 'PositronBeam';
        
        % Beam :: Protons
        case 'proton_beam'
            sReturn = 'ProtonBeam';
        case 'pb'
            sReturn = 'ProtonBeam';

        otherwise
            sReturn = sInput;

    end % switch

end

