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
        
        case 'readable-cyl'
            switch(sInput)
                case 'e1'
                    sReturn = 'E_{\xi}';
                case 'e2'
                    sReturn = 'E_r';
                case 'e3'
                    sReturn = 'E_{\theta}';
            end % switch
        % end case 'readable'

        case 'readable'
            switch(sInput)
                case 'e1'
                    sReturn = 'E_{\xi}';
                case 'e2'
                    sReturn = 'E_x';
                case 'e3'
                    sReturn = 'E_y';
            end % switch
        % end case 'readable'
        
    end % switch

end

