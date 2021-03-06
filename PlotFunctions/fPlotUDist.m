
%
%  Function: fPlotUDist
% **********************
%  Plots udist plot
%
%  Inputs:
% =========
%  oData  :: OsirisData object
%  sTime  :: Time dump
%  sBeam  :: Which beam to look at
%  sUDist :: Which distribution to look at
%
%  Options:
% ==========
%  Limits      :: Axis limits
%  Slice       :: 2D slice coordinate for 3D data
%  SliceAxis   :: 2D slice axis for 3D data
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%  Absolute    :: Use absolute charge. Default No
%

function stReturn = fPlotUDist(oData, sTime, sBeam, sUDist, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotUDist\n');
        fprintf(' **********************\n');
        fprintf('  Plots udist plot\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData :: OsirisData object\n');
        fprintf('  sTime :: Time dump\n');
        fprintf('  sBeam :: Which beam to look at\n');
        fprintf('  sUDist :: Which distribution to look at\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Limits      :: Axis limits\n');
        fprintf('  Slice       :: 2D slice coordinate for 3D data\n');
        fprintf('  SliceAxis   :: 2D slice axis for 3D data\n');
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
    
    vBeam  = oData.Translate.Lookup(sBeam,'Species');
    vUDist = oData.Translate.Lookup(sUDist,{'Ufl','Uth'});
    iTime  = oData.StringToDump(num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Log',         'No');
    addParameter(oOpt, 'Kelvin',      'No');
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'Slice',       0.0);
    addParameter(oOpt, 'SliceAxis',   3);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    addParameter(oOpt, 'Absolute',    'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if

    % Prepare Data
    
    oUD      = UDist(oData,vBeam.Name,'Units','SI','Scale','mm');
    oUD.Time = iTime;

    if length(stOpt.Limits) == 4
        oUD.X1Lim = stOpt.Limits(1:2);
        oUD.X2Lim = stOpt.Limits(3:4);
    end % if
    
    if oData.Config.Simulation.Dimensions == 3
        oUD.SliceAxis = stOpt.SliceAxis;
        oUD.Slice     = stOpt.Slice;
    end % if
    
    stData = oUD.Density2D(vUDist.Name);
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        stReturn.Error = 'No data';
        return;
    end % if

    aData  = stData.Data;
    sUnit  = stData.Unit;
    sLabel = stData.Label;
    aHAxis = stData.HAxis;
    aVAxis = stData.VAxis;
    sHAxis = stData.Axes{1};
    sVAxis = stData.Axes{2};
    dZPos  = stData.ZPos;
    
    if strcmpi(stOpt.Kelvin, 'Yes')
        aData = aData/oData.Config.Constants.EV.Boltzmann;
        sUnit = 'K';
    end % if

    vHAxis = oData.Translate.Lookup(sHAxis);
    vVAxis = oData.Translate.Lookup(sVAxis);
    
    if strcmpi(stOpt.Log, 'Yes')
        aData  = log10(aData);
        %aData(~isfinite(aData)) = 0;
        aData = real(aData);
        sSUnit = sUnit;
    else
        dMax  = max(abs(aData(:)));
        [dSMax,sSUnit] = fAutoScale(dMax,sUnit);
        aData = aData*dSMax/dMax;
    end % if

    stReturn.XAxis     = stData.HAxis;
    stReturn.YAxis     = stData.VAxis;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oUD.AxisFac;
    stReturn.AxisRange = oUD.AxisRange;
    
    if strcmpi(stOpt.ShowOverlay, 'Yes')

        oDN      = Density(oData,vBeam.Name,'Units','SI','Scale','mm');
        oDN.Time = iTime;

        if length(stOpt.Limits) == 4
            oDN.X1Lim = stOpt.Limits(1:2);
            oDN.X2Lim = stOpt.Limits(3:4);
        end % if

        if oData.Config.Simulation.Dimensions == 3
            oDN.SliceAxis = stOpt.SliceAxis;
            oDN.Slice     = stOpt.Slice;
        end % if

        stData = oDN.Density2D('charge');
        aProjZ = abs(sum(stData.Data));
        aProjZ = 0.15*(aVAxis(end)-aVAxis(1))*aProjZ/max(abs(aProjZ))+aVAxis(1);

        stQTot       = oDN.BeamCharge;
        [dQ, sQUnit] = fAutoScale(stQTot.QTotal,'C');
        sBeamCharge  = sprintf('Q_{tot} = %.2f %s', dQ, sQUnit);

    end % if
    

    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Particle UDist (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if
    
    imagesc(aHAxis, aVAxis, aData);
    set(gca,'YDir','Normal');
    aPos = cubehelix([],0.1, 0.5,2,1,[0.0,0.8],[0.0,0.8]);
    aNeg = cubehelix([],0.1,-0.5,2,1,[0.0,0.8],[0.0,0.8]);
    if min(aData(:)) < 0 && ~strcmpi(stOpt.Log, 'Yes')
        dPeak = max(abs(aData(:)));
        caxis([-dPeak dPeak]);
        aMap = [flipud(aNeg); aPos];
    else
        aMap = aPos;
    end % if
    colormap(aMap);
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;

    if strcmpi(stOpt.ShowOverlay, 'Yes')
        plot(aHAxis, aProjZ, 'White');
        h = legend(sBeamCharge, 'Location', 'NE');
        set(h,'Box','Off');
        set(h,'TextColor', [1.0 1.0 1.0]);
        set(findobj(h, 'type', 'line'), 'visible', 'off')
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s %s (%s #%d)',vBeam.Full,vUDist.Full,oUD.PlasmaPosition,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s %s %s',vBeam.Full,vUDist.Full,oUD.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('%s [mm]',vHAxis.Tex));
    ylabel(sprintf('%s [mm]',vVAxis.Tex));
    if strcmpi(stOpt.Log, 'Yes')
        title(hCol,sprintf('log_{10}(%s) [%s]',sLabel,sSUnit));
    else
        title(hCol,sprintf('%s [%s]',sLabel,sSUnit));
    end % if
    
    hold off;
    
    
    % Return

    stReturn.Beam = sBeam;
    stReturn.XLim = xlim;
    stReturn.YLim = ylim;
    stReturn.CLim = caxis;
    
end % function
