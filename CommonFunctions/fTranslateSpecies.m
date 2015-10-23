%
%  Function: fTranslateSpecies
% *****************************
%  Translates Species name to the value the analysis code uses
%

function sReturn = fTranslateSpecies(sInput, sMode)

    % If no mode specified, translate to standard file name format
    if nargin < 2
        sMode = 'Standard';
    end % if
    
    sReturn = sInput;

    switch(lower(sMode))
        
        case 'standard'
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

            end % switch
        % end case 'standard'
        
        case 'readable'
            switch(sInput)
                case 'PlasmaElectrons'
                    sReturn = 'Plasma Electron';
                case 'PlasmaProtons'
                    sReturn = 'Plasma Proton';
                case 'PlasmaIons'
                    sReturn = 'Plasma Ion';
                case 'ElectronBeam'
                    sReturn = 'Electron Beam';
                case 'PositronBeam'
                    sReturn = 'Positron Beam';
                case 'ProtonBeam'
                    sReturn = 'Proton Beam';

            end % switch
        % end case 'readable'
        
        case 'short'
            switch(lower(sInput))

                % Plasma :: Elctrons
                case 'electrons'
                    sReturn = 'PE';
                case 'plasmaelectrons'
                    sReturn = 'PE';

                % Plasma :: Protons
                case 'plasmaprotons'
                    sReturn = 'PP';

                % Plasma :: Ions
                case 'ions'
                    sReturn = 'PI';
                case 'plasmaions'
                    sReturn = 'PI';

                % Beam :: Electrons
                case 'electron_beam'
                    sReturn = 'EB';
                case 'electronbeam'
                    sReturn = 'EB';

                % Beam :: Positrons
                case 'positron_beam'
                    sReturn = 'PtB';
                case 'positronbeam'
                    sReturn = 'PtB';

                % Beam :: Protons
                case 'proton_beam'
                    sReturn = 'PB';
                case 'protonbeam'
                    sReturn = 'PB';

            end % switch
        % end case 'short'
        
    end % switch

end

