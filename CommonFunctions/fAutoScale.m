%
%  Function: fAutoScale
% ************************
%

function [dValue, sUnit] = fAutoScale(dBaseValue, sBaseUnit)

    dValue = dBaseValue;
    sUnit  = sBaseUnit;
    
    if abs(dBaseValue) > 1.0
        if abs(dBaseValue) > 1e18
            dValue = dBaseValue*1e-18;
            sUnit  = strcat('E',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) > 1e15
            dValue = dBaseValue*1e-15;
            sUnit  = strcat('P',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) > 1e12
            dValue = dBaseValue*1e-12;
            sUnit  = strcat('T',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) > 1e9
            dValue = dBaseValue*1e-9;
            sUnit  = strcat('G',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) > 1e6
            dValue = dBaseValue*1e-6;
            sUnit  = strcat('M',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) > 1e3
            dValue = dBaseValue*1e-3;
            sUnit  = strcat('k',sBaseUnit);
            return;
        end % if

    else

        if abs(dBaseValue) < 0.999e-15
            dValue = dBaseValue*1e18;
            sUnit  = strcat('a',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) < 0.999e-12
            dValue = dBaseValue*1e15;
            sUnit  = strcat('f',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) < 0.999e-9
            dValue = dBaseValue*1e12;
            sUnit  = strcat('p',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) < 0.999e-6
            dValue = dBaseValue*1e9;
            sUnit  = strcat('n',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) < 0.999e-3
            dValue = dBaseValue*1e6;
            sUnit  = strcat('µ',sBaseUnit);
            return;
        end % if

        if abs(dBaseValue) < 0.999
            dValue = dBaseValue*1e3;
            sUnit  = strcat('m',sBaseUnit);
            return;
        end % if
        
    end % if

end

