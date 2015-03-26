
%
%  Function: fPlotPlasmaDensity
% ******************************
%  Plots density plot
%
%  Inputs:
% =========
%  oData   :: OsirisData object
%  sTime   :: Time dump
%  sPlasma :: Which plasma to look at
%
%  Options:
% ==========
%  Limits       :: Axis limits
%  FigureSize   :: Default [1100 600]
%  HideDump     :: Default No
%  IsSubplot    :: Default No
%  AutoResize   :: Default On
%  CAxis        :: Color axis limits
%  Absolute     :: Use absolute value of charge
%  Overlay[1,2] :: Beam projection overlay
%  Scatter[1,2] :: Beam scatter overlay
%  Sample[1,2]  :: Beam scatter sample size [200]
%  Filter[1,2]  :: Beam scatter filter type: Charge or Random
%

function stReturn = fPlotPlasmaDensity(oData, sTime, sPlasma, varargin)

    % Input/Output

    stReturn = {};

    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fPlotPlasmaDensity\n');
        fprintf(' ******************************\n');
        fprintf('  Plots density plot\n');
        fprintf('\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData   :: OsirisData object\n');
        fprintf('  sTime   :: Time dump\n');
        fprintf('  sPlasma :: Which plasma to look at\n');
        fprintf('\n');
        fprintf('  Options:\n');
        fprintf(' ==========\n');
        fprintf('  Limits       :: Axis limits\n');
        fprintf('  FigureSize   :: Default [1100 600]\n');
        fprintf('  HideDump     :: Default No\n');
        fprintf('  IsSubplot    :: Default No\n');
        fprintf('  AutoResize   :: Default On\n');
        fprintf('  CAxis        :: Color axis limits\n');
        fprintf('  Absolute     :: Use absolute value of charge\n');
        fprintf('  Overlay[1,2] :: Beam projection overlay\n');
        fprintf('  Scatter[1,2] :: Beam scatter overlay\n');
        fprintf('  Sample[1,2]  :: Beam scatter sample size [200]\n');
        fprintf('  Filter[1,2]  :: Beam scatter filter type: Charge or Random\n');
        fprintf('\n');
        return;
    end % if
    
    sPlasma = fTranslateSpecies(sPlasma);
    iTime   = fStringToDump(oData, num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'FigureSize',  [1100 600]);
    addParameter(oOpt, 'HideDump',    'No');
    addParameter(oOpt, 'IsSubPlot',   'No');
    addParameter(oOpt, 'AutoResize',  'On');
    addParameter(oOpt, 'CAxis',       []);
    addParameter(oOpt, 'Absolute',    'Yes');
    addParameter(oOpt, 'Overlay',     '');
    addParameter(oOpt, 'Overlay1',    '');
    addParameter(oOpt, 'Overlay2',    '');
    addParameter(oOpt, 'Scatter',     '');
    addParameter(oOpt, 'Scatter1',    '');
    addParameter(oOpt, 'Scatter2',    '');
    addParameter(oOpt, 'Sample',      200);
    addParameter(oOpt, 'Sample1',     200);
    addParameter(oOpt, 'Sample2',     200);
    addParameter(oOpt, 'Filter',      'Charge');
    addParameter(oOpt, 'Filter1',     'Charge');
    addParameter(oOpt, 'Filter2',     'Charge');
    addParameter(oOpt, 'E1',          []);
    addParameter(oOpt, 'E2',          []);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if
    
    stOLBeam = {};
    if ~isempty(stOpt.Overlay)
        stOLBeam{1} = stOpt.Overlay;
    end % if
    if ~isempty(stOpt.Overlay1)
        stOLBeam{1} = stOpt.Overlay1;
    end % if
    if ~isempty(stOpt.Overlay2)
        stOLBeam{2} = stOpt.Overlay2;
    end % if
    
    stField = {};
    iField = 1;
    if ~isempty(stOpt.E1)
        stField(iField).Name  = 'e1';
        stField(iField).Range = stOpt.E1;
        stField(iField).Color = [0.7 1.0 0.7];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.E2)
        stField(iField).Name  = 'e2';
        stField(iField).Range = stOpt.E2;
        stField(iField).Color = [0.9 0.9 0.7];
        iField = iField + 1;
    end % if

    stSCBeam = {};
    if ~isempty(stOpt.Scatter)
        stSCBeam{1} = stOpt.Scatter;
    end % if
    if ~isempty(stOpt.Scatter1)
        stSCBeam{1} = stOpt.Scatter1;
    end % if
    if ~isempty(stOpt.Scatter2)
        stSCBeam{2} = stOpt.Scatter2;
    end % if
    
    aSample = [];
    if ~isempty(stOpt.Sample)
        aSample(1) = stOpt.Sample;
    end % if
    if ~isempty(stOpt.Sample1)
        aSample(1) = stOpt.Sample1;
    end % if
    if ~isempty(stOpt.Sample2)
        aSample(2) = stOpt.Sample2;
    end % if

    stFilter = {};
    if ~isempty(stOpt.Filter)
        stFilter{1} = stOpt.Filter;
    end % if
    if ~isempty(stOpt.Filter1)
        stFilter{1} = stOpt.Filter1;
    end % if
    if ~isempty(stOpt.Filter2)
        stFilter{2} = stOpt.Filter2;
    end % if
    
    
    % Prepare Data

    oCH      = Charge(oData, sPlasma, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    oCH.Time = iTime;

    if length(stOpt.Limits) == 4
        oCH.X1Lim = stOpt.Limits(1:2);
        oCH.X2Lim = stOpt.Limits(3:4);
    end % if

    stData = oCH.Density;

    aData  = stData.Data;
    aZAxis = stData.X1Axis;
    aRAxis = stData.X2Axis;
    dZPos  = stData.ZPos;

    stReturn.X1Axis    = stData.X1Axis;
    stReturn.X2Axis    = stData.X2Axis;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oCH.AxisFac;
    stReturn.AxisRange = oCH.AxisRange;

    if strcmpi(stOpt.Absolute, 'Yes')
        aData = abs(aData);
    end % if


    %
    %  Plot Plasma Density
    % *********************
    %
    
    if strcmpi(stOpt.IsSubPlot, 'No')
        clf;
        if strcmpi(stOpt.AutoResize, 'On')
            fFigureSize(gcf, stOpt.FigureSize);
        end % if
        set(gcf,'Name',sprintf('Plasma Density (%s #%d)',oData.Config.Name,iTime))
    else
        cla;
    end % if

    imagesc(aZAxis, aRAxis, aData);
    set(gca,'YDir','Normal');
    colormap('gray');
    hCol = colorbar();
    if ~isempty(stOpt.CAxis)
        caxis(stOpt.CAxis);
    end % if

    hold on;
    
    
    %
    %  Plot Scatter Beam
    % *******************
    %

    if length(stSCBeam) == 1
        aCol(1,1:3) = [1.0 0.0 0.0];
    else
        aCol(1,1:3) = [1.0 0.0 0.0];
        aCol(2,1:3) = [0.0 0.0 1.0];
    end % if

    for i=1:length(stSCBeam)

        if ~isempty(stSCBeam(i))

            oBeam      = Charge(oData, stSCBeam{i}, 'Units', 'SI', 'X1Scale', oCH.AxisScale{1}, 'X2Scale', oCH.AxisScale{1});
            oBeam.Time = iTime;

            if length(stOpt.Limits) == 4
                oBeam.X1Lim = stOpt.Limits(1:2);
                oBeam.X2Lim = stOpt.Limits(3:4);
            end % if

            stScatter = oBeam.ParticleSample('Sample', aSample(i), 'Filter', stFilter{i});

            scatter(stScatter.X1,stScatter.X2,stScatter.Area,aCol(i,:),'Filled','HandleVisibility','Off');
            stReturn.Scatter = stScatter;

        end % if
        
    end % for

    %
    %  Overlay Plot Start
    % ********************
    %
    
    iOLNum  = 1;
    stOLLeg = {};

    %
    %  Plot Beam Overlay
    % *******************
    %
    
    if length(stOLBeam) == 1
        aCol(1,1:3) = [1.0 1.0 1.0];
    else
        aCol(1,1:3) = [1.0 0.7 0.7];
        aCol(2,1:3) = [0.7 0.7 1.0];
    end % if

    for i=1:length(stOLBeam)
    
        if ~isempty(stOLBeam(i))
            
            oBeam      = Charge(oData, stOLBeam{i}, 'Units', 'SI', 'X1Scale', oCH.AxisScale{1}, 'X2Scale', oCH.AxisScale{1});
            oBeam.Time = iTime;

            if length(stOpt.Limits) == 4
                oBeam.X1Lim = stOpt.Limits(1:2);
                oBeam.X2Lim = stOpt.Limits(3:4);
            end % if
        
            stBeam = oBeam.Density;
            aProjZ = abs(sum(stBeam.Data));
            aProjZ = 0.15*(aRAxis(end)-aRAxis(1))*aProjZ/max(abs(aProjZ))+aRAxis(1);
            stQTot = oBeam.BeamCharge;

            [dQ, sQUnit] = fAutoScale(stQTot.QTotal,'C');

            plot(aZAxis, aProjZ, 'Color', aCol(i,:));
            stOLLeg{iOLNum} = sprintf('Q_{tot}^{%s} = %.2f %s', fTranslateSpecies(stOLBeam{i},'Short'), dQ, sQUnit);
            iOLNum = iOLNum + 1;

        end % if
    
    end % for

    %
    %  Plot Field Overlay
    % ********************
    %
    
    for i=1:length(stField)
        
        if length(stField(i).Range) == 2
            iS = stField(i).Range(1);
            iA = stField(i).Range(2);
        else
            iS = 3;
            iA = 3;
        end % if
        
        oEF = EField(oData,stField(i).Name,'Units','SI','X1Scale',oCH.AxisScale{1},'X2Scale','m');
        oEF.Time = iTime;
        
        if length(stOpt.Limits) == 4
            oEF.X1Lim = stOpt.Limits(1:2);
        end % if

        stEF    = oEF.Lineout(iS,iA);
        aEFData = 0.15*(aRAxis(end)-aRAxis(1))*stEF.Data/max(abs(stEF.Data));

        [dEne,  sEne]  = fAutoScale(max(abs(stEF.Data)), 'eV');
        [dEVal, sUnit] = fAutoScale(stEF.X2Range(2), 'm');
        dSVal          = stEF.X2Range(1)*dEVal/stEF.X2Range(2);
        
        plot(stEF.X1Axis,aEFData,'Color',stField(i).Color);
        stOLLeg{iOLNum} = sprintf('%s^{%.0f–%.0f %s} < %.1f %s',fTranslateField(stField(i).Name,'ReadableCyl'),dSVal,dEVal,sUnit,dEne,sEne);
        %stOLLeg{iOLNum} = sprintf('%s < %.1f %s',fTranslateField(stField(i).Name,'ReadableCyl'),dEne,sEne);
        iOLNum = iOLNum + 1;
        
    end % if
    
    %
    %  Finish
    % ********
    %

    if ~isempty(stOLLeg)
        
        h = legend(stOLLeg, 'Location', 'NE');
        set(h,'Box','Off');
        set(h,'TextColor', 'White');

        if length(stOLBeam) == 1
            set(findobj(h, 'type', 'line'), 'visible', 'off')
        end % if

    end % if
    
    if strcmpi(oCH.Coords, 'cylindrical')
        sRType = 'ReadableCyl';
    else
        sRType = 'Readable';
    end % of

    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Density %s (%s #%d)', fTranslateSpecies(sPlasma,sRType), fPlasmaPosition(oData, iTime), oData.Config.Name, iTime);
    else
        sTitle = sprintf('%s Density %s', fTranslateSpecies(sPlasma,sRType), fPlasmaPosition(oData, iTime));
    end % if

    title(sTitle);
    xlabel('\xi [mm]');
    ylabel('r [mm]');
    title(hCol,'n_{pe}/n_0');
    
    hold off;
    
    
    %
    %  Return
    % ********
    %

    stReturn.Plasma = sPlasma;
    stReturn.XLim   = xlim;
    stReturn.YLim   = ylim;
    stReturn.CLim   = caxis;
    
end
