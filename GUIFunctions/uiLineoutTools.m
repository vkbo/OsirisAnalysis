
%
%  GUI :: Lineout Tool
% *********************
%

function uiLineoutTools(oData, varargin)

    %
    %  Data Struct
    % *************
    %
    
    % Check Input
    if nargin < 1
        fprintf(2,'Error: Please provide an OsirisData object.\n');
        return;
    end %if

    % Read input parameters
    oOpt = inputParser;
    addParameter(oOpt, 'Position', []);
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;
    
    % Get Values
    iDumps  = oData.MSData.MaxFiles;
    dPStart = oData.Config.Simulation.PlasmaStart;
    dTFac   = oData.Config.Convert.SI.TimeFac;
    dLFac   = oData.Config.Convert.SI.LengthFac;

    % Get DataSet Info
    X.Name     = oData.Config.Name;                          % Name of dataset
    X.Species  = fieldnames(oData.Config.Particles.Species); % All species in dataset
    X.Fields   = oData.Config.EMFields.Reports;
    X.Cyl      = oData.Config.Simulation.Cylindrical;
    X.Dim      = oData.Config.Simulation.Dimensions;

    if isempty(X.Species)
        fprintf(2,'Error: Dataset contains no species.\n');
        return;
    end % if
    
    X.DataSets  = {};
    X.DataTypes = {};
    X.DataNames = {};
    for s=1:length(X.Species)
        X.DataSets{end+1}  = X.Species{s};
        X.DataTypes{end+1} = 'S';
        X.DataNames{end+1} = oData.Translate.Lookup(X.Species{s},'Species').Name;
    end % for
    for s=1:length(X.Fields)
        X.DataSets{end+1}  = X.Fields{s};
        X.DataTypes{end+1} = 'F';
        X.DataNames{end+1} = oData.Translate.Lookup(X.Fields{s}).Full;
    end % for

    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(2);
    
    % Get Time Axis
    %X.TAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
    
    % Tracking
    X.Analyse.DataSet = X.DataSets{1};
    X.Analyse.Details = oData.Translate.Lookup(X.DataSets{1});

    % Data Objects
    oDN = Density(oData,X.Analyse.DataSet,'Units','SI','Scale','mm');
    oDN.Time = X.Dump;
    
    % Limits
    X.XLim         = oDN.AxisRange*1e-3;
    X.Plot.Limits  = [oDN.AxisRange(1:4) 0 0];
    if X.Cyl
        X.XLim(3)        = -X.XLim(4);
        X.Plot.Limits(3) = -X.Plot.Limits(4);
    end % if
    %X.Track.Limits = [X.XLim 0 X.XLim(4) 0 1 0 1 0 1 0 1];
    %X.Track.Scale  = ones(8,1);
    %X.Track.Units  = {'m','m','m','m','eV','eV','eV','C'};
    
    % Options
    switch(X.Dim)
        case 1
            fprintf(2,'Error: 1D simulations not supported.\n');
            return;
        case 2
            X.Opt.SliceAxis = {'X2'};
            X.SliceAxis     = 1;
            X.SlicePos      = 0.0;
        case 3
            X.Opt.SliceAxis = {'X1','X2','X3'};
            X.SliceAxis     = 3;
            X.SlicePos      = (X.XLim(6)-X.XLim(5))/2;
    end % switch
    

    %
    %  Figure
    % ********
    %
    
    %fMain = figure('IntegerHandle', 'Off'); clf;
    fMain = figure(1); clf;
    aFPos = get(fMain, 'Position');
    iH    = 740;
    
    % Set Figure Properties
    fMain.Units        = 'Pixels';
    fMain.MenuBar      = 'None';
    fMain.Position     = [aFPos(1:2) 1220 iH];
    fMain.Name         = 'OsirisAnalysis: Lineout Tools';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-LN';

    if ~isempty(stOpt.Position) && sum(size(stOpt.Position) == [1 2]) == 2
        aOPos = fMain.OuterPosition;
        fMain.OuterPosition = [stOpt.Position-[-5 aOPos(4)] aOPos(3:4)];
    end % if
    
    % Axes
    axMain = axes('Units','Pixels','Position',[310 iH-290 550 230]);
    axHorz = axes('Units','Pixels','Position',[310 iH-580 550 230]);
    axVert = axes('Units','Pixels','Position',[910 iH-290 280 230]);
    
    %
    % Controls
    %
    
    uicontrol('Style','Text','String','Lineout Tools','FontSize',20,'Position',[20 iH-50 200 35],'HorizontalAlignment','Left');
    uicontrol('Style','Text','String',X.Name,'FontSize',18,'Position',[20 iH-85 230 25],'ForegroundColor',[1.00 1.00 0.00],'BackgroundColor',[0.80 0.80 0.80]);

    %
    % Time Dump
    %

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[20 iH-195 140 100]);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 9 60 30 20],'Callback',{@fDump, -10});
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[39 60 30 20],'Callback',{@fDump,  -1});
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[69 60 30 20],'Callback',{@fDump,   1});
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[99 60 30 20],'Callback',{@fDump,  10});

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 9 35 30 20],'Callback',{@fJump, 1});
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[39 35 30 20],'Callback',{@fJump, 2});
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[69 35 30 20],'Callback',{@fJump, 3});
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[99 35 30 20],'Callback',{@fJump, 4});

    lblDump(1) = uicontrol(bgTime,'Style','Text','String',X.Limits(1),'Position',[ 10 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);
    lblDump(2) = uicontrol(bgTime,'Style','Text','String',X.Limits(2),'Position',[ 40 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);
    lblDump(3) = uicontrol(bgTime,'Style','Text','String',X.Limits(3),'Position',[ 70 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);
    lblDump(4) = uicontrol(bgTime,'Style','Text','String',X.Limits(4),'Position',[100 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);

    %
    % DataSet
    %

    bgData = uibuttongroup('Title','Reference Data','Units','Pixels','Position',[20 iH-280 230 80]);

    uicontrol(bgData,'Style','Text','String','Data Set','Position',[ 10 35 60 20],'HorizontalAlignment','Left');
    uicontrol(bgData,'Style','Text','String','3D Slice','Position',[ 10  5 60 20],'HorizontalAlignment','Left');
    uicontrol(bgData,'Style','Text','String','Pos',     'Position',[135  5 25 20],'HorizontalAlignment','Left');

    pumSpecies = uicontrol(bgData,'Style','PopupMenu','String',X.DataNames,'Position',[75 40 145 20],'Callback',{@fSetDataSet});
    pumSlice   = uicontrol(bgData,'Style','PopupMenu','Position',[ 75 10  55 20],'Callback',{@fSetAliceAxis},'String',X.Opt.SliceAxis);
    edtSlPos   = uicontrol(bgData,'Style','Edit',     'Position',[165  8  55 20],'Callback',{@fSetSlicePos});

    %
    % Plot Limits
    %

    bgPLim = uibuttongroup('Title','Plot Limits','Units','Pixels','Position',[20 iH-430 230 145]);

    % Labels

    uicontrol(bgPLim,'Style','Text','String','Min',       'Position',[ 90 108 60 20]);
    uicontrol(bgPLim,'Style','Text','String','Max',       'Position',[160 108 60 20]);
    uicontrol(bgPLim,'Style','Text','String','Horizontal','Position',[ 10  85 70 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Vertical',  'Position',[ 10  60 70 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Color',     'Position',[ 10  35 70 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Color Map', 'Position',[ 10  10 70 20],'HorizontalAlignment','Left');

    % Fields
    edtPHMin = uicontrol(bgPLim,'Style','Edit',     'Position',[ 90 87  60 20],'Callback',{@fSetPlotLim,1});
    edtPHMax = uicontrol(bgPLim,'Style','Edit',     'Position',[160 87  60 20],'Callback',{@fSetPlotLim,2});
    edtPVMin = uicontrol(bgPLim,'Style','Edit',     'Position',[ 90 62  60 20],'Callback',{@fSetPlotLim,3});
    edtPVMax = uicontrol(bgPLim,'Style','Edit',     'Position',[160 62  60 20],'Callback',{@fSetPlotLim,4});
    edtPCMin = uicontrol(bgPLim,'Style','Edit',     'Position',[ 90 37  60 20],'Callback',{@fSetPlotLim,5});
    edtPCMax = uicontrol(bgPLim,'Style','Edit',     'Position',[160 37  60 20],'Callback',{@fSetPlotLim,6});
    pumPCMap = uicontrol(bgPLim,'Style','PopupMenu','Position',[ 90 12 130 20],'Callback',{@fSetPlotLim,7},'String','N');
    
    % Defaults
    pumSlice.Value  = X.SliceAxis;
    edtSlPos.String = sprintf('%.2f',X.SlicePos);
    edtPHMin.String = sprintf('%.2f',X.Plot.Limits(1));
    edtPHMax.String = sprintf('%.2f',X.Plot.Limits(2));
    edtPVMin.String = sprintf('%.2f',X.Plot.Limits(3));
    edtPVMax.String = sprintf('%.2f',X.Plot.Limits(4));
    edtPCMin.String = '0.00';
    edtPCMax.String = '0.00';


    % Output Window
    lstOut = uicontrol('Style','Listbox','String','OsirisAnalysis: Lineout Tools','FontName','FixedWidth','HorizontalAlignment','Left','BackgroundColor',[0 0 0],'ForegroundColor',[0 1 0]);
    lstOut.Position = [20 iH-720 560 87];
    jOut   = findjobj(lstOut);
    jList  = jOut.getViewport.getComponent(0);
    set(jList, 'SelectionBackground', java.awt.Color.black);
    set(jList, 'SelectionForeground', java.awt.Color.green);
    jList.setSelectionAppearanceReflectsFocus(0);

    
    %
    % Init
    %
    
    fRefreshDensity;
    fOut(sprintf('Loaded ''%s''',X.DataNames{1}),1);
    
    
    %
    %  Data Functions
    %
    
    function fRefresh()
        
        fRefreshDensity();
        
    end % function

    function fRefreshDensity()

        oDN.Time  = X.Dump;
        oDN.X1Lim = X.Plot.Limits(1:2);
        oDN.X2Lim = X.Plot.Limits(3:4);

        stData = oDN.Density2D();
        
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
        aData = abs(aData*dSMax/dMax);
        
        % Update Axes

        axes(axMain); cla;

        imagesc(aHAxis, aVAxis, aData);
        
        set(gca,'YDir','Normal');
        colormap('hot');
        hCol = colorbar();

        xlim([aHAxis(1) aHAxis(end)]);
        ylim([aVAxis(1) aVAxis(end)]);
        
        title(sprintf('%s Charge Density',X.Analyse.Details.Full));
        xlabel(sprintf('%s [mm]',vHAxis.Tex));
        ylabel(sprintf('%s [mm]',vVAxis.Tex));
        title(hCol,sprintf('%s [%s]',sLabel,sSUnit));
        
    end % function

    function fRefreshLineout()

        oDN.Time  = X.Dump;
        oDN.X1Lim = X.Plot.Limits(1:2);
        oDN.X2Lim = X.Plot.Limits(3:4);

        stData = oDN.Density2D();

    end % function
    
    %
    %  Callback Functions
    %

    function fSetDataSet(uiSrc,~)

        X.Analyse.DataSet = X.DataSets{uiSrc.Value};
        X.Analyse.Details = oData.Translate.Lookup(X.DataSets{uiSrc.Value});
    
        if strcmpi(X.DataTypes{uiSrc.Value}, 'S')
            oDN = Density(oData,X.Analyse.DataSet,'Units','SI','Scale','mm');
        else
            oDN = Field(oData,X.Analyse.DataSet,'Units','SI','Scale','mm');
        end % if
        fOut(sprintf('Loaded ''%s''',X.DataNames{uiSrc.Value}),1);
        
        fRefresh;

    end % function

    function fSetPlotLim(uiSrc,~,iDim)
        
        dValue = str2double(uiSrc.String);
        
        if iDim == 1 || iDim == 3
            if dValue < X.XLim(iDim)
                dValue = X.XLim(iDim);
            end % if
        end % if

        if iDim == 2 || iDim == 4
            if dValue > X.XLim(iDim)
                dValue = X.XLim(iDim);
            end % if
        end % if

        X.Plot.Limits(iDim) = dValue;
        uiSrc.String = sprintf('%.2f',dValue);
        fRefresh;
        
    end % function
    
    function fDump(~,~,iStep)
        
        X.Dump = X.Dump + iStep;
        
        if X.Dump < X.Limits(1)
            X.Dump = X.Limits(1);
            fOut('At the start of the dataset',2);
        end % if

        if X.Dump > X.Limits(4)
            X.Dump = X.Limits(4);
            fOut('At the end of the dataset',2);
        end % if
        
        fRefresh;
        
    end % function

    function fJump(~,~,iJump)
        
        X.Dump = X.Limits(iJump);
        
        fRefresh;
        
    end % function

    %
    %  Other Functions
    %

    function fOut(sText, iType, bOverwrite)
        
        if nargin < 3
            bOverwrite = false;
        end % if
        
        stCol = {'#00ff00;','#ffdd66;','#ff9999;'};
        if rand >= 0.99
            stPrefix = {'','OOPS: ','WTF: '};
        else
            stPrefix = {'','Warning: ','Error: '};
        end % if
        aTime  = clock;
        sStamp = sprintf('%02d:%02d:%02.0f> ',aTime(4),aTime(5),floor(aTime(6)));
        sText  = sprintf('<html><font style="color: %s">%s%s%s</font></html>',stCol{iType},sStamp,stPrefix{iType},sText);
        
        cOut = lstOut.String;
        if bOverwrite
            cOut{end} = sText;
        else
            cOut = [cOut;{sText}];
        end % if
        [iN, ~] = size(cOut);
        
        if iN > 100
            cOut(1) = [];
            iN = 100;
        end % if

        lstOut.String = cOut;
        lstOut.Value  = iN;
        
    end % function

end % function
