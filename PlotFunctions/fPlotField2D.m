
%
%  Function: fPlotField2D
% ************************
%  Plots a field from OsirisData in 2D
%
%  Inputs:
% =========
%  oData  :: OsirisData object
%  sTime  :: Time dump
%  sField :: Which field to look at
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
%

function stReturn = fPlotField2D(oData, sTime, sField, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotField2D\n');
        fprintf(' ************************\n');
        fprintf('  Plots a field from OsirisData in 2D\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData  :: OsirisData object\n');
        fprintf('  sTime  :: Time dump\n');
        fprintf('  sField :: Which field to look at\n');
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
        fprintf('\n');
        return;
    end % if

    vField = oData.Translate.Lookup(sField,'Field');
    iTime  = oData.StringToDump(sTime);

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'Slice',       0.0);
    addParameter(oOpt, 'SliceAxis',   3);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if
    
    if ~vField.isField
        fprintf(2, 'Error: Non-existent field specified.\n');
        return;
    end % if
    
    % Prepare Data

    oFLD = Field(oData, vField.Name, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    oFLD.Time = iTime;
    sBaseUnit = oFLD.FieldUnit;
    
    if length(stOpt.Limits) == 4
        oFLD.X1Lim = stOpt.Limits(1:2);
        oFLD.X2Lim = stOpt.Limits(3:4);
    end % if

    if oData.Config.Simulation.Dimensions == 3
        oFLD.SliceAxis = stOpt.SliceAxis;
        oFLD.Slice     = stOpt.Slice;
    end % if
    
    stData = oFLD.Density2D;

    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        stReturn.Error = 'No data';
        return;
    end % if

    aData  = stData.Data;
    aHAxis = stData.HAxis;
    aVAxis = stData.VAxis;
    sHAxis = stData.Axes{1};
    sVAxis = stData.Axes{2};
    dZPos  = stData.ZPos;

    vHAxis = oData.Translate.Lookup(sHAxis);
    vVAxis = oData.Translate.Lookup(sVAxis);
    
    dPeak  = max(abs(aData(:)));
    [dTemp, sFUnit] = fAutoScale(dPeak, sBaseUnit);
    dScale = dTemp/dPeak;

    stReturn.HAxis     = stData.HAxis;
    stReturn.VAxis     = stData.VAxis;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oFLD.AxisFac;
    stReturn.AxisRange = oFLD.AxisRange;
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Field Density (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if

    imagesc(aHAxis, aVAxis, aData*dScale);
    set(gca,'YDir','Normal');
    polarmap(jet,0.5);
    %colormap('jet');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s (%s #%d)', vField.Full, oFLD.PlasmaPosition, oData.Config.Name, iTime);
    else
        sTitle = sprintf('%s %s', vField.Full, oFLD.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('%s [mm]',vHAxis.Tex));
    ylabel(sprintf('%s [mm]',vVAxis.Tex));
    title(hCol,sFUnit);
    
    hold off;
    
    
    % Return

    stReturn.Field = vField.Name;
    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;

end % function
