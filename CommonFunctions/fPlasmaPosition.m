%
%  fPlasmaPosition
% *****************
%  Returns a text representation of simulation position relative to the plasma
%

function sReturn = fPlasmaPosition(oData, iTime)

    sReturn = 'Unknown Position';

    dLFactor = oData.Config.Variables.Convert.SI.LengthFac;
    dTFactor = oData.Config.Variables.Convert.SI.TimeFac;
    iPStart  = fStringToDump(oData, 'PStart');
    iPEnd    = fStringToDump(oData, 'PEnd');
    
    if iTime < iPStart
        sReturn = sprintf('at %0.2f m Before Plasma', (iPStart-iTime)*dTFactor*dLFactor);
    end % if

    if iTime >= iPStart && iTime < iPEnd
        sReturn = sprintf('at %0.2f m Into Plasma', (iTime-iPStart)*dTFactor*dLFactor);
    end % if

    if iTime >= iPEnd
        sReturn = sprintf('at %0.2f m After Plasma', (iTime-iPEnd)*dTFactor*dLFactor);
    end % if

end

