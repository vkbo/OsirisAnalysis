
%
%  Function: fAccu1D
% *******************
%  Accumulate weighted data on a grid
%

function [aGrid, aAxis] = fAccu1D(aData, aWeights, iGrid, varargin)

    % Parse Input
    oOpt = inputParser;
    addParameter(oOpt, 'Method', 'Deposit'); % Bins or Deposit
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    dMin = min(aData);
    dMax = max(aData);
    dDel = (dMax-dMin)/(iGrid-1);

    aGrid = zeros(1,iGrid);
    aAxis = linspace(dMin,dMax,iGrid);
    
    if strcmpi(stOpt.Method, 'Deposit')
        aData = (aData-dMin)/dDel;
        for i=1:length(aData)
            iPos = round(aData(i));
            if isnan(iPos)
                continue;
            end % if
            dRem = aData(i)-iPos;
            aGrid(iPos+1) = aGrid(iPos+1) + (1 - abs(dRem))*aWeights(i);
            if dRem > 0 && iPos < iGrid - 1
                aGrid(iPos+2) = aGrid(iPos+2) + abs(dRem)*aWeights(i);
            end % if
            if dRem < 0 && iPos > 0
                aGrid(iPos) = aGrid(iPos) + abs(dRem)*aWeights(i);
            end % if
        end % for
    end % if

    if strcmpi(stOpt.Method, 'Bins')
        for i=1:iGrid-1
            iFind = find(aData >= aAxis(i) & aData < aAxis(i+1));
            if ~isempty(iFind)
                aGrid(i) = sum(aWeights(iFind));
            end % if
        end % for

        iFind = find(aData == aAxis(end));
        if ~isempty(iFind)
            aGrid(end) = sum(aWeights(iFind));
        end % if
    end % if
    
    %stairs(aAxis,aGrid);

end % function
