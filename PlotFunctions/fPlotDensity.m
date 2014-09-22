%
%  Function: fPlotDensity
% ************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Time dump
%  sSpecies :: Which species to look at
%
%  Outputs:
% ==========
%  None
%

function fPlotDensity(oData, iTime, sSpecies, aZoom)

    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotDensity\n');
       fprintf(' ************************\n');
       fprintf('  Plots density plot\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData    :: OsirisData object\n');
       fprintf('  sTime    :: Time dump\n');
       fprintf('  sSpecies :: Which species to look at\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 4
        aZoom = [];
    end % if

    % Check input variables
    sSpecies = fTranslateSpecies(sSpecies);
    iTMax    = oData.Elements.DENSITY.(sSpecies).charge.Info.Files - 1;
    if iTime > iTMax
        if iTMax == -1
            fprintf('There is no data in this dataset.\n');
            return;
        else
            fprintf('Specified time step is too large. Changed to %d\n', iTMax);
            iTime = iTMax;
        end % if
    end % if
    
    
    CH      = Charge(oData, sSpecies);
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

    sTitle = sprintf('%s Density after %0.2f m of Plasma (Dump %d)', sSpecies, dZeta, iTime);

    title(sTitle,'FontSize',14);
    xlabel('$$z \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    ylabel('$$r \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    
    axis(aZoom);
    
    hold off;
    
end
