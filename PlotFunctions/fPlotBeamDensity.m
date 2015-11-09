
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
%  Options:
% ==========
%  Current     :: Optional current instead of charge
%  Limits      :: Axis limits
%  Charge      :: Calculate charge in ellipse. Two inputs for peak
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%  Absolute    :: Use absolute charge. Default No
%

function stReturn = fPlotBeamDensity(oData, sTime, sBeam, varargin)

    % Input/Output

    stReturn = {};

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
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Current     :: Optional current instead of charge\n');
        fprintf('  Limits      :: Axis limits\n');
        fprintf('  Charge      :: Calculate charge in ellipse. Two inputs for peak\n');
        fprintf('  FigureSize  :: Default [900 500]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  CAxis       :: Color axis limits\n');
        fprintf('  ShowOverlay :: Default Yes\n');
        fprintf('  Absolute    :: Use absolute charge. Default No\n');
        fprintf('\n');
        return;
    end % if
    
    vBeam = Variable(oData,sBeam,'Species');
    iTime = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Current',     '');
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'Charge',      []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    addParameter(oOpt, 'Absolute',    'No');
    addParameter(oOpt, 'TrackPeak',   'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if

    if ~isempty(stOpt.Charge) && (length(stOpt.Charge) ~= 2 || length(stOpt.Charge) ~= 4)
        fprintf(2, 'Error: Charge specified, but must be of dimension 2 (follow peak) or 4.\n');
        return;
    end % if

    
    % Prepare Data
    
    oCH      = Charge(oData, vBeam.Name, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    oCH.Time = iTime;

    if length(stOpt.Limits) == 4
        oCH.X1Lim = stOpt.Limits(1:2);
        oCH.X2Lim = stOpt.Limits(3:4);
    end % if
    
    if isempty(stOpt.Current)
        stData = oCH.Density;
        vData  = Variable(oData,'charge','Quantity');
    else
        stData = oCH.Current(stOpt.Current);
        vData  = Variable(oData,stOpt.Current,'Current');
    end % if
    
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        return;
    end % if

    aData  = stData.Data;
    aZAxis = stData.X1Axis;
    aRAxis = stData.X2Axis;
    dZPos  = stData.ZPos;
    
    if ~isempty(stOpt.Current)
        dMax  = max(abs(aData(:)));
        [dCMax,dCUnit] = fAutoScale(dMax,'A');
        aData = aData*dCMax/dMax;
    end % if

    stReturn.X1Axis    = stData.X1Axis;
    stReturn.X2Axis    = stData.X2Axis;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oCH.AxisFac;
    stReturn.AxisRange = oCH.AxisRange;
    
    if strcmpi(stOpt.Absolute, 'Yes')
        aData = abs(aData);
    end % if
    
    aProjZ = abs(sum(aData));
    aProjZ = 0.15*(aRAxis(end)-aRAxis(1))*aProjZ/max(abs(aProjZ))+aRAxis(1);

    if length(stOpt.Charge) == 2
        [~,iZPeak] = max(sum(abs(aData),1));
        [~,iRPeak] = max(sum(abs(aData),2));
        stQTot = oCH.BeamCharge('Ellipse', [aZAxis(iZPeak), 0, stOpt.Charge(1), stOpt.Charge(2)]);
    elseif length(stOpt.Charge) == 4
        stQTot = oCH.BeamCharge('Ellipse', [stOpt.Charge(1), stOpt.Charge(2), stOpt.Charge(3), stOpt.Charge(4)]);
    else
        stQTot = oCH.BeamCharge;
    end % if
    [dQ, sQUnit] = fAutoScale(stQTot.QTotal,'C');
    sBeamCharge  = sprintf('Q_{tot} = %.2f %s', dQ, sQUnit);
    

    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Beam Density (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if
    
    imagesc(aZAxis, aRAxis, aData);
    set(gca,'YDir','Normal');
    colormap('hot');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;

    if strcmpi(stOpt.ShowOverlay, 'Yes')
        plot(aZAxis, aProjZ, 'White');
        h = legend(sBeamCharge, 'Location', 'NE');
        set(h,'Box','Off');
        set(h,'TextColor', [1 1 1]);
        set(findobj(h, 'type', 'line'), 'visible', 'off')
    end % if

    if length(stOpt.Charge) == 2
        dRX = aZAxis(iZPeak)-stOpt.Charge(1);
        dRY = aRAxis(iRPeak)-stOpt.Charge(2);
        rectangle('Position',[dRX,dRY,2*stOpt.Charge(1),2*stOpt.Charge(2)],'Curvature',[1,1],'EdgeColor','White','LineStyle','--');
    elseif length(stOpt.Charge) == 4
        dRX = aCharge(1)-stOpt.Charge(3);
        dRY = aCharge(2)-stOpt.Charge(4);
        rectangle('Position',[dRX,dRY,2*stOpt.Charge(3),2*stOpt.Charge(4)],'Curvature',[1,1],'EdgeColor','White','LineStyle','--');
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s Density %s (%s #%d)',vBeam.Full,vData.Full,fPlasmaPosition(oData, iTime),oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s %s Density %s',vBeam.Full,vData.Full,fPlasmaPosition(oData, iTime));
    end % if

    title(sTitle);
    xlabel('\xi [mm]');
    ylabel('r [mm]');
    if isempty(stOpt.Current)
        title(hCol,'n_{pe}/n_0');
    else
        title(hCol,sprintf('%s %s',vData.Tex,dCUnit));
    end % if
    
    hold off;
    
    
    % Return

    stReturn.Beam1 = sBeam;
    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;
    
end
