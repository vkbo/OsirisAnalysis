
%
%  Function: fStringToDump
% *************************
%  Converts string to Osiris dump number based on simulation configuration
%

function iDump = fStringToDump(oData, vValue)

    iDump   = 0;
    sString = num2str(vValue);

    if strcmp(sString, '')
        iDump = 0;
        return;
    end % if

    if strcmp(sString(end), 'm')
        % Function will translate from metres to closest dump
        % Not yet implemented
        iDump = 0;
        return;
    end % if

    if isInteger(sString)
        iDump = str2num(sString);
        return;
    end % if

    if strcmpi(sString, 'Start')
        iDump = 0;
        return;
    end % if

    if strcmpi(sString, 'End')
        iDump = oData.MSData.MinFiles - 1;
        if iDump < 0
            iDump = 0;
        end % if
        return;
    end % if

    if strcmpi(sString, 'PStart')
        dPStart   = oData.Config.Variables.Plasma.PlasmaStart;
        dTimeStep = oData.Config.Variables.Simulation.TimeStep;
        iNDump    = oData.Config.Variables.Simulation.NDump;
        iDump     = floor(dPStart/(dTimeStep*iNDump));
        if iDump > oData.MSData.MinFiles - 1
            iDump = oData.MSData.MinFiles - 1;
        end % if
        if iDump < 0
            iDump = 0;
        end % if
        return;
    end % if

    if strcmpi(sString, 'PEnd')
        dPEnd     = oData.Config.Variables.Plasma.PlasmaEnd;
        dTimeStep = oData.Config.Variables.Simulation.TimeStep;
        iNDump    = oData.Config.Variables.Simulation.NDump;
        iDump     = floor(dPEnd/(dTimeStep*iNDump));
        if iDump > oData.MSData.MinFiles - 1
            iDump = oData.MSData.MinFiles - 1;
        end % if
        if iDump < 0
            iDump = 0;
        end % if
        return;
    end % if

end

