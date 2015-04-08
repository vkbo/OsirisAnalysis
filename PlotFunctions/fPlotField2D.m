
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
       fprintf('  FigureSize  :: Default [900 500]\n');
       fprintf('  HideDump    :: Default No\n');
       fprintf('  IsSubplot   :: Default No\n');
       fprintf('  AutoResize  :: Default On\n');
       fprintf('  CAxis       :: Color axis limits\n');
       fprintf('  ShowOverlay :: Default Yes\n');
       fprintf('\n');
       return;
    end % if

    sField = fTranslateField(sField);
    iTime = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
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
    
    if ~isField(sField)
        fprintf(2, 'Error: Non-existent field specified.\n');
        return;
    end % if
    
    sFType = upper(sField(1));

    % Prepare Data

    switch(sFType)
        case 'E'
            oFLD = EField(oData, sField, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
            sBaseUnit = 'eV';
        case 'B'
            oFLD = BField(oData, sField, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
            sBaseUnit = 'T';
    end % switch
    oFLD.Time = iTime;

    if length(stOpt.Limits) == 4
        oFLD.X1Lim = stOpt.Limits(1:2);
        oFLD.X2Lim = stOpt.Limits(3:4);
    end % if
    
    stData = oFLD.Density;

    aData  = stData.Data;
    aZAxis = stData.X1Axis;
    aRAxis = stData.X2Axis;
    dZPos  = stData.ZPos;
    
    dPeak  = max(abs(aData(:)));
    [dTemp, sFUnit] = fAutoScale(dPeak, sBaseUnit);
    dScale = dTemp/dPeak;

    stReturn.X1Axis    = stData.X1Axis;
    stReturn.X2Axis    = stData.X2Axis;
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

    imagesc(aZAxis, aRAxis, aData*dScale);
    set(gca,'YDir','Normal');
    polarmap(jet,0.5);
    %colormap('jet');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;

    %if strcmpi(stOpt.ShowOverlay, 'Yes')
    %    plot(aZAxis, aProjZ, 'White');
    %    h = legend(sBeamCharge, 'Location', 'NE');
    %    set(h,'Box','Off');
    %    set(h,'TextColor', [1 1 1]);
    %    set(findobj(h, 'type', 'line'), 'visible', 'off')
    %end % if

    if strcmpi(oFLD.Coords, 'cylindrical')
        sRType = 'LongCyl';
    else
        sRType = 'Long';
    end % of

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s %s (%s #%d)', fTranslateField(sField,sRType), fPlasmaPosition(oData, iTime), oData.Config.Name, iTime);
    else
        sTitle = sprintf('%s %s', fTranslateField(sField,sRType), fPlasmaPosition(oData, iTime));
    end % if

    title(sTitle);
    xlabel('\xi [mm]');
    ylabel('r [mm]');
    title(hCol,sFUnit);
    
    hold off;
    
    
    % Return

    stReturn.Field = sField;
    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;

end

