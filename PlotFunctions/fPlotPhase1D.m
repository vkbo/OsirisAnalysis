%
%  Function: fPlotPhase1D
% ************************
%  Plot 1D Phase Data
%
function fPlotPhase1D(oData, iTime, sSpecies, sAxis)

    % Help output

    if nargin == 0
        fprintf('\n');
        fprintf(' Usage: fPlotPhase1D(oData, iTime, sSpecies, sAxis)\n');
        fprintf('\n');
        fprintf(' Input:\n');
        fprintf(' oData    :: OsirisData object\n');
        fprintf(' iTime    :: Which dump to look at\n');
        fprintf(' sSpecies :: Which species to look at\n');
        fprintf(' sAxis    :: Which axis to plot\n');
        fprintf('\n');
        return;
    end % if

    h5Data = oData.Data(iTime, oData.Elements.PHA.(sAxis).(sSpecies));
    
    fig1 = figure(1);
    
    plot(h5Data);

end

