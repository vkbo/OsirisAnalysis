
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

function stReturn = fPlotPhase2D(oData, sTime, sSpecies, sAxis1, sAxis2, varargin)

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
    
    sSpecies = fTranslateSpecies(sSpecies);
    iTime    = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'HLim',        []);
    addParameter(oOpt, 'HAuto',       'No');
    addParameter(oOpt, 'VLim',        []);
    addParameter(oOpt, 'VAuto',       'No');
    addParameter(oOpt, 'UseRaw',      'No');
    addParameter(oOpt, 'Scatter',     0);
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

    aAllowed = {'p1','p2','p3','x1','x2','x3'};
    if ~ismember(sAxis1, aAllowed) || ~ismember(sAxis2, aAllowed)
        fprintf(2, 'Error: Unknown axes\n');
        return;
    end % if

    % Data
    oPha      = Phase(oData,sSpecies,'Units','SI');
    oPha.Time = iTime;
    if stOpt.Scatter == 0 && strcmpi(stOpt.UseRaw, 'No')
        stData = oPha.Phase2D(sAxis1,sAxis2,'HLim',stOpt.HLim,'VLim',stOpt.VLim,'HAuto',stOpt.HAuto,'VAuto',stOpt.VAuto);
    else
        if stOpt.Scatter == 0
            stData = oPha.Scatter2D(sAxis1,sAxis2,'HLim',stOpt.HLim,'VLim',stOpt.VLim,'Sample',100000);
        else
            stData = oPha.Scatter2D(sAxis1,sAxis2,'HLim',stOpt.HLim,'VLim',stOpt.VLim,'Sample',stOpt.Scatter);
        end % if
    end % if
    
    if isempty(stData)
        fprintf(2, 'Error: No data.\n');
        return;
    end % if

    aData = stData.Data;

    if strcmpi(stOpt.UseRaw, 'No')
        aData = aData*100;
    else
        dQTot = sum(aData(:));
        [dQVal,sQUnit] = fAutoScale(dQTot,'C');

        dDMax = max(abs(aData(:)));
        [dDVal,sDUnit] = fAutoScale(dDMax,'C');
        aData = aData*dDVal/dDMax;
    end % if
    
    aHAxis = stData.HAxis;
    aVAxis = stData.VAxis;

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

    if stOpt.Scatter == 0
        imagesc(aHAxis,aVAxis,aData);
        set(gca,'YDir','Normal');
        colormap('hot');
        hCol = colorbar();
        if ~isempty(stOpt.CAxis)
            caxis(stOpt.CAxis);
        end % if
    else
        cMap = hot(stData.Count);
        scatter(stData.HData, stData.VData, 5, cMap, 'Filled');
    end % if

    if stOpt.Scatter == 0
        aProjZ = abs(sum(aData));
        aProjZ = 0.15*(aVAxis(end)-aVAxis(1))*aProjZ/max(abs(aProjZ))+aVAxis(1);

        hold on;
        if strcmpi(stOpt.ShowOverlay, 'Yes')
            plot(aHAxis, aProjZ, 'White');
            if strcmpi(stOpt.UseRaw, 'No')
                h = legend(sprintf('Particles: %.2f %%',stData.Ratio*100), 'Location', 'NE');
            else
                h = legend(sprintf('Q_{tot} = %.2f %s',dQVal,sQUnit), 'Location', 'NE');
            end % if
            set(h,'Box','Off');
            set(h,'TextColor', [1 1 1]);
            set(findobj(h, 'type', 'line'), 'visible', 'off')
        end % if
        hold off;
    end % if

    if strcmpi(oPha.Coords, 'cylindrical')
        sRType = 'ReadableCyl';
    else
        sRType = 'Readable';
    end % of

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Phase %s (%s #%d)',fTranslateSpecies(sSpecies,'Readable'),fPlasmaPosition(oData, iTime),oData.Config.Name,iTime);
    else
        sTitle = sprintf('%s Phase %s',fTranslateSpecies(sSpecies,'Readable'),fPlasmaPosition(oData, iTime));
    end % if

    title(sTitle);
    xlabel(sprintf('%s [%s]',fTranslateAxis(sAxis1,sRType),sHUnit));
    ylabel(sprintf('%s [%s]',fTranslateAxis(sAxis2,sRType),sVUnit));

    if stOpt.Scatter == 0
        if strcmpi(stOpt.UseRaw, 'No')
            title(hCol,'%');
        else
            title(hCol,sDUnit);
        end % if
    end % if
    
    % Return

    stReturn.XLim  = xlim;
    stReturn.YLim  = ylim;
    stReturn.CLim  = caxis;

end
