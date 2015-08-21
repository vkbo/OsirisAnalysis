
%
%  Function: fTranslateField
% ***************************
%  Translates field name to the value the analysis code uses
%

function sReturn = fTranslateField(sInput, sMode)

    % If no mode specified, translate to standard file name format
    if nargin < 2
        sMode = 'Standard';
    end % if
    
    sReturn = lower(sInput);

%--------------------------------------------------------------------------
    
    switch(lower(sMode))
        
        case 'standard'
            switch(lower(sInput))

                % E-Fields
                case 'ez'
                    sReturn = 'e1';
                case 'er'
                    sReturn = 'e2';
                case 'ex'
                    sReturn = 'e2';
                case 'eth'
                    sReturn = 'e3';
                case 'ey'
                    sReturn = 'e3';

                % B-Fields
                case 'bz'
                    sReturn = 'b1';
                case 'br'
                    sReturn = 'b2';
                case 'bx'
                    sReturn = 'b2';
                case 'bth'
                    sReturn = 'b3';
                case 'by'
                    sReturn = 'b3';

                % Current
                case 'jz'
                    sReturn = 'j1';
                case 'jr'
                    sReturn = 'j2';
                case 'jx'
                    sReturn = 'j2';
                case 'jth'
                    sReturn = 'j3';
                case 'jy'
                    sReturn = 'j3';

                % Charge
                case 'q'
                    sReturn = 'charge';

            end % switch
        % end case 'standard'
        
%--------------------------------------------------------------------------
        
        case 'readablecyl'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'E_{z}';
                case 'e2'
                    sReturn = 'E_r';
                case 'e3'
                    sReturn = 'E_{\theta}';

                % B-Fields
                case 'b1'
                    sReturn = 'B_{z}';
                case 'b2'
                    sReturn = 'B_r';
                case 'b3'
                    sReturn = 'B_{\theta}';

                % Current
                case 'j1'
                    sReturn = 'J_{z}';
                case 'j2'
                    sReturn = 'J_r';
                case 'j3'
                    sReturn = 'J_{\theta}';

                % Charge
                case 'q'
                    sReturn = 'Charge';
                case 'charge'
                    sReturn = 'Charge';

            end % switch
        % end case 'readablecyl'

        case 'readable'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'E_{z}';
                case 'e2'
                    sReturn = 'E_x';
                case 'e3'
                    sReturn = 'E_y';

                % B-Fields
                case 'b1'
                    sReturn = 'B_{z}';
                case 'b2'
                    sReturn = 'B_x';
                case 'b3'
                    sReturn = 'B_y';

                % Current
                case 'j1'
                    sReturn = 'J_{z}';
                case 'j2'
                    sReturn = 'J_x';
                case 'j3'
                    sReturn = 'J_y';

                % Charge
                case 'q'
                    sReturn = 'Charge';
                case 'charge'
                    sReturn = 'Charge';

            end % switch
        % end case 'readable'

%--------------------------------------------------------------------------

        case 'notexcyl'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'Ez';
                case 'e2'
                    sReturn = 'Er';
                case 'e3'
                    sReturn = 'Eo';

                % B-Fields
                case 'b1'
                    sReturn = 'Bz';
                case 'b2'
                    sReturn = 'Br';
                case 'b3'
                    sReturn = 'Bo';

                % Current
                case 'j1'
                    sReturn = 'Jz';
                case 'j2'
                    sReturn = 'Jr';
                case 'j3'
                    sReturn = 'Jo';

                % Charge
                case 'q'
                    sReturn = 'Q';
                case 'charge'
                    sReturn = 'Q';

            end % switch
        % end case 'notexcyl'

        case 'notex'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'Ez';
                case 'e2'
                    sReturn = 'Ex';
                case 'e3'
                    sReturn = 'Ey';

                % B-Fields
                case 'b1'
                    sReturn = 'Bz';
                case 'b2'
                    sReturn = 'Bx';
                case 'b3'
                    sReturn = 'By';

                % Current
                case 'j1'
                    sReturn = 'Jz';
                case 'j2'
                    sReturn = 'Jx';
                case 'j3'
                    sReturn = 'Jy';

                % Charge
                case 'q'
                    sReturn = 'Q';
                case 'charge'
                    sReturn = 'Q';

            end % switch
        % end case 'notex'
        
%--------------------------------------------------------------------------

        case 'longcyl'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'Longitudinal E-Field';
                case 'e2'
                    sReturn = 'Radial E-Field';
                case 'e3'
                    sReturn = 'Azimuthal E-Field';

                % B-Fields
                case 'b1'
                    sReturn = 'Longitudinal B-Field';
                case 'b2'
                    sReturn = 'Radial B-Field';
                case 'b3'
                    sReturn = 'Azimuthal B-Field';

                % Current
                case 'j1'
                    sReturn = 'Longitudinal Current';
                case 'j2'
                    sReturn = 'Radial Current';
                case 'j3'
                    sReturn = 'Azimuthal Current';

                % Charge
                case 'q'
                    sReturn = 'Charge';
                case 'charge'
                    sReturn = 'Charge';

            end % switch
        % end case 'long-cyl'

        case 'long'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'Longitudinal E-Field';
                case 'e2'
                    sReturn = 'Horizontal E-Field';
                case 'e3'
                    sReturn = 'Vertical E-Field';

                % B-Fields
                case 'b1'
                    sReturn = 'Longitudinal B-Field';
                case 'b2'
                    sReturn = 'Horizontal B-Field';
                case 'b3'
                    sReturn = 'Vertical B-Field';

                % Current
                case 'j1'
                    sReturn = 'Longitudinal Current';
                case 'j2'
                    sReturn = 'Horizontal Current';
                case 'j3'
                    sReturn = 'Vertical Current';

                % Charge
                case 'q'
                    sReturn = 'Charge';
                case 'charge'
                    sReturn = 'Charge';

            end % switch
        % end case 'long'

%--------------------------------------------------------------------------

        case 'fromlong'
            switch(sInput)
                
                % E-Fields
                case 'Longitudinal E-Field'
                    sReturn = 'e1';
                case 'Horizontal E-Field'
                    sReturn = 'e2';
                case 'Radial E-Field'
                    sReturn = 'e2';
                case 'Vertical E-Field'
                    sReturn = 'e3';
                case 'Azimuthal E-Field'
                    sReturn = 'e3';

                % B-Fields
                case 'Longitudinal B-Field'
                    sReturn = 'b1';
                case 'Horizontal B-Field'
                    sReturn = 'b2';
                case 'Radial B-Field'
                    sReturn = 'b2';
                case 'Vertical B-Field'
                    sReturn = 'b3';
                case 'Azimuthal B-Field'
                    sReturn = 'b3';

                % Current
                case 'Longitudinal Current'
                    sReturn = 'j1';
                case 'Horizontal Current'
                    sReturn = 'j2';
                case 'Radial Current'
                    sReturn = 'j2';
                case 'Vertical Current'
                    sReturn = 'j3';
                case 'Azimuthal Current'
                    sReturn = 'j3';

                % Charge
                case 'Charge'
                    sReturn = 'charge';
                case 'Q'
                    sReturn = 'charge';

            end % switch
        % end case 'long'

    end % switch

end

