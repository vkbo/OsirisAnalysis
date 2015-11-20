
%
%  Function: fPlotPhase2D
% ************************
%  Plots 2D Phase Data
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sTime    :: Which dump to look at
%  sSpecies :: Which species to look at
%  sAxis1   :: Which axis to plot
%  sAxis2   :: Which axis to plot
%
%  Options:
% ==========
%  HLim        :: Horizontal axis limits in mm or MeV
%  VLim        :: Vertical axis limits in mm or MeV
%  FigureSize  :: Default [900 500]
%  HideDump    :: Default No
%  IsSubplot   :: Default No
%  AutoResize  :: Default On
%  CAxis       :: Color axis limits
%  ShowOverlay :: Default Yes
%

function stReturn = fPlotPhase2D(oData, sTime, sSpecies, sAxis, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotPhase2D\n');
        fprintf(' ************************\n');
        fprintf('  Plots 2D Phase Data\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sTime    :: Which dump to look at\n');
        fprintf('  sSpecies :: Which species to look at\n');
        fprintf('  sAxis1   :: Which axis to plot\n');
        fprintf('  sAxis2   :: Which axis to plot\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  HLim        :: Horizontal axis limits in mm or MeV\n');
        fprintf('  VLim        :: Vertical axis limits in mm or MeV\n');
        fprintf('  FigureSize  :: Default [900 500]\n');
        fprintf('  HideDump    :: Default No\n');
        fprintf('  IsSubplot   :: Default No\n');
        fprintf('  AutoResize  :: Default On\n');
        fprintf('  CAxis       :: Color axis limits\n');
        fprintf('  ShowOverlay :: Default Yes\n');
        fprintf('\n');
        return;
    end % if
    
    vSpecies = oData.Translate.Lookup(sSpecies,'Species');
    iTime    = oData.StringToDump(num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'HLim',        []);
    addParameter(oOpt, 'VLim',        []);
    addParameter(oOpt, 'FigureSize',  [900 500]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'ShowOverlay', 'Yes');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.HLim) && length(stOpt.HLim) ~= 2
        fprintf(2, 'Error: HLim specified, but must be of dimension 2.\n');
        return;
    end % if
    if ~isempty(stOpt.VLim) && length(stOpt.VLim) ~= 2
        fprintf(2, 'Error: VLim specified, but must be of dimension 2.\n');
        return;
    end % if

    % Data
    oPha      = Phase(oData,vSpecies.Name,'Units','SI');
    oPha.Time = iTime;
    stData    = oPha.Phase2D(sAxis,'HLim',stOpt.HLim,'VLim',stOpt.VLim);
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        return;
    end % if

    aData    = stData.Data*100;
    aHAxis   = stData.HAxis;
    aVAxis   = stData.VAxis;
    vHAxis   = oData.Translate.Lookup(strrep(stData.AxisName{1},'x1','xi'));
    vVAxis   = oData.Translate.Lookup(strrep(stData.AxisName{2},'x1','xi'));
    vDeposit = oData.Translate.Lookup(stData.Deposit);

    % Scale Data
    dHMax = max(abs(aHAxis));
    [dHVal,sHUnit] = fAutoScale(dHMax,stData.AxisUnit{1});
    aHAxis = aHAxis*dHVal/dHMax;

    dVMax = max(abs(aVAxis));
    [dVVal,sVUnit] = fAutoScale(dVMax,stData.AxisUnit{2});
    aVAxis = aVAxis*dVVal/dVMax;

    stReturn.DataSet   = stData.DataSet;
    stReturn.AxisRange = stData.AxisRange;
    stReturn.AxisScale = [dHVal/dHMax dVVal/dVMax];

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

    imagesc(aHAxis,aVAxis,aData);
    set(gca,'YDir','Normal');
    colormap('hot');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    % Overlay
    hold on;
    if strcmpi(stOpt.ShowOverlay, 'Yes')
        aProjZ = abs(sum(aData));
        aProjZ = 0.15*(aVAxis(end)-aVAxis(1))*aProjZ/max(abs(aProjZ))+aVAxis(1);

        plot(aHAxis, aProjZ, 'White');
        h = legend(sprintf('%s: %.2f %%',vDeposit.Full,stData.Ratio*100), 'Location', 'NE');
        set(h,'Box','Off');
        set(h,'TextColor', [1 1 1]);
        set(findobj(h, 'type', 'line'), 'visible', 'off')
    end % if
    hold off;

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Phase %s (%s #%d)',vSpecies.Full,oPha.PlasmaPosition,oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s Phase %s',vSpecies.Full,oPha.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel(sprintf('%s [%s]',vHAxis.Tex,sHUnit));
    ylabel(sprintf('%s [%s]',vVAxis.Tex,sVUnit));
    title(hCol,'%');
    
    % Return

    stReturn.Species = vSpecies.Name;
    stReturn.Axis1   = vHAxis.Name;
    stReturn.Axis2   = vVAxis.Name;
    stReturn.XLim    = xlim;
    stReturn.YLim    = ylim;
    stReturn.CLim    = caxis;

end % function
