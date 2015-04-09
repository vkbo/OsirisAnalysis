
%
%  Function: fTranslateAxis
% **************************
%  Translates axis name to the value the analysis code uses
%

function sReturn = fTranslateAxis(sInput, sMode)

    % If no mode specified, translate to standard file name format
    if nargin < 2
        sMode = 'Standard';
    end % if
    
    sReturn = lower(sInput);

%--------------------------------------------------------------------------
    
    switch(lower(sMode))
        
        case 'standard'
            switch(lower(sInput))

                % X Axes
                case 'z'
                    sReturn = 'x1';
                case 'r'
                    sReturn = 'x2';
                case 'x'
                    sReturn = 'x2';
                case 'th'
                    sReturn = 'x3';
                case 'y'
                    sReturn = 'x3';

                % P Axes
                case 'pz'
                    sReturn = 'p1';
                case 'pr'
                    sReturn = 'p2';
                case 'px'
                    sReturn = 'p2';
                case 'pth'
                    sReturn = 'p3';
                case 'py'
                    sReturn = 'p3';

            end % switch
        % end case 'standard'
        
%--------------------------------------------------------------------------
        
        case 'readablecyl'
            switch(sInput)
                
                % X Axes
                case 'x1'
                    sReturn = '\xi';
                case 'x2'
                    sReturn = 'r';
                case 'x3'
                    sReturn = '\theta';

                % P Axes
                case 'p1'
                    sReturn = 'p_{\xi}';
                case 'p2'
                    sReturn = 'p_r';
                case 'p3'
                    sReturn = 'p_{\theta}';

            end % switch
        % end case 'readablecyl'

        case 'readable'
            switch(sInput)
                
                % X Axes
                case 'x1'
                    sReturn = 'z';
                case 'x2'
                    sReturn = 'x';
                case 'x3'
                    sReturn = 'y';

                % P Axes
                case 'p1'
                    sReturn = 'p_z';
                case 'p2'
                    sReturn = 'p_x';
                case 'p3'
                    sReturn = 'p_y';

            end % switch
        % end case 'readable'

%--------------------------------------------------------------------------

        case 'notexcyl'
            switch(sInput)
                
                % X Axes
                case 'x1'
                    sReturn = 'z';
                case 'x2'
                    sReturn = 'r';
                case 'x3'
                    sReturn = 'o';

                % P Axes
                case 'p1'
                    sReturn = 'Pz';
                case 'p2'
                    sReturn = 'Pr';
                case 'p3'
                    sReturn = 'Po';

            end % switch
        % end case 'notexcyl'

        case 'notex'
            switch(sInput)
                
                % X Axes
                case 'x1'
                    sReturn = 'z';
                case 'x2'
                    sReturn = 'x';
                case 'x3'
                    sReturn = 'y';

                % P Axes
                case 'p1'
                    sReturn = 'Pz';
                case 'p2'
                    sReturn = 'Px';
                case 'p3'
                    sReturn = 'Py';
            end % switch
        % end case 'notex'
        
%--------------------------------------------------------------------------

        case 'longcyl'
            switch(sInput)
                
                % X Axes
                case 'x1'
                    sReturn = 'Longitudinal Axis';
                case 'x2'
                    sReturn = 'Radial Axis';
                case 'x3'
                    sReturn = 'Azimuthal Axis';

                % P Axes
                case 'p1'
                    sReturn = 'Longitudinal Momentum';
                case 'p2'
                    sReturn = 'Radial Momentum';
                case 'p3'
                    sReturn = 'Azimuthal Momentum';

            end % switch
        % end case 'long-cyl'

        case 'long'
            switch(sInput)
                
                % X Axes
                case 'x1'
                    sReturn = 'Longitudinal Axis';
                case 'x2'
                    sReturn = 'Horizontal Axis';
                case 'x3'
                    sReturn = 'Vertical Axis';

                % P Axes
                case 'p1'
                    sReturn = 'Longitudinal Momentum';
                case 'p2'
                    sReturn = 'Horizontal Momentum';
                case 'p3'
                    sReturn = 'Vertical Momentum';

            end % switch
        % end case 'long'

%--------------------------------------------------------------------------

        case 'fromlong'
            switch(sInput)
                
                % X Axes
                case 'Longitudinal Axis'
                    sReturn = 'x1';
                case 'Horizontal Axis'
                    sReturn = 'x2';
                case 'Radial Axis'
                    sReturn = 'x2';
                case 'Vertical Axis'
                    sReturn = 'x3';
                case 'Azimuthal Axis'
                    sReturn = 'x3';

                % P Axes
                case 'Longitudinal Momentum'
                    sReturn = 'p1';
                case 'Horizontal Momentum'
                    sReturn = 'p2';
                case 'Radial Momentum'
                    sReturn = 'p2';
                case 'Vertical Momentum'
                    sReturn = 'p3';
                case 'Azimuthal Momentum'
                    sReturn = 'p3';

            end % switch
        % end case 'long'

    end % switch

end

