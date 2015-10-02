%
%  fMathFunc
% ***********
%  Applies an Osiris MathFunc on a vector or a set of vectors
%

function stReturn = fMathFunc(sFunc, aX1, aX2, aX3)

    fprintf('%s\n\n', sFunc);

    iKW = 0;
    sKW = '';
    iPar = 0;

    for c=1:length(sFunc)
        
        sC = sFunc(c);
        
        bOP = isOperator(sC);
        bNM = isDigit(sC);
        bLC = isLower(sC);
        bUC = isUpper(sC);
        bCH = bLC || bUC;
        
        % If the
        if ~iKW && bCH
            sKW = sC;
            iKW = 1;
            continue;
        end % if
        
        if iKW && ~bOP
            sKW = [sKW sC];
        end % if
        
        if bOP
            iKW = 0;
        end % if
        
        if iKW || ~bOP
            continue;
        end % if

        %fprintf('%s on %s\n',sKW,sC);

        switch sKW
            case 'if'
                fprintf('%s at %d\n',sKW,c);
        end % switch

    end % for
    

end

