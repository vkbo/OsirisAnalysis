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
    iTime = fStringToDump(oData, num2str(sTime));

    
    % Prepare Data

    CH        = Charge(oData, sBeam);
    CH.Time   = iTime;
    CH.Units  = 'SI';
    CH.ZScale = 'mm';
    CH.RScale = 'mm';

    if length(aLimits) == 4
        CH.ZLim = aLimits(1:2);
        CH.RLim = aLimits(3:4);
    else
        fprintf(2, 'Warning: Limits specified, but must be of dimension 4.\n');
    end % if

    stData    = CH.Density;

    aData   = stData.Data;
    aZAxis  = stData.ZAxis;
    aRAxis  = stData.RAxis;
    dZPos   = stData.ZPos;
    
    aProjZ  = -abs(sum(aData));
    aProjZ  = 0.15*(aRAxis(end)-aRAxis(1))*aProjZ/max(abs(aProjZ))+aRAxis(end);

    if length(aCharge) == 2
        [~,iZPeak] = max(sum(abs(aData),1));
        [~,iRPeak] = max(sum(abs(aData),2));
        stQTot = CH.BeamCharge('Ellipse', [aZAxis(iZPeak), 0, aCharge(1), aCharge(2)]);
    elseif length(aCharge) == 4
        stQTot = CH.BeamCharge('Ellipse', [aCharge(1), aCharge(2), aCharge(3), aCharge(4)]);
    else
        stQTot = CH.BeamCharge;
    end % if
    dQ = stQTot.QTotal;
    
    if abs(dQ) < 1.0
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
    elseif length(aCharge) == 4
        dRX = aCharge(1)-aCharge(3);
        dRY = aCharge(2)-aCharge(4);
        rectangle('Position',[dRX,dRY,2*aCharge(3),2*aCharge(4)],'Curvature',[1,1],'EdgeColor','White','LineStyle','--');
    end % if

    sTitle = sprintf('%s Density after %0.2f m of Plasma (Dump %d)', sBeam, dZPos, iTime);

    title(sTitle,'FontSize',14);
    xlabel('$$\xi \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    ylabel('$$r \;\mbox{[mm]}$$','interpreter','LaTex','FontSize',12);
    
    hold off;
    
end
