%
%  Function: fPlotRawHist
% ************************
%  Plot a historgram of raw data
%

function aHist = fPlotRawHist(oData, iTime, sSpecies, sAxis, iBinSize)

    % Help output

    if nargin == 0
        fprintf('\n');
        fprintf(' Usage: fPlotRawHist(oData, iTime, sSpecies, sAxis)\n');
        fprintf('\n');
        fprintf(' Input:\n');
        fprintf(' oData    :: OsirisData object\n');
        fprintf(' iTime    :: Which dump to look at\n');
        fprintf(' sSpecies :: Which species to look at\n');
        fprintf(' sAxis    :: Which axis to look at: x[123] or p[123]\n');
        fprintf(' iBinSize :: Size of bins in plot\n');
        fprintf('\n');
        fprintf(' Output:\n');
        fprintf(' None\n');
        fprintf('\n');
        return;
    end % if
    
    if nargin < 5
        iBinSize = 1;
    end % if
    

    % Extract simulation variables
    
    dTFactor   = oData.Config.Variables.Convert.SI.TimeFac;
    dBoxX1Max  = oData.Config.Variables.Simulation.BoxX1Max;
    iBoxNX1    = oData.Config.Variables.Simulation.BoxNX1;


    % Data extraction
    
    h5Data = oData.Data(iTime, oData.Elements.RAW.(sSpecies));

    dOffset  = iTime*dTFactor;
    dNZScale = iBoxNX1 / dBoxX1Max;

    aQ = h5Data(:,8);
    
    switch(sAxis)
        case 'x1'
            aData = round(double(dNZScale).*(h5Data(:,1)-dOffset));
        case 'x2'
            aData = double(dNZScale).*(h5Data(:,2));
        case 'x3'
            aData = double(dNZScale).*(h5Data(:,3));
        case 'p1'
            aData = h5Data(:,4);
        case 'p2'
            aData = h5Data(:,5);
        case 'p3'
            aData = h5Data(:,6);
        otherwise
            fprintf('Error: Unknown RAW data column.\n');
            return;
    end % switch
    
    aHist = accumarray(aData,aQ);
    
    fprintf('Min: %d\n', min(aData));
    fprintf('Max: %d\n', max(aData));
    
    fig1 = figure(1);
    %hist(aHist, 200);
    bar(aHist,iBinSize);

end

