%
%  Function: fPlotPhase1D
% ************************
%  Plots 1D Phase Data
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  iTime    :: Which dump to look at
%  sSpecies :: Which species to look at
%  sAxis    :: Which axis to plot
%
%  Outputs:
% ==========
%  None
%

function fPlotPhase1D(oData, iTime, sSpecies, sAxis)


    h5Data = oData.Data(iTime, oData.Elements.PHA.(sAxis).(sSpecies));
    
    fig1 = figure(1);
    
    plot(h5Data);

end

