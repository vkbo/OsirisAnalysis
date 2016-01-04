
%
%  Function: fAccu2D
% *******************
%  Accumulate weighted data on a grid
%

function [aGrid, aHAxis, aVAxis] = fAccu2D(aData, aWeights, vGrid, varargin)

    % Output
    aGrid  = [];
    aHAxis = [];
    aVAxis = [];

    % Parse Input
    oOpt = inputParser;
    addParameter(oOpt, 'Method', 'Deposit'); % Bins or Deposit
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;
    
    [iR,iC] = size(aData);
    if iC ~= 2
        fprintf(2,'aData must have 2 columns.\n');
        return;
    end % if

    if iR ~= length(aWeights)
        fprintf(2,'aData must have same number of rows as aWeights.\n');
        return;
    end % if
    
    if length(vGrid) == 1
        iGridH = floor(vGrid);
        iGridV = floor(vGrid);
    else
        iGridH = floor(vGrid(1));
        iGridV = floor(vGrid(2));
    end % if

    dMinH = min(aData(:,1));
    dMaxH = max(aData(:,1));
    dDelH = (dMaxH-dMinH)/(iGridH-1);

    dMinV = min(aData(:,2));
    dMaxV = max(aData(:,2));
    dDelV = (dMaxV-dMinV)/(iGridV-1);

    aGrid  = zeros(iGridV,iGridH);
    aHAxis = linspace(dMinH,dMaxH,iGridH);
    aVAxis = linspace(dMinV,dMaxV,iGridV);
    
    if strcmpi(stOpt.Method, 'Deposit')
        aData(:,1) = (aData(:,1)-dMinH)/dDelH;
        aData(:,2) = (aData(:,2)-dMinV)/dDelV;
        for i=1:iR
            iPosH = round(aData(i,1));
            iPosV = round(aData(i,2));
            if isnan(iPosH) || isnan(iPosV)
                continue;
            end % if
            dRemH = aData(i,1)-iPosH;
            dRemV = aData(i,2)-iPosV;
            aGrid(iPosV+1,iPosH+1) = aGrid(iPosV+1,iPosH+1) + 0.5*(1 - abs(dRemH))*aWeights(i);
            aGrid(iPosV+1,iPosH+1) = aGrid(iPosV+1,iPosH+1) + 0.5*(1 - abs(dRemV))*aWeights(i);
            if dRemH > 0 && iPosH < iGridH - 1
                aGrid(iPosV+1,iPosH+2) = aGrid(iPosV+1,iPosH+2) + 0.5*abs(dRemH)*aWeights(i);
            end % if
            if dRemH < 0 && iPosH > 0
                aGrid(iPosV+1,iPosH) = aGrid(iPosV+1,iPosH) + 0.5*abs(dRemH)*aWeights(i);
            end % if
            if dRemV > 0 && iPosV < iGridV - 1
                aGrid(iPosV+2,iPosH+1) = aGrid(iPosV+2,iPosH+1) + 0.5*abs(dRemV)*aWeights(i);
            end % if
            if dRemV < 0 && iPosV > 0
                aGrid(iPosV,iPosH+1) = aGrid(iPosV,iPosH+1) + 0.5*abs(dRemV)*aWeights(i);
            end % if
        end % for
    end % if

    if strcmpi(stOpt.Method, 'Bins')
        for i=1:iGridH-1
            for j=1:iGridV-1
                iFind = find(aData(:,1) >= aHAxis(i) & aData(:,1) < aHAxis(i+1) & aData(:,2) >= aVAxis(j) & aData(:,2) < aVAxis(j+1));
                if ~isempty(iFind)
                    aGrid(j,i) = sum(aWeights(iFind));
                end % if
            end % for
        end % for

        iFind = find(aData(:,1) == aHAxis(end) & aData(:,2) == aVAxis(end));
        if ~isempty(iFind)
            aGrid(end,end) = sum(aWeights(iFind));
        end % if
    end % if

end % function
