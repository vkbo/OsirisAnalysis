%
%  Function: fPlotBeamDensity
% ****************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData :: OsirisData object
%  sTime :: Time dump
%  sBeam :: Which beam to look at
%
%  Outputs:
% ==========
%  None
%

function fPlotBeamDensity(oData, sTime, sBeam, aZoom)

    % Check Arguments

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotBeamDensity\n');
       fprintf(' ****************************\n');
       fprintf('  Plots density plot\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData :: OsirisData object\n');
       fprintf('  sTime :: Time dump\n');
       fprintf('  sBeam :: Which beam to look at\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 4
        aZoom = [];
    end % if

    % Check Input

    sBeam = fTranslateSpecies(sBeam);
    iTime = fStringToDump(oData, sTime);
    

    % Prepare Data
    
    CH      = Charge(oData, sBeam);
    CH.Time = iTime;
    stData  = CH.Density;
    stQTot  = CH.BeamCharge;
    
    aData   = stData.Data;
    aXAxis  = stData.ZAxis*1e3;
    aYAxis  = stData.RAxis*1e3;
    dZeta   = stData.Zeta;
    dQ      = stQTot.QTotal;
    
    if length(aZoom) ~= 4
        aZoom = [aXAxis(1), aXAxis(length(aXAxis)), aYAxis(1), aYAxis(length(aYAxis))];
    end % if

    aProjZ  = -abs(sum(aData));
    aProjZ  = 0.15*(aZoom(4)-aZoom(3))*aProjZ/max(abs(aProjZ(fGetIndex(aXAxis, aZoom(1)):fGetIndex(aXAxis, aZoom(2)))))+aZoom(4);

    if dQ < 1.0
        sBeamCharge = sprintf('Q_{tot} = %.2f pC', dQ*1e3);
    else
        sBeamCharge = sprintf('Q_{tot} = %.2f nC', dQ);
    end % if
    

    % Plot

    imagesc(aXAxis, aYAxis, aData);
    colormap(jet);
    colorbar();

    hold on;
    plot(aXAxis, aProjZ, 'White');
    
    h = legend(sBeamCharge, 'Location', 'NE');
    legend(h, 'boxoff');
    set(h,'TextColor', [1 1 1]);
    set(findobj(h, 'type', 'line'), 'visible', 'off')

    sTitle = sprintf('%s Density after %0.2f m of Plasma (Dump %d)', sBeam, dZeta, iTime);

    title(sTitle,'FontSize',14);
    xlabel('$$z \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    ylabel('$$r \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    
    axis(aZoom);
    
    hold off;
    
end
