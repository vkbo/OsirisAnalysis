
%
%  Function: fPlotParticleDensity
% ********************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Time dump
%  sSpecies :: Which species to look at
%
%  Options:
% ==========
%  Data        :: Which data. Default charge
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

function stReturn = fPlotParticleDensity(oData, sTime, sSpecies, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotParticleDensity\n');
        fprintf(' ********************************\n');
        fprintf('  Plots density plot\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sTime    :: Time dump\n');
        fprintf('  sSpecies :: Which species to look at\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Data        :: Which data. Default charge\n');
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
    
    vSpecies = oData.Translate.Lookup(sSpecies,'Species');
    iTime    = oData.StringToDump(num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Data',        'charge');
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
    
    oDN      = Density(oData,vSpecies.Name,'Units','SI','Scale','mm');
    oDN.Time = iTime;

    if length(stOpt.Limits) == 4
        oDN.X1Lim = stOpt.Limits(1:2);
        oDN.X2Lim = stOpt.Limits(3:4);
    end % if
    
    if oData.Config.Simulation.Dimensions == 3
        oDN.SliceAxis = stOpt.SliceAxis;
        oDN.Slice     = stOpt.Slice;
    end % if
    
    vData  = oData.Translate.Lookup(stOpt.Data);
    stData = oDN.Density2D(vData.Name);
    
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
    
    vHAxis = oData.Translate.Lookup(sHAxis);
    vVAxis = oData.Translate.Lookup(sVAxis);
    
    dMax  = max(abs(aData(:)));
    [dSMax,sSUnit] = fAutoScale(dMax,sUnit);
    aData = aData*dSMax/dMax;

    stReturn.XAxis     = stData.HAxis;
    stReturn.YAxis     = stData.VAxis;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oDN.AxisFac;
    stReturn.AxisRange = oDN.AxisRange;
    
    if strcmpi(stOpt.Absolute, 'Yes')
        aData = abs(aData);
    end % if
    
    aProjZ = abs(sum(aData));
    aProjZ = 0.15*(aVAxis(end)-aVAxis(1))*aProjZ/max(abs(aProjZ))+aVAxis(1);

    stQTot = oDN.BeamCharge;
    if ~isempty(stQTot)
        [dQ, sQUnit] = fAutoScale(stQTot.QTotal,'C');
    else
        dQ     = 0.0;
        sQUnit = 'C';
    end % if
    sPCharge = sprintf('Q_{tot} = %.2f %s', dQ, sQUnit);
    

    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Particle Density (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if
    
    imagesc(aHAxis, aVAxis, aData);
    set(gca,'YDir','Normal');
    colormap('hot');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;

    if strcmpi(stOpt.ShowOverlay, 'Yes')
        plot(aHAxis, aProjZ, 'White');
        h = legend(sPCharge, 'Location', 'NE');
        set(h,'Box','Off');
        set(h,'TextColor', [1 1 1]);
        set(findobj(h, 'type', 'line'), 'visible', 'off')
    end % if

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s Density %s (%s #%d)',vSpecies.Full,vData.Full,oDN.PlasmaPosition,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s %s Density %s',vSpecies.Full,vData.Full,oDN.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('%s [mm]',vHAxis.Tex));
    ylabel(sprintf('%s [mm]',vVAxis.Tex));
    title(hCol,sprintf('%s [%s]',sLabel,sSUnit));
    
    hold off;
    
    
    % Return

    stReturn.Beam1 = sSpecies;
    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;
    
end % function
