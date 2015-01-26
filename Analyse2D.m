
%
%  GUI :: Analyse 2D Data
% ************************
%

function Analyse2D(oData)

    %
    %  Variable Presets
    % ******************
    %

    % Colours
    
    cBackGround  = [0.8 0.8 0.8];
    cWhite       = [1.0 1.0 1.0];
    
    % Default Settings
    
    X.Time.Dump    = 0;
    X.Time.ZPos    = 0.0;

    X.Time.Start   = fStringToDump(oData, 'Start');
    X.Time.End     = fStringToDump(oData, 'End');
    X.Time.PStart  = fStringToDump(oData, 'PStart');
    X.Time.PEnd    = fStringToDump(oData, 'PEnd');
    
    X.Data.Name    = oData.Config.Name;
    X.Data.Beam    = oData.Config.Variables.Species.Beam;
    X.Data.Plasma  = oData.Config.Variables.Species.Plasma;
    
    X.Data.X1Min   = oData.Config.Variables.Simulation.BoxX1Min;
    X.Data.X1Max   = oData.Config.Variables.Simulation.BoxX1Max;
    X.Data.X2Min   = oData.Config.Variables.Simulation.BoxX2Min;
    X.Data.X2Max   = oData.Config.Variables.Simulation.BoxX2Max;
    
    X.Data.Coords  = oData.Config.Variables.Simulation.Coordinates;
    X.Data.X1Range = [0.0 0.0];
    X.Data.X2Range = [0.0 0.0];
    X.Data.X1Limit = [0.0 0.0];
    X.Data.X2Limit = [0.0 0.0];
    
    X.Main.Plots   = {'Beam Density','Plasma Density'};
    X.Main.Type    = 1;
    X.Main.Data    = 'ProtonBeam';
    X.Main.Scatter = ['Off'; X.Data.Beam];
    X.Main.ShowS1  = '';
    X.Main.ShowS2  = '';
    X.Main.NumS1   = 2000;
    X.Main.NumS2   = 2000;
    X.Main.Proj    = {'Off','Density','E-Field'};
    X.Main.ToProj  = 2;
    X.Main.SymX2   = 1;

    
    %
    %  Main Figure
    % *************
    %
    
    % Figure Controls
    iFigF = 0;
    iFigR = 0;
    
    fMain = figure(1); clf;
    aMPos = get(fMain, 'Position');
    
    % Set figure properties
    
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'Position', [aMPos(1:2) 1000 610]);
    set(fMain, 'Color', cBackGround);
    set(fMain, 'Name', sprintf('Beam Density (%s #%d)', X.Data.Name, X.Time.Dump));

    aMPos = get(fMain, 'Position');

    % Plot Axes
    axMain = axes('Units','Pixels');
    axFoot = axes('Units','Pixels','Visible','Off');
    axROne = axes('Units','Pixels','Visible','Off');
    axRTwo = axes('Units','Pixels','Visible','Off');
    axFTwo = axes('Units','Pixels','Visible','Off');

    
    %
    %  Control Figure
    % ****************
    %

    fCtrl = figure(2); clf;

    set(fCtrl, 'Units', 'Pixels');
    set(fCtrl, 'Position', [aMPos(1) aMPos(2) 250 700]);
    set(fCtrl, 'Color', cBackGround);
    set(fCtrl, 'NumberTitle', 'Off');
    set(fCtrl, 'MenuBar', 'None');
    set(fCtrl, 'ToolBar', 'None');
    set(fCtrl, 'Name', 'Controls');
    
    fUpdateFigures;
    fPlot;

    X.Data.X1Limit = X.Data.X1Range;
    X.Data.X2Limit = X.Data.X2Range;

    
    %
    %  Create Controls
    % *****************
    %
    
    iX = 20; iY = 660;
    set(0, 'CurrentFigure', fCtrl);
    uicontrol('Style','Text','String','Controls','FontSize',20,'Position',[iX iY 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    iY = iY-15;

    
    %  Time Dump Controls
    % ====================

    iY = iY-85;
    
    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[iX iY 200 80],'BackgroundColor',cBackGround);

    uicontrol(bgTime,'Style','Text','String','#','Position',[132 37 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTime,'Style','Text','String','L','Position',[133 12 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 10 35 30 22],'Callback',@fJumpPrev);
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[ 40 35 30 22],'Callback',@fSkipPrev);
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[ 70 35 30 22],'Callback',@fSkipNext);
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[100 35 30 22],'Callback',@fJumpNext);

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 10 10 30 22],'Callback',@fGoStart);
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[ 40 10 30 22],'Callback',@fGoPStart);
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[ 70 10 30 22],'Callback',@fGoPEnd);
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[100 10 30 22],'Callback',@fGoEnd);

    edtDumpN = uicontrol(bgTime,'Style','Edit','String',sprintf('%d',  X.Time.Dump),'Position',[ 145 35 45 20],'Callback',@fEditDump);
    edtDumpL = uicontrol(bgTime,'Style','Edit','String',sprintf('%.2f',X.Time.ZPos),'Position',[ 145 10 45 20]);

    
    %  Main Figure Controls
    % ======================
    
    iTop = 80;
    iY   = iY-iTop-25;

    bgMain = uibuttongroup('Title','Main Figure','Units','Pixels','Position',[iX iY 200 iTop+20],'BackgroundColor',cBackGround);

    uicontrol(bgMain,'Style','Text','String','Plot',   'Position',[10 iTop-18 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgMain,'Style','Text','String','Data',   'Position',[10 iTop-43 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgMain,'Style','Text','String','Overlay','Position',[10 iTop-68 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    
    pumFMain = uicontrol(bgMain,'Style','PopupMenu','String',X.Main.Plots,'Value',1,'Position',[65 iTop-20 125 22],'Callback',@fSelMainType);
    pumData  = uicontrol(bgMain,'Style','PopupMenu','String',X.Data.Beam, 'Value',1,'Position',[65 iTop-45 125 22],'Callback',@fSelMainData);
    pumProj  = uicontrol(bgMain,'Style','PopupMenu','String',X.Main.Proj, 'Value',2,'Position',[65 iTop-70 125 22],'Callback',@fSelMainProj);

    % Main Figure Scatter Controls

    iTop = 55;
    iY   = iY-iTop-25;

    bgScatter = uibuttongroup('Title','Main: Scatter Beam','Units','Pixels','Position',[iX iY 200 iTop+20],'BackgroundColor',cBackGround);

    uicontrol(bgScatter,'Style','PopupMenu','String',X.Main.Scatter,'Position',[10 iTop-20 110 22],'Callback',@fSelScatter1);
    uicontrol(bgScatter,'Style','PopupMenu','String',X.Main.Scatter,'Position',[10 iTop-45 110 22],'Callback',@fSelScatter2);

    uicontrol(bgScatter,'Style','Text','String','#','Position',[122 iTop-18 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgScatter,'Style','Text','String','#','Position',[122 iTop-43 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    uicontrol(bgScatter,'Style','Edit','String',sprintf('%d',X.Main.NumS1),'Position',[135 iTop-20 55 20],'Callback',@fNumScatter1);
    uicontrol(bgScatter,'Style','Edit','String',sprintf('%d',X.Main.NumS2),'Position',[135 iTop-45 55 20],'Callback',@fNumScatter2);
    
    % Zoom Controls

    iTop = 70;
    iY   = iY-iTop-25;

    bgZoom = uibuttongroup('Title','Main: Zoom','Units','Pixels','Position',[iX iY 200 iTop+20],'BackgroundColor',cBackGround);

    uicontrol(bgZoom,'Style','Text','String','X Lim','Position',[10 iTop-18 45 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgZoom,'Style','Text','String','Y Lim','Position',[10 iTop-43 45 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    
    uicontrol(bgZoom,'Style','Text','String','–','Position',[120 iTop-18 10 15],'BackgroundColor',cBackGround);
    uicontrol(bgZoom,'Style','Text','String','–','Position',[120 iTop-43 10 15],'BackgroundColor',cBackGround);
    
    edtXMin = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',X.Data.X1Limit(1)),'Position',[ 60 iTop-20 60 20],'Callback',@fMainXMin);
    edtXMax = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',X.Data.X1Limit(2)),'Position',[130 iTop-20 60 20],'Callback',@fMainXMax);
    edtYMin = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',X.Data.X2Limit(1)),'Position',[ 60 iTop-45 60 20],'Callback',@fMainYMin);
    edtYMax = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',X.Data.X2Limit(2)),'Position',[130 iTop-45 60 20],'Callback',@fMainYMax);

    chkX2Sym = uicontrol(bgZoom,'Style','Checkbox','String','Symmetric X2 axis','Value',X.Main.SymX2,'Position',[50 iTop-65 140 15],'BackgroundColor',cBackGround,'Callback',@fMainSymX2);
                      
    
    %
    %  Functions
    % ***********
    %
    
    % Type Callback
    
    function fSelMainType(uiSrc, ~)
        
        iValue = get(uiSrc, 'Value');

        switch(iValue)
            case 1
                X.Main.Type = 1;
                set(pumData, 'String', X.Data.Beam, 'Value', 1);
                X.Main.Data = X.Data.Beam{1};
            case 2
                X.Main.Type = 2;
                set(pumData, 'String', X.Data.Plasma, 'Value', 1);
                X.Main.Data = X.Data.Plasma{1};
        end % switch
        
        fPlot;
        
    end % function
    
    % Time Callback
    
    function fSkipNext(~, ~)

        X.Time.Dump = X.Time.Dump + 1;
        if X.Time.Dump > X.Time.End
            X.Time.Dump = X.Time.End;
        end % if

        fPlot;
        fUpdateTime;

    end % function

    function fJumpNext(~, ~)
    
        X.Time.Dump = X.Time.Dump + 10;
        if X.Time.Dump > X.Time.End
            X.Time.Dump = X.Time.End;
        end % if

        fPlot;
        fUpdateTime;

    end % function

    function fSkipPrev(~, ~)

        X.Time.Dump = X.Time.Dump - 1;
        if X.Time.Dump < 0
            X.Time.Dump = 0;
        end % if
        
        fPlot;
        fUpdateTime;

    end % function

    function fJumpPrev(~, ~)

        X.Time.Dump = X.Time.Dump - 10;
        if X.Time.Dump < 0
            X.Time.Dump = 0;
        end % if
        
        fPlot;
        fUpdateTime;

    end % function

    function fGoStart(~, ~)
        
        X.Time.Dump = X.Time.Start;
        fPlot;
        fUpdateTime;
        
    end % function

    function fGoEnd(~, ~)
        
        X.Time.Dump = X.Time.End;
        fPlot;
        fUpdateTime;
        
    end % function

    function fGoPStart(~, ~)
        
        X.Time.Dump = X.Time.PStart;
        fPlot;
        fUpdateTime;
        
    end % function

    function fGoPEnd(~, ~)
        
        X.Time.Dump = X.Time.PEnd;
        fPlot;
        fUpdateTime;
        
    end % function

    function fEditDump(uiSrc)
        
        sValue      = num2str(get(uiSrc, 'Value'));
        X.Time.Dump = fStringToDump(oData, sValue);
        fPlot;
        fUpdateTime;
        
    end % function

    % Data Callback
    
    function fSelMainData(uiSrc, ~)
        
        iValue = get(uiSrc, 'Value');

        switch(X.Main.Type)
            case 1
                X.Main.Data = X.Data.Beam{iValue};
            case 2
                X.Main.Data = X.Data.Plasma{iValue};
        end % switch
        
        fPlot;
        
    end % function

    function fSelMainProj(uiSrc, ~)
        
        X.Main.ToProj = get(uiSrc, 'Value');
        fPlot;
        
    end % function
    
    % Scatter Callpack
    
    function fSelScatter1(uiSrc, ~)
        
        iValue = get(uiSrc, 'Value');

        X.Main.ShowS1 = X.Main.Scatter{iValue};
        if strcmp(X.Main.ShowS1, 'Off')
            X.Main.ShowS1 = '';
        end % if
        
        fPlot;
        
    end % function

    function fSelScatter2(uiSrc, ~)
        
        iValue = get(uiSrc, 'Value');

        X.Main.ShowS2 = X.Main.Scatter{iValue};
        if strcmp(X.Main.ShowS2, 'Off')
            X.Main.ShowS2 = '';
        end % if
        
        fPlot;
        
    end % function

    function fNumScatter1(uiSrc, ~)
        
        iValue = str2num(get(uiSrc, 'String'));
        iValue = floor(iValue);
        
        if isempty(iValue)
            iValue = 2000;
        end % if
        
        set(uiSrc, 'String', num2str(iValue));
        
        X.Main.NumS1 = iValue;
        fPlot;
        
    end % function

    function fNumScatter2(uiSrc, ~)
        
        iValue = str2num(get(uiSrc, 'String'));
        iValue = floor(iValue);
        
        if isempty(iValue)
            iValue = 2000;
        end % if
        
        set(uiSrc, 'String', num2str(iValue));
        
        X.Main.NumS2 = iValue;
        fPlot;
        
    end % function

    % Zoom Callback

    function fMainXMin(uiSrc, ~)
        
        iValue = str2num(get(uiSrc, 'String'));
        
        if isempty(iValue)
            iValue = X.Data.X1Limit(1);
        end % if
        
        if iValue < X.Data.X1Range(1)
            iValue = X.Data.X1Range(1);
        end % if
        
        if iValue > X.Data.X1Range(2)
            iValue = X.Data.X1Range(2);
        end % if
        
        X.Data.X1Limit(1) = iValue;
        fUpdateZoom;
        
    end % function

    function fMainXMax(uiSrc, ~)
        
        iValue = str2num(get(uiSrc, 'String'));
        
        if isempty(iValue)
            iValue = X.Data.X1Limit(2);
        end % if
        
        if iValue < X.Data.X1Range(1)
            iValue = X.Data.X1Range(1);
        end % if
        
        if iValue > X.Data.X1Range(2)
            iValue = X.Data.X1Range(2);
        end % if
        
        X.Data.X1Limit(2) = iValue;
        fUpdateZoom;
        
    end % function

    function fMainYMin(uiSrc, ~)
        
        iValue = str2num(get(uiSrc, 'String'));
        
        if isempty(iValue)
            iValue = X.Data.X2Limit(1);
        end % if
        
        if iValue < X.Data.X2Range(1)
            iValue = X.Data.X2Range(1);
        end % if
        
        if iValue > X.Data.X2Range(2)
            iValue = X.Data.X2Range(2);
        end % if

        X.Data.X2Limit(1) = iValue;
        if X.Main.SymX2 == 1
            X.Data.X2Limit(2) = -X.Data.X2Limit(1);
        end % if
        
        fUpdateZoom;
        
    end % function

    function fMainYMax(uiSrc, ~)
        
        iValue = str2num(get(uiSrc, 'String'));
        
        if isempty(iValue)
            iValue = X.Data.X2Limit(2);
        end % if
        
        if iValue < X.Data.X2Range(1)
            iValue = X.Data.X2Range(1);
        end % if
        
        if iValue > X.Data.X2Range(2)
            iValue = X.Data.X2Range(2);
        end % if
        
        X.Data.X2Limit(2) = iValue;
        if X.Main.SymX2 == 1
            X.Data.X2Limit(1) = -X.Data.X2Limit(2);
        end % if

        fUpdateZoom;
        
    end % function

    function fMainSymX2(uiSrc, ~) 

        X.Main.SymX2 = get(uiSrc, 'Value');
        fUpdateZoom;

    end % function

    % Update Functions

    function fUpdateTime
        
        set(edtDumpN, 'String', sprintf('%d', X.Time.Dump));
        set(edtDumpL, 'String', sprintf('%.2f', X.Time.ZPos));
        
    end % function

    function fUpdateZoom

        set(edtXMin,'String',sprintf('%.2f',X.Data.X1Limit(1)));
        set(edtXMax,'String',sprintf('%.2f',X.Data.X1Limit(2)));
        set(edtYMin,'String',sprintf('%.2f',X.Data.X2Limit(1)));
        set(edtYMax,'String',sprintf('%.2f',X.Data.X2Limit(2)));
        
        fPlot;

    end % function

    % Plot Function

    function fPlot
        
        set(0,     'CurrentFigure', fMain);
        set(fMain, 'CurrentAxes',   axMain);

        if X.Data.X1Limit(2) > 0 && X.Data.X2Limit(2) > 0
            aLimits = [X.Data.X1Limit X.Data.X2Limit];
        else
            aLimits = [];
        end % if
        
        sOverlay1 = '';
        sOverlay2 = '';
        
        switch(X.Main.ToProj)
            case 1
                sOverlay  = 'No';
            case 2
                sOverlay  = 'Yes';
                sOverlay1 = X.Main.ShowS1;
                sOverlay2 = X.Main.ShowS2;
        end % if
        
        switch(X.Main.Type)
            
            case 1
                stPlot = fPlotBeamDensity(oData, X.Time.Dump, X.Main.Data, ...
                                          'IsSubPlot', 'Yes', ...
                                          'HideDump', 'Yes', ...
                                          'Absolute', 'Yes', ...
                                          'ShowOverlay', sOverlay, ...
                                          'Limits', aLimits);
                                      
            case 2
                stPlot = fPlotPlasmaDensity(oData, X.Time.Dump, X.Main.Data, ...
                                            'IsSubPlot', 'Yes', ...
                                            'HideDump', 'Yes', ...
                                            'Absolute', 'Yes', ...
                                            'Overlay1', sOverlay1, ...
                                            'Overlay2', sOverlay2, ...
                                            'Scatter1', X.Main.ShowS1, ...
                                            'Scatter2', X.Main.ShowS2, ...
                                            'Sample1', X.Main.NumS1, ...
                                            'Sample2', X.Main.NumS2, ...
                                            'Limits', aLimits, ...
                                            'CAxis', [0 5]);

        end % switch

        set(fMain, 'Name', sprintf('Analyse Density (%s #%d)', X.Data.Name, X.Time.Dump));

        if sum(X.Data.X1Range) == 0.0 && sum(X.Data.X2Range) == 0

            X.Data.X1Range = [stPlot.X1Axis(1) stPlot.X1Axis(end)];
            X.Data.X2Range = [stPlot.X2Axis(1) stPlot.X2Axis(end)];

            if strcmpi(X.Data.Coords, 'Cylindrical')
                X.Data.X2Range(1) = -X.Data.X2Range(2);
            end % if

        end % if

        X.Time.ZPos  = stPlot.ZPos;
        
    end % function 

    % Figures
    
    function fUpdateFigures

        set(0, 'CurrentFigure', fMain);
        aMainO = get(fMain, 'OuterPosition');
        aMainI = get(fMain, 'Position');
        
        stFig = struct();
        stFig.FPos = [aMainO(1) aMainO(2)+aMainO(4)];
        stFig.Size = [1020 610];
        stFig.Main = [  70  60];
        stFig.Foot = [  70  60];
        stFig.ROne = [1070 360];
        stFig.RTwo = [1070  60];
        stFig.FTwo = [1070  60];
       
        if iFigF == 1
            set(axFoot, 'Position', [stFig.Foot 900 250]);
            set(axFoot, 'Visible',  'On');
            stFig.Size = [1020 950];
            stFig.Main = [  70 400];
            stFig.ROne = [1070 700];
            stFig.RTwo = [1070 400];
        else
            cla(axFoot);
            cla(axFTwo);
            set(axFoot, 'Visible',  'Off');
            set(axFTwo, 'Visible',  'Off');
        end % if
        
        if iFigR == 1
            set(axROne, 'Position', [stFig.ROne 300 200]);
            set(axRTwo, 'Position', [stFig.RTwo 300 200]);
            set(axROne, 'Visible',  'On');
            set(axRTwo, 'Visible',  'On');
            stFig.Size = [1400 610];
        else
            cla(axROne);
            cla(axRTwo);
            set(axROne, 'Visible',  'Off');
            set(axRTwo, 'Visible',  'Off');
        end % if

        if iFigF == 1 && iFigR == 1
            set(axFTwo, 'Position', [stFig.FTwo 300 250]);
            set(axFTwo, 'Visible',  'On');
            stFig.Size = [1400 950];
        else
            cla(axFTwo);
            set(axFTwo, 'Visible',  'Off');
        end % if

        set(axMain, 'Position', [stFig.Main 900 500]);
        
        set(fMain, 'Position', [aMainI(1:2) stFig.Size]);
        aMainO = get(fMain, 'OuterPosition');
        aMainI = get(fMain, 'Position');
        
        set(fMain, 'OuterPosition', [stFig.FPos(1) stFig.FPos(2)-aMainO(4) aMainO(3:4)]);
        aMainO = get(fMain, 'OuterPosition');

        aCtrl = get(fCtrl, 'OuterPosition');
        set(fCtrl, 'OuterPosition', [aMainO(1)+aMainO(3)+8 aMainO(2)+aMainO(4)-aCtrl(4) aCtrl(3:4)]);
        
    end % function
   
end % function
