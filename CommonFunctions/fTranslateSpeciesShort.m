%
%  Function: fTranslateSpecies
% *****************************
%  Translates Species name to the value the analysis code uses
%

function sReturn = fTranslateSpecies(sInput)

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

        otherwise
            sReturn = sInput;

    end % switch

end

