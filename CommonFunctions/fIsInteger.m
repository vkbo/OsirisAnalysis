function iBool = fIsInteger(sString)

    aNum = isstrprop(sString, 'digit');

    if sum(aNum) == length(aNum)
        iBool = 1;
    else
        iBool = 0;
    end % if

end

