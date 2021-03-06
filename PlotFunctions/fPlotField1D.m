
%
%  Function: fPlotField1D
% ************************
%  Plots a field from OsirisData in 1D
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
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%

function stReturn = fPlotField1D(oData, sTime, sField, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotField1D\n');
       fprintf(' ************************\n');
       fprintf('  Plots a field from OsirisData in 1D\n');
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
    addParameter(oOpt, 'Start',       3);
    addParameter(oOpt, 'Average',     3);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 2
        fprintf(2, 'Error: Limits specified, but must be of dimension 2.\n');
        return;
    end % if
    
    if ~vField.isField
        fprintf(2, 'Error: Non-existent field specified.\n');
        return;
    end % if
    
    % Prepare Data

    oFLD = Field(oData,vField.Name,'Units','SI','X1Scale','mm');
    oFLD.Time = iTime;
    sBaseUnit = oFLD.FieldUnit;

    if length(stOpt.Limits) == 2
        oFLD.X1Lim = stOpt.Limits;
    end % if
    
    stData = oFLD.Lineout(stOpt.Start,stOpt.Average);

    aData  = stData.Data;
    aXAxis = stData.HAxis;
    aRange = stData.VRange;
    dZPos  = stData.ZPos;
    
    dPeak  = max(abs(aData(:)));
    [dTemp, sFUnit] = fAutoScale(dPeak, sBaseUnit);
    dScale = dTemp/dPeak;

    stReturn.HAxis     = stData.HAxis;
    stReturn.Range     = stData.VRange;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oFLD.AxisFac;
    stReturn.AxisRange = oFLD.AxisRange;
    
    % Plot
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Field Lineout (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if

    plot(aXAxis, aData*dScale,'Color','Blue');

    hold on;

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s (%s #%d)',vField.Full,oFLD.PlasmaPosition,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s %s',vField.Full,oFLD.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel('\xi [mm]');
    ylabel(sprintf('%s [%s]',vField.Tex,sFUnit));
    xlim([aXAxis(1) aXAxis(end)]);
    
    hold off;
    
    
    % Return

    stReturn.Field = vField.Name;
    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;

end % function
