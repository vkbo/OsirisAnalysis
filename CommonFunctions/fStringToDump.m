function iDump = fStringToDump(oData, sString)

    iDump = 0;

    if strcmp(sString, '')
        fprintf('Empty\n');
        iDump = 0;
        return;
    end % if

    if strcmp(sString(end), 'm')
        fprintf('Metres\n');
        iDump = 0;
        return;
    end % if

    if fIsInteger(sString)
        fprintf('Number\n');
        iDump = str2num(sString);
        return;
    end % if

    if strcmpi(sString, 'start')
        iDump = 0;
        return;
    end % if

    if strcmpi(sString, 'end')
        iDump = oData.Elements.FLD.e1.Info.Files - 1;
        return;
    end % if

    if strcmpi(sString, 'pstart')
        dPStart   = oData.Config.Variables.Plasma.PlasmaStart;
        dTimeStep = oData.Config.Variables.Simulation.TimeStep;
        iNDump    = oData.Config.Variables.Simulation.NDump;
        iDump     = floor(dPStart/(dTimeStep*iNDump));
        return;
    end % if

    if strcmpi(sString, 'pend')
        dPEnd     = oData.Config.Variables.Plasma.PlasmaEnd;
        dTimeStep = oData.Config.Variables.Simulation.TimeStep;
        iNDump    = oData.Config.Variables.Simulation.NDump;
        iDump     = floor(dPEnd/(dTimeStep*iNDump));
        return;
    end % if

end

