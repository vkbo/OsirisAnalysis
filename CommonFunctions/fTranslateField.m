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

    switch(lower(sMode))
        
        case 'standard'
            switch(lower(sInput))

                % E-Fields
                case 'ez'
                    sReturn = 'e1';
                case 'er'
                    sReturn = 'e2';
                case 'eth'
                    sReturn = 'e3';

                % B-Fields
                case 'bz'
                    sReturn = 'b1';
                case 'br'
                    sReturn = 'b2';
                case 'bth'
                    sReturn = 'b3';

            end % switch
        % end case 'standard'
        
        case 'readablecyl'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'E_{\xi}';
                case 'e2'
                    sReturn = 'E_r';
                case 'e3'
                    sReturn = 'E_{\theta}';

                % B-Fields
                case 'b1'
                    sReturn = 'B_{\xi}';
                case 'b2'
                    sReturn = 'B_r';
                case 'b3'
                    sReturn = 'B_{\theta}';

            end % switch
        % end case 'readable'

        case 'readable'
            switch(sInput)
                
                % E-Fields
                case 'e1'
                    sReturn = 'E_{\xi}';
                case 'e2'
                    sReturn = 'E_x';
                case 'e3'
                    sReturn = 'E_y';

                % B-Fields
                case 'b1'
                    sReturn = 'B_{\xi}';
                case 'b2'
                    sReturn = 'B_x';
                case 'b3'
                    sReturn = 'B_y';

            end % switch
        % end case 'readable'
        
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

            end % switch
        % end case 'long'

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

            end % switch
        % end case 'long'

    end % switch

end

