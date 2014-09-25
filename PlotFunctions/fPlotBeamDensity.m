%
%  Function: fPlotBeamDensity
% ****************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData   :: OsirisData object
%  sTime   :: Time dump
%  sBeam   :: Which beam to look at
%
%  Optional Inputs:
% ==================
%  aLimits :: Axis limits [ZMin, ZMax, RMin, RMax]
%  aCharge :: Charge area [ZRadius, RRadius]
%
%  Outputs:
% ==========
%  None
%

function fPlotBeamDensity(oData, sTime, sBeam, aLimits, aCharge)

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
       fprintf('  Optional Inputs:\n');
       fprintf(' ==================\n');
       fprintf('  aLimits :: Axis limits [ZMin, ZMax, RMin, RMax]\n');
       fprintf('  aCharge :: Charge area [ZRadius, RRadius]\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 4
        aLimits = [];
    end % if

    if nargin < 5
        aCharge = [];
    end % if

    % Check Input

    sBeam = fTranslateSpecies(sBeam);
    iTime = fStringToDump(oData, sTime);
    

    % Set Values
    dZScale = 1e3; % millimetres
    dRScale = 1e3; % millimetres


    % Prepare Data
    
    if length(aLimits) == 4
        aLimits(1:2) = aLimits(1:2)/dZScale;
        aLimits(3:4) = aLimits(3:4)/dRScale;
    end % if

    CH      = Charge(oData, sBeam);
    CH.Time = iTime;
    stData  = CH.Density(aLimits);

    aData   = stData.Data;
    aZAxis  = stData.ZAxis*dZScale;
    aRAxis  = stData.RAxis*dRScale;
    dZeta   = stData.Zeta;
    
    aProjZ  = -abs(sum(aData));
    aProjZ  = 0.15*(aRAxis(end)-aRAxis(1))*aProjZ/max(abs(aProjZ))+aRAxis(end);

    if length(aCharge) == 2
        [~,iZPeak] = max(sum(abs(aData),1));
        [~,iRPeak] = max(sum(abs(aData),2));
        stQTot = CH.BeamCharge([aZAxis(iZPeak)/dZScale, aRAxis(iRPeak)/dZScale, aCharge(1)/dZScale, aCharge(2)/dRScale]);
    else
        stQTot = CH.BeamCharge;
    end % if
    dQ = stQTot.QTotal;

    if dQ < 1.0
        sBeamCharge = sprintf('Q_{tot} = %.2f pC', dQ*1e3);
    else
        sBeamCharge = sprintf('Q_{tot} = %.2f nC', dQ);
    end % if
    

    % Plot

    imagesc(aZAxis, aRAxis, aData);
    colormap(jet);
    colorbar();

    hold on;
    plot(aZAxis, aProjZ, 'White');
    
    h = legend(sBeamCharge, 'Location', 'NE');
    legend(h, 'boxoff');
    set(h,'TextColor', [1 1 1]);
    set(findobj(h, 'type', 'line'), 'visible', 'off')

    if length(aCharge) == 2
        dRX = aZAxis(iZPeak)-aCharge(1);
        dRY = aRAxis(iRPeak)-aCharge(2);
        rectangle('Position',[dRX,dRY,2*aCharge(1),2*aCharge(2)],'Curvature',[1,1],'EdgeColor','White','LineStyle','--');
    end % if

    sTitle = sprintf('%s Density after %0.2f m of Plasma (Dump %d)', sBeam, dZeta, iTime);

    title(sTitle,'FontSize',14);
    xlabel('$$z \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    ylabel('$$r \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    
    hold off;
    
end
