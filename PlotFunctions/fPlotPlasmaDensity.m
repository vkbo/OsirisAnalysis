
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
%  Limits     :: Axis limits
%  Slice      :: 2D slice coordinate for 3D data
%  SliceAxis  :: 2D slice axis for 3D data
%  FigureSize :: Default [900 500]
%  HideDump   :: Default No
%  IsSubplot  :: Default No
%  AutoResize :: Default On
%  CAxis      :: Color axis limits
%  Absolute   :: Use absolute value of charge
%  Overlay1/2 :: Beam projection overlay
%  Scatter1/2 :: Beam scatter overlay
%  Sample1/2  :: Beam scatter sample size [200]
%  Filter1/2  :: Beam scatter filter type: Charge, Random, WRandom or W2Random
%  E1/2/3     :: E-field overlay range average over [Start, Count]
%  W1/2/3     :: Wakefield overlay range average over [Start, Count]
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
        fprintf('  Density    :: Which plasma data to plot\n');
        fprintf('  Limits     :: Axis limits\n');
        fprintf('  Slice      :: 2D slice coordinate for 3D data\n');
        fprintf('  SliceAxis  :: 2D slice axis for 3D data\n');
        fprintf('  GridDiag   :: Options for grid diagnostics data.\n');
        fprintf('  FigureSize :: Default [900 500]\n');
        fprintf('  HideDump   :: Default No\n');
        fprintf('  IsSubplot  :: Default No\n');
        fprintf('  AutoResize :: Default On\n');
        fprintf('  CAxis      :: Color axis limits\n');
        fprintf('  Absolute   :: Use absolute value of charge\n');
        fprintf('  Overlay1/2 :: Beam projection overlay\n');
        fprintf('  Scatter1/2 :: Beam scatter overlay\n');
        fprintf('  Sample1/2  :: Beam scatter sample size [200]\n');
        fprintf('  Filter1/2  :: Beam scatter filter type: Charge, Random, WRandom or W2Random\n');
        fprintf('  E1/2/3     :: E-field overlay range average over [Start, Count]\n');
        fprintf('  B1/2/3     :: B-field overlay range average over [Start, Count]\n');
        fprintf('  W1/2/3     :: Wakefield overlay range average over [Start, Count]\n');
        fprintf('\n');
        return;
    end % if
    
    vPlasma = oData.Translate.Lookup(sPlasma,'Plasma');
    iTime   = oData.StringToDump(num2str(sTime));

    oOpt = inputParser;
    addParameter(oOpt, 'Density',     'charge');
    addParameter(oOpt, 'Limits',      []);
    addParameter(oOpt, 'Slice',       0.0);
    addParameter(oOpt, 'SliceAxis',   3);
    addParameter(oOpt, 'GridDiag',    {});
    addParameter(oOpt, 'FigureSize',  [900 500]);
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
    addParameter(oOpt, 'E3',          []);
    addParameter(oOpt, 'B1',          []);
    addParameter(oOpt, 'B2',          []);
    addParameter(oOpt, 'B3',          []);
    addParameter(oOpt, 'W1',          []);
    addParameter(oOpt, 'W2',          []);
    addParameter(oOpt, 'W3',          []);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    if ~isempty(stOpt.Limits) && length(stOpt.Limits) ~= 4
        fprintf(2, 'Error: Limits specified, but must be of dimension 4.\n');
        return;
    end % if
    
    stOLBeam = {};
    if ~isempty(stOpt.Overlay)
        vTemp = oData.Translate.Lookup(stOpt.Overlay,'Species');
        stOLBeam{1} = vTemp.Name;
    end % if
    if ~isempty(stOpt.Overlay1)
        vTemp = oData.Translate.Lookup(stOpt.Overlay1,'Species');
        stOLBeam{1} = vTemp.Name;
    end % if
    if ~isempty(stOpt.Overlay2)
        vTemp = oData.Translate.Lookup(stOpt.Overlay2,'Species');
        stOLBeam{2} = vTemp.Name;
    end % if
    
    stField = {};
    iField = 1;
    if ~isempty(stOpt.E1)
        stField(iField).Name  = 'e1';
        stField(iField).Type  = 1;
        stField(iField).Range = stOpt.E1;
        stField(iField).Color = [0.7 1.0 0.7];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.E2)
        stField(iField).Name  = 'e2';
        stField(iField).Type  = 1;
        stField(iField).Range = stOpt.E2;
        stField(iField).Color = [0.9 0.9 0.7];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.E3)
        stField(iField).Name  = 'e3';
        stField(iField).Type  = 1;
        stField(iField).Range = stOpt.E3;
        stField(iField).Color = [0.9 0.7 0.7];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.B1)
        stField(iField).Name  = 'b1';
        stField(iField).Type  = 1;
        stField(iField).Range = stOpt.B1;
        stField(iField).Color = [0.2 1.0 0.2];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.B2)
        stField(iField).Name  = 'b2';
        stField(iField).Type  = 1;
        stField(iField).Range = stOpt.B2;
        stField(iField).Color = [0.9 0.9 0.2];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.B3)
        stField(iField).Name  = 'b3';
        stField(iField).Type  = 1;
        stField(iField).Range = stOpt.B3;
        stField(iField).Color = [0.9 0.2 0.2];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.W1)
        stField(iField).Name  = 'w1';
        stField(iField).Type  = 2;
        stField(iField).Range = stOpt.W1;
        stField(iField).Color = [0.7 1.0 1.0];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.W2)
        stField(iField).Name  = 'w2';
        stField(iField).Type  = 2;
        stField(iField).Range = stOpt.W2;
        stField(iField).Color = [1.0 0.7 0.5];
        iField = iField + 1;
    end % if
    if ~isempty(stOpt.W3)
        stField(iField).Name  = 'w3';
        stField(iField).Type  = 2;
        stField(iField).Range = stOpt.W3;
        stField(iField).Color = [1.0 0.7 1.0];
        iField = iField + 1;
    end % if

    stSCBeam = {};
    if ~isempty(stOpt.Scatter)
        vTemp = oData.Translate.Lookup(stOpt.Scatter,'Species');
        stSCBeam{1} = vTemp.Name;
    end % if
    if ~isempty(stOpt.Scatter1)
        vTemp = oData.Translate.Lookup(stOpt.Scatter1,'Species');
        stSCBeam{1} = vTemp.Name;
    end % if
    if ~isempty(stOpt.Scatter2)
        vTemp = oData.Translate.Lookup(stOpt.Scatter2,'Species');
        stSCBeam{2} = vTemp.Name;
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

    oDN      = Density(oData, vPlasma.Name, 'Units', 'SI', 'X1Scale', 'mm', 'X2Scale', 'mm');
    oDN.Time = iTime;

    if length(stOpt.Limits) == 4
        oDN.X1Lim = stOpt.Limits(1:2);
        oDN.X2Lim = stOpt.Limits(3:4);
    end % if

    if oData.Config.Simulation.Dimensions == 3
        oDN.SliceAxis = stOpt.SliceAxis;
        oDN.Slice     = stOpt.Slice;
    end % if

    stData = oDN.Density2D('Density',stOpt.Density,'GridDiag',stOpt.GridDiag);

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

    stReturn.HAxis     = stData.HAxis;
    stReturn.VAxis     = stData.VAxis;
    stReturn.ZPos      = stData.ZPos;
    stReturn.AxisFac   = oDN.AxisFac;
    stReturn.AxisRange = oDN.AxisRange;

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

    imagesc(aHAxis, aVAxis, aData);
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

            oBeam      = Density(oData, stSCBeam{i}, 'Units', 'SI', 'X1Scale', oDN.AxisScale{1}, 'X2Scale', oDN.AxisScale{1});
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
    
    aCol(1,1:3) = [1.0 0.7 0.7];
    aCol(2,1:3) = [0.7 0.7 1.0];

    for i=1:length(stOLBeam)
    
        if ~isempty(stOLBeam(i))
            
            oBeam      = Density(oData, stOLBeam{i}, 'Units', 'SI', 'X1Scale', oDN.AxisScale{1}, 'X2Scale', oDN.AxisScale{1});
            oBeam.Time = iTime;

            if length(stOpt.Limits) == 4
                oBeam.X1Lim = stOpt.Limits(1:2);
                oBeam.X2Lim = stOpt.Limits(3:4);
            end % if
        
            stBeam = oBeam.Density2D('GridDiag',stOpt.GridDiag);
            aProjZ = abs(sum(stBeam.Data));
            aProjZ = 0.15*(aVAxis(end)-aVAxis(1))*aProjZ/max(abs(aProjZ))+aVAxis(1);
            stQTot = oBeam.BeamCharge;

            [dQ, sQUnit] = fAutoScale(stQTot.QTotal,'C');

            plot(aHAxis, aProjZ, 'Color', aCol(i,:));
            stOLLeg{iOLNum} = sprintf('Q_{tot}^{%s} = %.2f %s', oData.Translate.Lookup(stOLBeam{i}).Short, dQ, sQUnit);
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
        
        if stField(i).Type == 1
            oFLD = Field(oData,stField(i).Name,'Units','SI','X1Scale',oDN.AxisScale{1},'X2Scale',oDN.AxisScale{2});
        else
            oFLD = Field(oData,'e1','Units','SI','X1Scale',oDN.AxisScale{1},'X2Scale',oDN.AxisScale{2});
        end % if
        oFLD.Time = iTime;
        sFUnit    = oFLD.FieldUnit;
        
        if length(stOpt.Limits) == 4
            oFLD.X1Lim = stOpt.Limits(1:2);
            oFLD.X2Lim = stOpt.Limits(3:4);
        end % if

        if oData.Config.Simulation.Dimensions == 3
            oFLD.SliceAxis = stOpt.SliceAxis;
            oFLD.Slice     = stOpt.Slice;
        end % if

        if stField(i).Type == 1
            stFLD   = oFLD.Lineout(iS,iA);
        else
            stFLD   = oFLD.WFLineout(stField(i).Name,iS,iA);
        end % if
        aEFData = 0.15*(aVAxis(end)-aVAxis(1))*stFLD.Data/max(abs(stFLD.Data));

        [dEne,  sEne]  = fAutoScale(max(abs(stFLD.Data)), sFUnit);
        [dEVal, sUnit] = fAutoScale(stFLD.VRange(2)*1e-3, 'm');
        dSVal          = stFLD.VRange(1)*dEVal/stFLD.VRange(2);
        
        plot(stFLD.HAxis,aEFData,'Color',stField(i).Color);
        stOLLeg{iOLNum} = sprintf('%s^{%.0f–%.0f %s} < %.1f %s',oData.Translate.Lookup(stField(i).Name).Tex,dSVal,dEVal,sUnit,dEne,sEne);
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
            set(findobj(h, 'type', 'line'), 'visible', 'off');
        end % if

    end % if
    
    if strcmpi(stOpt.HideDump, 'No')
        sTitle = sprintf('%s Density %s (%s #%d)', vPlasma.Full, oDN.PlasmaPosition, oData.Config.Name, iTime);
    else
        sTitle = sprintf('%s Density %s', vPlasma.Full, oDN.PlasmaPosition);
    end % if

    title(sTitle);
    xlabel('\xi [mm]');
    ylabel('r [mm]');
    title(hCol,'n/n_0');
    
    hold off;
    
    
    %
    %  Return
    % ********
    %

    stReturn.Plasma = vPlasma.Name;
    stReturn.XLim   = xlim;
    stReturn.YLim   = ylim;
    stReturn.CLim   = caxis;
    
end % function
