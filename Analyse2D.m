
%
%  GUI :: Analyse 2D Data
% ************************
%

function Analyse2D

    %
    %  Variable Presets
    % ******************
    %

    % Colours
    
    cBackGround  = [0.94 0.94 0.94];
    cWhite       = [1.00 1.00 1.00];
    cBlack       = [0.00 0.00 0.00];
    cInfoText    = [1.00 1.00 0.00];
    cOutText     = [0.00 1.00 0.00];
    cGreyText    = [0.50 0.50 0.50];
    cInfoBack    = [0.80 0.80 0.80];
    cInfoBtn     = [0.00 0.55 0.88];
    cFocusBtn    = [0.00 0.55 0.00];
    cInfoRed     = [1.00 0.50 0.50];
    cInfoYellow  = [1.00 1.00 0.50];
    cInfoGreen   = [0.50 1.00 0.50];
    cWarningBack = [1.00 0.50 0.50];
    cButtonOff   = [0.80 0.80 0.80];
    cButtonOn    = [0.85 0.40 0.85];
    
    % Data
    
    iXFig = 10;
    oData = OsirisData('Silent','Yes');
    oVar  = Variables();

    X.DataSet     = 0;
    X.LoadTo      = 1;
    X.Time.Dump   = 0;
    X.Time.Limits = [0 0 0 0];
    X.Data.Beam   = {' '};
    
    % Settings
    
    stSettings.LoadData = {'','',''};
    stSettings.LoadPath = {'','',''};
    for i=1:iXFig
        stSettings.Position(i).Pos  = [0 0];
        stSettings.Position(i).Size = [0 0];
    end % for
    if exist(strcat(oData.Temp, '/OsirisAnalyseSettings.mat'), 'file')
        stSettings = load(strcat(oData.Temp, '/OsirisAnalyseSettings.mat'));
    end % if

    X.Plots{1} = 'Beam Density';
    X.Plots{2} = 'Plasma Density';
    X.Plots{3} = 'Field Density';
    X.Plots{4} = 'Phase 2D';
    X.Plots{5} = 'XX'' Phase Space';
    
    X.Opt.Sample = {'Random','WRandom','W2Random','Top','Bottom'};

    X.Figure = [0 0 0 0 0 0];
    X.X1Link = [0 0 0 0 0 0];
    X.X2Link = [0 0 0 0 0 0];
    X.X2Sym  = [0 0 0 0 0 0];
    
    for f=1:6
        X.Plot(f).Figure  = f;
        X.Plot(f).Enabled = 0;
        X.Plot(f).MaxLim  = [0.0 0.0 0.0 0.0];
        X.Plot(f).Limits  = [0.0 0.0 0.0 0.0];
        X.Plot(f).Scale   = [1.0 1.0];
    end % for
    for f=7:iXFig
        X.Plot(f).Figure  = f;
        X.Plot(f).Enabled = 0;
    end % for

    
    %
    %  Main Figure
    % *************
    %
    
    % Figure Controls
    fMain = figure('IntegerHandle', 'Off'); clf;
    aFPos = fMain.Position;
    
    % Set figure properties
    fMain.Units        = 'Pixels';
    fMain.MenuBar      = 'None';
    fMain.Position     = [aFPos(1:2) 560 640];
    fMain.Name         = 'OsirisAnalysis Version 1.1 - GUI';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-Main';
    fMain.KeyPressFcn  = @fKeyPress;
    
    % Set background color to default
    cBackGround = fMain.Color;
    
    
    %
    %  Menu Bar
    % **********
    %

    mData = uimenu(fMain,'Label','Data');
    mD(1) = uimenu(mData,'Label','Load DataSet 1','Accelerator','1','Callback',{@fLoadSet,1});
    mD(2) = uimenu(mData,'Label','Load DataSet 2','Accelerator','2','Callback',{@fLoadSet,2});
    mD(3) = uimenu(mData,'Label','Load DataSet 3','Accelerator','3','Callback',{@fLoadSet,3});
            uimenu(mData,'Label','Rescan Data Folders','Accelerator','r','Separator','On','Callback',{@fScanData});

    mSims = uimenu(fMain,'Label','Simulation');
            uimenu(mSims,'Label','Show Sim Info','Accelerator','i','Callback',{@fShowSimInfo});

    mFigs = uimenu(fMain,'Label','Figure');
            uimenu(mFigs,'Label','Focus Figures','Accelerator','f','Callback',{@fFocus});
            
    mLoad = uimenu(fMain,'Label','Load');
    mL(1) = uimenu(mLoad,'Label','Load as #1','Callback',{@fSetLoadTo,1});
    mL(2) = uimenu(mLoad,'Label','Load as #2','Callback',{@fSetLoadTo,2});
    mL(3) = uimenu(mLoad,'Label','Load as #3','Callback',{@fSetLoadTo,3});
            uimenu(mLoad,'Label','Select Dataset:','Separator','On');
    
    mL(X.LoadTo).Checked = 'On';

    
    %
    %  Create Controls
    % *****************
    %
    
    set(0, 'CurrentFigure', fMain);
    uicontrol('Style','Text','String','Controls','FontSize',20,'Position',[20 602 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol('Style','PushButton','String','i','FontSize',15,'FontName','FixedWidth','FontWeight','Bold','Position',[210 600 25 25],'BackgroundColor',cButtonOff,'ForegroundColor',cInfoBtn,'Callback',{@fShowSimInfo});
    uicontrol('Style','PushButton','String','f','FontSize',15,'FontName','FixedWidth','FontWeight','Bold','Position',[180 600 25 25],'BackgroundColor',cButtonOff,'ForegroundColor',cFocusBtn,'Callback',{@fFocus});

    lblData = uicontrol('Style','Text','String','No Data','FontSize',18,'Position',[240 600 300 25],'ForegroundColor',cInfoText,'BackgroundColor',cInfoBack);

    % Output Window
    lstOut = uicontrol('Style','Listbox','String','OsirisAnalysis','FontName','FixedWidth','Position',[20 20 520 87],'HorizontalAlignment','Left','BackgroundColor',cBlack,'ForegroundColor',cOutText);
    jOut   = findjobj(lstOut);
    jList  = jOut.getViewport.getComponent(0);
    set(jList, 'SelectionBackground', java.awt.Color.black);
    set(jList, 'SelectionForeground', java.awt.Color.green);
    jList.setSelectionAppearanceReflectsFocus(0);

    %  Data Set Controls
    % ===================

    bgData = uibuttongroup('Title','Load Data','Units','Pixels','Position',[20 490 250 100],'BackgroundColor',cBackGround);
    
    aY = [60 35 10];
    for i=1:3
        uicontrol(bgData,'Style','Text','String',sprintf('#%d',i),'Position',[9 aY(i)+2 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgData,'Style','PushButton','String','...','Position',[159 aY(i) 25 20],'BackgroundColor',cButtonOff,'Callback',{@fBrowseSet,i});
        
        edtSet(i) = uicontrol(bgData,'Style','Edit','String',stSettings.LoadData{i},'Position',[34 aY(i) 120 20],'BackgroundColor',cWhite);
        btnSet(i) = uicontrol(bgData,'Style','PushButton','String','Load','Position',[189 aY(i) 50 20],'BackgroundColor',cButtonOff,'Callback',{@fLoadSet,i});
    end % for
    

    %  Time Dump Controls
    % ====================

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[280 490 140 100],'BackgroundColor',cBackGround);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 9 60 30 20],'BackgroundColor',cButtonOff,'Callback',{@fDump, -10});
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[39 60 30 20],'BackgroundColor',cButtonOff,'Callback',{@fDump,  -1});
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[69 60 30 20],'BackgroundColor',cButtonOff,'Callback',{@fDump,   1});
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[99 60 30 20],'BackgroundColor',cButtonOff,'Callback',{@fDump,  10});

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 9 35 30 20],'BackgroundColor',cButtonOff,'Callback',{@fJump, 1});
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[39 35 30 20],'BackgroundColor',cButtonOff,'Callback',{@fJump, 2});
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[69 35 30 20],'BackgroundColor',cButtonOff,'Callback',{@fJump, 3});
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[99 35 30 20],'BackgroundColor',cButtonOff,'Callback',{@fJump, 4});

    lblDump(1) = uicontrol(bgTime,'Style','Text','String','0','Position',[ 10 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(2) = uicontrol(bgTime,'Style','Text','String','0','Position',[ 40 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(3) = uicontrol(bgTime,'Style','Text','String','0','Position',[ 70 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(4) = uicontrol(bgTime,'Style','Text','String','0','Position',[100 11 28 15],'BackgroundColor',cInfoBack);
    

    %  Simulation Info
    % =================

    bgInfo = uibuttongroup('Title','Simulation','Units','Pixels','Position',[430 490 110 100],'BackgroundColor',cBackGround);
    
    lblInfo(1) = uicontrol(bgInfo,'Style','Text','String','Geometry','Position',[9 60 90 17],'BackgroundColor',cInfoBack);
    lblInfo(2) = uicontrol(bgInfo,'Style','Text','String','Status',  'Position',[9 35 90 17],'BackgroundColor',cInfoBack);
    lblInfo(3) = uicontrol(bgInfo,'Style','Text','String','Tracks',  'Position',[9 10 90 17],'BackgroundColor',cInfoBack);

    
    %  Figure Controls
    % =================

    bgFigs = uibuttongroup('Title','Figures','Units','Pixels','Position',[20 280 520 200],'BackgroundColor',cBackGround);
    
    uicontrol(bgFigs,'Style','Text','String','Fig',      'Position',[  9 160  20 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','Plot Type','Position',[ 34 160 150 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','On',       'Position',[189 160  20 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','X-Min',    'Position',[214 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','| ',       'Position',[274 160  15 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','X-Max',    'Position',[294 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','Y-Min',    'Position',[354 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','| ',       'Position',[414 160  15 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','-=',       'Position',[432 160  19 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','Y-Max',    'Position',[454 160  55 15],'HorizontalAlignment','Center');

    aY = [135 110 85 60 35 10];
    aP = [1 2 3 4 5 1];
    for f=1:6
        uicontrol(bgFigs,'Style','Text','String',sprintf('#%d',f),'Position',[9 aY(f)+1 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        
        pumFig(f)  = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',aP(f),'Position',[34 aY(f) 150 20]);
        btnFig(f)  = uicontrol(bgFigs,'Style','PushButton','String','','Position',[189 aY(f) 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleFig,f});
        
        edtXMin(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[214 aY(f) 55 20],'BackgroundColor',cWhite,'Callback',{@fZoom,1,f});
        edtXMax(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[294 aY(f) 55 20],'BackgroundColor',cWhite,'Callback',{@fZoom,2,f});
        edtYMin(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[354 aY(f) 55 20],'BackgroundColor',cWhite,'Callback',{@fZoom,3,f});
        edtYMax(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[454 aY(f) 55 20],'BackgroundColor',cWhite,'Callback',{@fZoom,4,f});

        chkX1(f)   = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(f),'Position',[274 aY(f)+2 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
        chkX2(f)   = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Link(f),'Position',[414 aY(f)+2 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX2);
        chkS2(f)   = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(f), 'Position',[434 aY(f)+2 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    end % for
    

    %  Tabs
    % ======

    hTabGroup = uitabgroup('Units','Pixels','Position',[20 120 520 150]);
    
    for t=1:6
        hTabs(t) = uitab(hTabGroup,'Title',sprintf('Plot %d', t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','BorderType','None','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Text','String','No settings','FontSize',15,'Position',[10 85 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround,'ForegroundColor',cGreyText);
    end % for
    

    %  Time Plots
    % ============

    iY = 115;
    hTabX(1)  = uitab(hTabGroup,'Title','Time Plots');
    bgTabX(1) = uibuttongroup(hTabX(1),'Title','','BorderType','None','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
    % Sigma E to E Mean
    iY = iY - 25;

    uicontrol(bgTabX(1),'Style','Text','String','#8','Position',[5 iY+1 30 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(1),'Style','Text','String','Sigma E to E Mean','Position',[40 iY+1 160 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(1),'Style','Text','String','T =','Position',[395 iY+1 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    btnFig(7) = uicontrol(bgTabX(1),'Style','PushButton','String','','Position',[210 iY 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleXFig,7});
    pumT8(1)  = uicontrol(bgTabX(1),'Style','PopupMenu','String',X.Data.Beam,'Value',1,'Position',[240 iY 150 20],'Callback',{@fPlotSetBeam,7});
    edtT8(1)  = uicontrol(bgTabX(1),'Style','Edit','String','0','Position',[425 iY 40 20],'BackgroundColor',cWhite,'Callback',{@fChangeXVal,7});
    edtT8(2)  = uicontrol(bgTabX(1),'Style','Edit','String','0','Position',[470 iY 40 20],'BackgroundColor',cWhite,'Callback',{@fChangeXVal,7});

    % Sigma E to E Mean Ratio
    iY = iY - 25;

    uicontrol(bgTabX(1),'Style','Text','String','#9','Position',[5 iY+1 30 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(1),'Style','Text','String','Sigma E to E Mean Ratio','Position',[40 iY+1 160 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(1),'Style','Text','String','T =','Position',[395 iY+1 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    btnFig(8) = uicontrol(bgTabX(1),'Style','PushButton','String','','Position',[210 iY 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleXFig,8});
    pumT9(1)  = uicontrol(bgTabX(1),'Style','PopupMenu','String',X.Data.Beam,'Value',1,'Position',[240 iY 150 20],'Callback',{@fPlotSetBeam,8});
    edtT9(1)  = uicontrol(bgTabX(1),'Style','Edit','String','0','Position',[425 iY 40 20],'BackgroundColor',cWhite,'Callback',{@fChangeXVal,8});
    edtT9(2)  = uicontrol(bgTabX(1),'Style','Edit','String','0','Position',[470 iY 40 20],'BackgroundColor',cWhite,'Callback',{@fChangeXVal,8});

    % Beam Slip
    iY = iY - 25;

    uicontrol(bgTabX(1),'Style','Text','String','#10','Position',[5 iY+1 30 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(1),'Style','Text','String','Beam Slip','Position',[40 iY+1 160 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(1),'Style','Text','String','T =','Position',[395 iY+1 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    btnFig(9) = uicontrol(bgTabX(1),'Style','PushButton','String','','Position',[210 iY 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleXFig,9});
    pumT10(1) = uicontrol(bgTabX(1),'Style','PopupMenu','String',X.Data.Beam,'Value',1,'Position',[240 iY 150 20],'Callback',{@fPlotSetBeam,9});
    edtT10(1) = uicontrol(bgTabX(1),'Style','Edit','String','0','Position',[425 iY 40 20],'BackgroundColor',cWhite,'Callback',{@fChangeXVal,9});
    edtT10(2) = uicontrol(bgTabX(1),'Style','Edit','String','0','Position',[470 iY 40 20],'BackgroundColor',cWhite,'Callback',{@fChangeXVal,9});

    
    %  GUI Tools
    % ===========

    iY = 115;
    hTabX(2)  = uitab(hTabGroup,'Title','GUI Tools');
    bgTabX(2) = uibuttongroup(hTabX(2),'Title','','BorderType','None','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
    % Track Density
    iY = iY - 25;
    uicontrol(bgTabX(2),'Style','Text','String','#11','Position',[5 iY+1 30 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgTabX(2),'Style','Text','String','Track Density','Position',[40 iY+1 160 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    btnFig(10) = uicontrol(bgTabX(2),'Style','PushButton','String','','Position',[210 iY 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleXFig,10});

    set(hTabGroup,'SelectedTab',hTabX(2));
    
    fScanData(0,0);
    
    
    %
    %  Tab Controls
    % **************
    %
    
    function fResetTab(t)

        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','BorderType','None','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Text','String','No settings','FontSize',15,'Position',[10 85 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround,'ForegroundColor',cGreyText);

    end % function
    
    function fCtrlBeamDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        [~,iVal] = incellarray(X.Plot(t).Data, X.Data.Beam);
        if iVal == 0
            X.Plot(t).Data = X.Data.Beam{1};
            iVal = 1;
        end % if
        uicontrol(bgTab(t),'Style','Text','String','Beam','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Beam,'Value',iVal,'Position',[85 iY 150 20],'Callback',{@fPlotSetBeam,t});

        iY = iY - 25;
        [~,iVal] = incellarray(X.Plot(t).Density, X.Data.Density);
        if iVal == 0
            X.Plot(t).Data = X.Data.Density{1};
            iVal = 1;
        end % if
        uicontrol(bgTab(t),'Style','Text','String','Density','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Density,'Value',iVal,'Position',[85 iY 150 20],'Callback',{@fPlotSetDensity,t});
        
    end % function

    function fCtrlPlasmaDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        if strcmpi(X.Data.Coords, 'cylindrical')
            sField = 'NoTexCyl';
        else
            sField = 'NoTex';
        end % if
        
        iY = iY - 25;
        [~,iVal] = incellarray(X.Plot(t).Data, X.Data.Plasma);
        if iVal == 0
            X.Plot(t).Data = X.Data.Plasma{1};
            iVal = 1;
        end % if
        uicontrol(bgTab(t),'Style','Text','String','Plasma','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Plasma,'Value',iVal,'Position',[85 iY 150 20],'Callback',{@fPlotSetPlasma,t});

        iY = iY - 25;
        [~,iVal] = incellarray(X.Plot(t).Scatter(1),X.Plot(t).ScatterOpt);
        iVal     = iVal+(iVal==0);
        uicontrol(bgTab(t),'Style','Text','String','Scatter 1','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Plot(t).ScatterOpt,'Value',iVal,'Position',[85 iY 150 20],'Callback',{@fPlotSetScatter,t,1});
        uicontrol(bgTab(t),'Style','Text','String','Count','Position',[240 iY+1 45 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Edit','String',sprintf('%d',X.Plot(t).ScatterNum(1)),'Position',[285 iY 60 20],'Callback',{@fPlotSetScatterNum,t,1});
        uicontrol(bgTab(t),'Style','Text','String','Sample','Position',[355 iY+1 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Opt.Sample,'Value',X.Plot(t).Sample(1),'Position',[415 iY 90 20],'Callback',{@fPlotSetSample,t,1});

        iY = iY - 25;
        [~,iVal] = incellarray(X.Plot(t).Scatter(2),X.Plot(t).ScatterOpt);
        iVal     = iVal+(iVal==0);
        uicontrol(bgTab(t),'Style','Text','String','Scatter 2','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Plot(t).ScatterOpt,'Value',iVal,'Position',[85 iY 150 20],'Callback',{@fPlotSetScatter,t,2});
        uicontrol(bgTab(t),'Style','Text','String','Count','Position',[240 iY+1 45 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Edit','String',sprintf('%d',X.Plot(t).ScatterNum(2)),'Position',[285 iY 60 20],'Callback',{@fPlotSetScatterNum,t,2});
        uicontrol(bgTab(t),'Style','Text','String','Sample','Position',[355 iY+1 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Opt.Sample,'Value',X.Plot(t).Sample(2),'Position',[415 iY 90 20],'Callback',{@fPlotSetSample,t,2});
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Fields','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Checkbox','String',fTranslateField('e1',sField),'Value',X.Plot(t).Settings(1),'Position',[ 85 iY 50 20],'BackgroundColor',cBackGround,'Callback',{@fPlotSetting,t,1});
        uicontrol(bgTab(t),'Style','Checkbox','String',fTranslateField('e2',sField),'Value',X.Plot(t).Settings(2),'Position',[135 iY 50 20],'BackgroundColor',cBackGround,'Callback',{@fPlotSetting,t,2});

    end % function
    
    function fCtrlFieldDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Field','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Field,'Value',1,'Position',[85 iY 150 20],'Callback',{@fPlotSetField,t});
        
    end % function

    function fCtrlPhase2D(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Species','Position',[10 iY+1 100 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Species,'Value',1,'Position',[115 iY 150 20],'Callback',{@fPlotSetSpecies,t});
        uicontrol(bgTab(t),'Style','Checkbox','String','Use Raw Data','Value',X.Plot(t).Settings(1),'Position',[305 iY 150 20],'BackgroundColor',cBackGround,'Callback',{@fPlotSetting,t,1});

        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Horizontal Axis','Position',[10 iY+1 100 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Axis,'Value',1,'Position',[115 iY 180 20],'Callback',{@fPlotSetPhase,1,t});
        uicontrol(bgTab(t),'Style','Checkbox','String','Auto Scale','Value',X.Plot(t).Settings(2),'Position',[305 iY 150 20],'BackgroundColor',cBackGround,'Callback',{@fPlotSetting,t,2});

        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Vertical Axis','Position',[10 iY+1 100 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Axis,'Value',3,'Position',[115 iY 180 20],'Callback',{@fPlotSetPhase,2,t});
        uicontrol(bgTab(t),'Style','Checkbox','String','Auto Scale','Value',X.Plot(t).Settings(3),'Position',[305 iY 150 20],'BackgroundColor',cBackGround,'Callback',{@fPlotSetting,t,3});
        
    end % function

    function fCtrlPhaseSpace(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Species','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Species,'Value',1,'Position',[85 iY 150 20],'Callback',{@fPlotSetSpecies,t});
        uicontrol(bgTab(t),'Style','Text','String','Min. Part.','Position',[240 iY+1 65 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Edit','String',sprintf('%d',X.Plot(t).Count),'Position',[310 iY 80 20],'Callback',{@fPlotSetCount,t});

    end % function


    %
    %  Functions
    % ***********
    %
    
    % Load Data Callback
    
    function fScanData(~,~)
        
        oData    = OsirisData('Silent','Yes');
        stFields = fieldnames(oData.DefaultPath);
        for f=1:length(stFields)
            if oData.DefaultPath.(stFields{f}).Available
                fOut(sprintf('Scanning %s',oData.DefaultPath.(stFields{f}).Path),1);
                fOut(sprintf('... found %d sets',length(fieldnames(oData.DataSets.ByPath.(stFields{f})))),1);
                mLd(f) = uimenu(mLoad,'Label',stFields{f});
                stSets = fieldnames(oData.DataSets.ByPath.(stFields{f}));
                for s=1:length(stSets)
                    sSetPath  = oData.DataSets.ByPath.(stFields{f}).(stSets{s}).Path;
                    stSetPath = strsplit(sSetPath,'/');
                    uimenu(mLd(f),'Label',stSetPath{end},'Callback',{@fSelectDataSet,stSetPath{end}});
                end % for
            end % if
        end % for
        
    end % function
    
    function fLoadSet(~,~,iSet)
        
        for i=1:3
            btnSet(i).BackgroundColor = cButtonOff;
            stSettings.LoadData{i}    = edtSet(i).String;
            mD(i).Checked = 'Off';
        end % for

        btnSet(iSet).BackgroundColor = cButtonOn;
        mD(iSet).Checked = 'On';
        
        oData      = OsirisData('Silent','Yes');
        oData.Path = [stSettings.LoadPath{iSet} stSettings.LoadData{iSet}];
        X.DataSet  = iSet;
        if isempty(oData.Path)
            fOut('Dataset not found',3);
            return;
        end % if

        X.Data.Name       = oData.Config.Name;
        X.Data.Path       = oData.Config.Path;
        X.Data.Beam       = oData.Config.Variables.Species.Beam;
        X.Data.Plasma     = oData.Config.Variables.Species.Plasma;
        X.Data.Species    = [X.Data.Beam; X.Data.Plasma];
        X.Data.Field      = oData.Config.Variables.Fields.Field;
        X.Data.Completed  = oData.Config.Completed;
        X.Data.HasData    = oData.Config.HasData;
        X.Data.HasTracks  = oData.Config.HasTracks;
        X.Data.Consistent = oData.Config.Consistent;
        X.Data.Coords     = oData.Config.Variables.Simulation.Coordinates;
        
        % Reload Variables class
        oVar = Variables(X.Data.Coords);

        % Output
        fOut(sprintf('Loaded %s',X.Data.Path),1);
        
        % Geometry
        if strcmpi(X.Data.Coords, 'cylindrical')
            lblInfo(1).String          = 'Cylindrical';
            lblInfo(1).BackgroundColor = cInfoGreen;
            X.Data.CoordsPF            = 'Cyl';
        else
            lblInfo(1).String          = 'Cartesian';
            lblInfo(1).BackgroundColor = cInfoGreen;
            X.Data.CoordsPF            = '';
        end % if
        
        % Beams
        X.Data.Witness = oData.Config.Variables.Species.WitnessBeam;
        X.Data.Drive   = oData.Config.Variables.Species.DriveBeam;

        % Index Beams
        X.Data.WitnessIdx = 1;
        for i=1:length(X.Data.Beam)
            if strcmpi(X.Data.Beam{i}, X.Data.Witness)
                X.Data.WitnessIdx = i;
            end % if
        end % for
        
        % Translate Fields
        for i=1:length(X.Data.Field)
            X.Data.Field{i} = oVar.Lookup(X.Data.Field{i}).Full;
        end % for

        % Translate Densities
        X.Data.Density = oData.Config.Variables.Density.(X.Data.Species{1}).Density;
        for i=1:length(X.Data.Density)
            X.Data.Density{i} = oVar.Lookup(X.Data.Density{i}).Full;
        end % for

        % Translate Axes
        X.Data.Axis = {'x1','x2','p1','p2'};
        for i=1:length(X.Data.Axis)
            X.Data.Axis{i} = oVar.Lookup(X.Data.Axis{i}).Full;
        end % for
        
        % Simulation Status
        if X.Data.HasData
            if X.Data.Completed
                lblInfo(2).String          = 'Completed';
                lblInfo(2).BackgroundColor = cInfoGreen;
            else
                lblInfo(2).String          = 'Incomplete';
                lblInfo(2).BackgroundColor = cInfoYellow;
            end % if

            if ~X.Data.Consistent
                lblInfo(2).String          = 'Inconsistent';
                lblInfo(2).BackgroundColor = cInfoYellow;
            end % if

            X.Time.Limits(1) = fStringToDump(oData, 'Start');
            X.Time.Limits(2) = fStringToDump(oData, 'PStart');
            X.Time.Limits(3) = fStringToDump(oData, 'PEnd');
            X.Time.Limits(4) = fStringToDump(oData, 'End');
        else
            lblInfo(2).String          = 'No Data';
            lblInfo(2).BackgroundColor = cInfoRed;
            X.Time.Limits = [0 0 0 0];
        end % if
        
        % Tracking Data
        if X.Data.HasTracks
            lblInfo(3).String          = 'Has Tracks';
            lblInfo(3).BackgroundColor = cInfoGreen;
        else
            lblInfo(3).String          = 'No Tracks';
            lblInfo(3).BackgroundColor = cInfoYellow;
        end % if
                
        % Reset dump boxes
        for i=1:4
            lblDump(i).BackgroundColor = cInfoBack;
        end % for

        % Check that plasma start/end does not extend past the end of the simulation
        if X.Time.Limits(2) > X.Time.Limits(4)
            X.Time.Limits(2) = X.Time.Limits(4);
            lblDump(2).BackgroundColor = cWarningBack;
        end % if
        if X.Time.Limits(3) > X.Time.Limits(4)
            X.Time.Limits(3) = X.Time.Limits(4);
            lblDump(3).BackgroundColor = cWarningBack;
        end % if
        
        % Update Time Dump labels
        for i=1:4
            lblDump(i).String = X.Time.Limits(i);
        end % for
        
        % Set 'Time Plots' values
        edtT8(1).String  = X.Time.Limits(2);
        edtT8(2).String  = X.Time.Limits(4);
        edtT9(1).String  = X.Time.Limits(2);
        edtT9(2).String  = X.Time.Limits(4);
        edtT10(1).String = X.Time.Limits(1);
        edtT10(2).String = X.Time.Limits(4);
        
        pumT8(1).String  = X.Data.Beam;
        pumT9(1).String  = X.Data.Beam;
        pumT10(1).String = X.Data.Beam;

        pumT8(1).Value   = X.Data.WitnessIdx;
        pumT9(1).Value   = X.Data.WitnessIdx;
        pumT10(1).Value  = X.Data.WitnessIdx;
        
        X.Plot(7).Data   = X.Data.Beam{X.Data.WitnessIdx};
        X.Plot(8).Data   = X.Data.Beam{X.Data.WitnessIdx};
        X.Plot(9).Data   = X.Data.Beam{X.Data.WitnessIdx};

        % Refresh
        fReloadOptions;
        fRefresh;
        fRefreshX;
        
        % Save settings to file
        fSaveVariables;
        
    end % function

    function fBrowseSet(~,~,iSet)
        
        sDir   = uigetdir(stSettings.LoadPath{iSet});
        stPath = strsplit(sDir,'/');
        sData  = stPath{end};
        sPath  = [strjoin(stPath(1:end-1),'/') '/'];
        
        stSettings.LoadPath{iSet} = sPath;
        edtSet(iSet).String       = sData;
        fLoadSet(0,0,iSet);
        
    end % function

    function fSelectDataSet(~,~,sSet)
        
        edtSet(X.LoadTo).String       = sSet;
        stSettings.LoadPath{X.LoadTo} = '';
        fLoadSet(0,0,X.LoadTo);
        
    end % function

    % Time Dump
    
    function fDump(~,~,iStep)
        
        X.Time.Dump = X.Time.Dump + iStep;
        
        if X.Time.Dump < X.Time.Limits(1)
            X.Time.Dump = X.Time.Limits(1);
            fOut('At the start of the dataset',2);
        end % if

        if X.Time.Dump > X.Time.Limits(4)
            X.Time.Dump = X.Time.Limits(4);
            fOut('At the end of the dataset',2);
        end % if
        
        fRefresh;
        
    end % function

    function fJump(~,~,iJump)
        
        X.Time.Dump = X.Time.Limits(iJump);
        
        fRefresh;
        
    end % function

    % Zoom
    
    function fZoom(uiSrc,~,d,f)
        
        % Collect values
        dValue = str2double(uiSrc.String);
        
        if ~isempty(dValue)
            if d <= 2
                X.Plot(f).Limits(d) = dValue/X.Plot(f).Scale(1);
            else
                X.Plot(f).Limits(d) = dValue/X.Plot(f).Scale(2);
            end % if
        end % if
        
        % Check X range
        for i=1:2
            if X.Plot(f).Limits(i) < X.Plot(f).MaxLim(1)
                X.Plot(f).Limits(i) = X.Plot(f).MaxLim(1);
            end % if
            if X.Plot(f).Limits(i) > X.Plot(f).MaxLim(2)
                X.Plot(f).Limits(i) = X.Plot(f).MaxLim(2);
            end % if
        end % for

        % Check Y range
        for i=3:4
            if X.Plot(f).Limits(i) < X.Plot(f).MaxLim(3)
                X.Plot(f).Limits(i) = X.Plot(f).MaxLim(3);
            end % if
            if X.Plot(f).Limits(i) > X.Plot(f).MaxLim(4)
                X.Plot(f).Limits(i) = X.Plot(f).MaxLim(4);
            end % if
        end % for
        
        % Check X limit sanity
        if X.Plot(f).Limits(1) > X.Plot(f).Limits(2)
            dTemp               = X.Plot(f).Limits(1);
            X.Plot(f).Limits(1) = X.Plot(f).Limits(2);
            X.Plot(f).Limits(2) = dTemp;
        end % if
        
        % Check to update other X limits
        if X.X1Link(f)
            for i=1:6
                if X.X1Link(i) && X.Figure(i) > 0
                    X.Plot(i).Limits(1:2) = X.Plot(f).Limits(1:2)*X.Plot(f).Scale(1)/X.Plot(i).Scale(1);
                end % if
                for j=1:2
                    if X.Plot(i).Limits(j) < X.Plot(i).MaxLim(1)
                        X.Plot(i).Limits(j) = X.Plot(i).MaxLim(1);
                    end % if
                    if X.Plot(i).Limits(j) > X.Plot(i).MaxLim(2)
                        X.Plot(i).Limits(j) = X.Plot(i).MaxLim(2);
                    end % if
                end % for
            end % for
        end % if

        % Check to update other Y limit
        if X.X2Sym(f)
            switch(d)
                case 3
                    X.Plot(f).Limits(3) = -abs(X.Plot(f).Limits(3));
                    X.Plot(f).Limits(4) =  abs(X.Plot(f).Limits(3));
                case 4
                    X.Plot(f).Limits(3) = -abs(X.Plot(f).Limits(4));
                    X.Plot(f).Limits(4) =  abs(X.Plot(f).Limits(4));
            end % switch
        end % if

        if X.X2Link(f)
            for i=1:6
                if X.X2Link(i) && X.Figure(i) > 0
                    X.Plot(i).Limits(3:4) = X.Plot(f).Limits(3:4)*X.Plot(f).Scale(2)/X.Plot(i).Scale(2);
                end % if
                for j=3:4
                    if X.Plot(i).Limits(j) < X.Plot(i).MaxLim(3)
                        X.Plot(i).Limits(j) = X.Plot(i).MaxLim(3);
                    end % if
                    if X.Plot(i).Limits(j) > X.Plot(i).MaxLim(4)
                        X.Plot(i).Limits(j) = X.Plot(i).MaxLim(4);
                    end % if
                end % for
            end % for
        end % if
        
        % Refresh
        if X.X1Link(f) || X.X2Link(f)
            fRefresh;
        else
            fRefresh(f);
        end % if
        
    end % function

    % Toggle Figure
    
    function fToggleFig(~,~,f)
        
        if X.DataSet == 0
            return;
        end % if
        
        if X.Figure(f) == 0

            iOpt = pumFig(f).Value;

            btnFig(f).BackgroundColor = cButtonOn;
            X.Figure(f) = iOpt;
            figure(f); clf;
            aFigSize = [200 200];

            switch(X.Plots{iOpt})

                case 'Beam Density'
                    X.Plot(f).Data    = X.Data.Beam{1};
                    X.Plot(f).Density = X.Data.Density{1};
                    fCtrlBeamDensity(f);
                    aFigSize = [900 500];

                case 'Plasma Density'
                    X.Plot(f).Data       = X.Data.Plasma{1};
                    X.Plot(f).ScatterOpt = ['Off'; X.Data.Beam];
                    X.Plot(f).Scatter    = {'',''};
                    X.Plot(f).ScatterNum = [2000 2000];
                    X.Plot(f).Sample     = [3 3];
                    X.Plot(f).Settings   = [0 0];
                    fCtrlPlasmaDensity(f);
                    aFigSize = [900 500];

                case 'Field Density'
                    X.Plot(f).Data = X.Data.Field{1};
                    fCtrlFieldDensity(f);
                    aFigSize = [900 500];

                case 'Phase 2D'
                    X.Plot(f).Data     = X.Data.Species{1};
                    X.Plot(f).Axis     = {X.Data.Axis{1},X.Data.Axis{3}};
                    X.Plot(f).Settings = [0 0 0];
                    fCtrlPhase2D(f);
                    aFigSize = [700 500];
                    
                case 'XX'' Phase Space'
                    X.Plot(f).Data  = X.Data.Species{1};
                    X.Plot(f).Count = 500000;
                    fCtrlPhaseSpace(f);
                    aFigSize = [700 500];

            end % switch

            if sum(stSettings.Position(f).Pos) == 0
                fFigureSize(figure(f), aFigSize);
            else
                set(figure(f), 'Position', [stSettings.Position(f).Pos aFigSize]);
            end % if

            hTabGroup.SelectedTab = hTabs(f);
            fRefresh(f);

        else
            
            btnFig(f).BackgroundColor = cButtonOff;
            
            X.Figure(f) = 0;
            X.X1Link(f) = 0;
            X.X2Sym(f)  = 0;
            X.Plot(f).MaxLim  = [0.0 0.0 0.0 0.0];
            X.Plot(f).Limits  = [0.0 0.0 0.0 0.0];
            X.Plot(f).LimPres = [2   2   2   2];
            
            aFigPos = get(figure(f), 'Position');
            stSettings.Position(f).Pos  = aFigPos(1:2);
            stSettings.Position(f).Size = aFigPos(3:4);
            fSaveVariables;

            close(figure(f));
            fResetTab(f);
            fRefresh(f);

        end % if
        
    end % function

    function fToggleXFig(~,~,f)
        
        if X.DataSet == 0
            return;
        end % if
        
        if X.Plot(f).Enabled == 0
            btnFig(f).BackgroundColor = cButtonOn;
            X.Plot(f).Enabled = 1;
            fRefreshX
        else
            btnFig(f).BackgroundColor = cButtonOff;
            X.Plot(f).Enabled = 0;
            
            aFigPos = get(figure(f), 'Position');
            stSettings.Position(f).Pos  = aFigPos(1:2);
            stSettings.Position(f).Size = aFigPos(3:4);
            fSaveVariables;

            close(figure(f));
        end % if
        
    end % function

    function fChangeXVal(~,~,f)
        
        if X.DataSet == 0
            return;
        end % if
        fRefreshX(f);
        
    end % function

    % Link and Symmetric Functions
    
    function fLinkX1(~,~)
        
        for f=1:6
            X.X1Link(f) = chkX1(f).Value;
        end % for
        
    end % function

    function fLinkX2(~,~)
        
        for f=1:6
            X.X2Link(f) = chkX2(f).Value;
        end % for
        
    end % function

    function fSymX2(~,~)
        
        for f=1:6
            X.X2Sym(f) = chkS2(f).Value;
        end % for
        
    end % function

    % Common Functions
    
    function fReloadOptions(p)

        % If plot not specified, refresh all plots
        if nargin < 1
            a = 1;
            b = 6;
        else
            a = p;
            b = p;
        end % if
        
        % Refresh all tabs and options
        for f=a:b

            if X.Figure(f) == 0
                continue;
            end % if
            
            switch(X.Plots{X.Figure(f)})

                case 'Beam Density'
                    fResetTab(f);
                    fCtrlBeamDensity(f);

                case 'Plasma Density'
                    fResetTab(f);
                    fCtrlPlasmaDensity(f);

                %case 'Field Density'
                %    fResetTab(f);
                %    fCtrlFieldDensity(f);

                %case 'Phase 2D'
                %    fResetTab(f);
                %    fCtrlPhase2D(f);

                %case 'XX'' Phase Space'
                %    fResetTab(f);
                %    fCtrlPhaseSpace(f);

            end % switch
            
        end % for

    end % function
    
    function fRefresh(p)
        
        % Check dump sanity
        if X.Time.Dump > X.Time.Limits(4)
            X.Time.Dump = X.Time.Limits(4);
        end % if

        % Refresh labels
        set(lblData, 'String', sprintf('%s – #%d', X.Data.Name, X.Time.Dump));
        
        % If plot not specified, refresh all plots
        if nargin < 1
            a = 1;
            b = 6;
        else
            a = p;
            b = p;
        end % if
        
        % Refresh all specified plots in sequence
        for f=a:b
            
            if X.Figure(f) > 0
                
                X.Plot(f).Enabled = 1;
                iMakeSym = 0;

                % Apply limits if > 0
                if sum(X.Plot(f).Limits) > 0
                    aHLim = X.Plot(f).Limits(1:2);
                    aVLim = X.Plot(f).Limits(3:4);
                else
                    aHLim = [];
                    aVLim = [];
                end % if
                
                switch(X.Plots{X.Figure(f)})
                    
                    case 'Beam Density'
                        figure(X.Plot(f).Figure); clf;
                        if strcmpi(X.Plot(f).Density,'charge')
                            sCurrent = '';
                        else
                            sCurrent = fTranslateField(X.Plot(f).Density,'FromLong');
                        end % if
                        iMakeSym = 1;

                        X.Plot(f).Return = fPlotBeamDensity(oData,X.Time.Dump,X.Plot(f).Data,'Current',sCurrent, ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes','Absolute','Yes','ShowOverlay','Yes','Limits',[aHLim aVLim]);

                    case 'Plasma Density'
                        stEF(2) = struct();
                        for s=1:2
                            stEF(s).Range = [];
                            if X.Plot(f).Settings(s)
                                stEF(s).Range = [3,3];
                            end % if
                        end % for
                        iMakeSym = 1;
                            
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotPlasmaDensity(oData,X.Time.Dump,X.Plot(f).Data, ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes','Absolute', 'Yes', ...
                            'Scatter1',X.Plot(f).Scatter{1},'Scatter2',X.Plot(f).Scatter{2}, ...
                            'Sample1',X.Plot(f).ScatterNum(1),'Sample2',X.Plot(f).ScatterNum(2), ...
                            'Overlay1',X.Plot(f).Scatter{1},'Overlay2',X.Plot(f).Scatter{2}, ...
                            'Filter1',X.Opt.Sample{X.Plot(f).Sample(1)},'Filter2',X.Opt.Sample{X.Plot(f).Sample(2)}, ...
                            'E1',stEF(1).Range,'E2',stEF(2).Range, ...
                            'Limits',[aHLim aVLim],'CAxis',[]);
                        
                    case 'Field Density'
                        iMakeSym = 1;
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotField2D(oData,X.Time.Dump,fTranslateField(X.Plot(f).Data,'FromLong'), ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes','Limits',[aHLim aVLim]);

                    case 'Phase 2D'
                        iMakeSym = 0;
                        if X.Plot(f).Settings(1) == 1
                            sUseRaw = 'Yes';
                        else
                            sUseRaw = 'No';
                        end % if
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotPhase2D(oData,X.Time.Dump,X.Plot(f).Data, ...
                            fTranslateAxis(X.Plot(f).Axis{1},'FromLong'), ...
                            fTranslateAxis(X.Plot(f).Axis{2},'FromLong'), ...
                            'HLim',aHLim,'VLim',aVLim,'UseRaw',sUseRaw, ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes');
                        if isempty(X.Plot(f).Return)
                            return;
                        end % if
                        X.Plot(f).Scale = X.Plot(f).Return.AxisScale(1:2);
    
                    case 'XX'' Phase Space'
                        if X.Plot(f).Count < 1
                            iMinPart = 1;
                        else
                            iMinPart = X.Plot(f).Count;
                        end % if
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotPhaseSpace(oData,X.Time.Dump,X.Plot(f).Data, ...
                            'MinParticles',iMinPart, ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes');
                        fOut(sprintf('Sampled %d particles, Erms: %.3f mm·mrad',X.Plot(f).Return.Count,X.Plot(f).Return.ERMS),1);

                    otherwise
                        return;
                                                                       
                end % switch

                if isempty(X.Plot(f).Return)
                    return;
                end % if

                % Set default zoom levels
                if sum(X.Plot(f).MaxLim) == 0.0

                    X.Plot(f).MaxLim = X.Plot(f).Return.AxisRange(1:4);
                    
                    if strcmpi(X.Data.Coords,'cylindrical') && iMakeSym
                        X.Plot(f).MaxLim(3) = -X.Plot(f).MaxLim(4);
                        X.X2Sym(f) = 1;
                    else
                        X.X2Sym(f) = 0;
                    end % if
                    
                    X.Plot(f).Limits = X.Plot(f).MaxLim;

                end % if
                
            end % if
            
            edtXMin(f).String = sprintf('%.2f', X.Plot(f).Limits(1)*X.Plot(f).Scale(1));
            edtXMax(f).String = sprintf('%.2f', X.Plot(f).Limits(2)*X.Plot(f).Scale(1));
            edtYMin(f).String = sprintf('%.2f', X.Plot(f).Limits(3)*X.Plot(f).Scale(2));
            edtYMax(f).String = sprintf('%.2f', X.Plot(f).Limits(4)*X.Plot(f).Scale(2));

            chkX1(f).Value = X.X1Link(f);
            chkX2(f).Value = X.X2Link(f);
            chkS2(f).Value = X.X2Sym(f);
            
            % Set focus to main figure
            figure(fMain);

        end % for
        
    end % function

    function fRefreshX(p)
        
        % If plot not specified, refresh all plots
        if nargin < 1
            a = 7;
            b = iXFig;
        else
            a = p;
            b = p;
        end % if
        
        for f=a:b
            if X.Plot(f).Enabled
                switch(f)

                    case 7
                        sStart = get(edtT8(1),'String');
                        sEnd   = get(edtT8(2),'String');
                        figure(X.Plot(f).Figure); clf;
                        fPlotESigmaMean(oData,X.Plot(f).Data,'Start',sStart,'End',sEnd,'HideDump','Yes','IsSubPlot','No','AutoResize','Off');
                    
                    case 8
                        sStart = get(edtT9(1),'String');
                        sEnd   = get(edtT9(2),'String');
                        figure(X.Plot(f).Figure); clf;
                        fPlotESigmaMeanRatio(oData,X.Data.Witness{1},'Start',sStart,'End',sEnd,'HideDump','Yes','IsSubPlot','No','AutoResize','Off');

                    case 9
                        sStart = get(edtT10(1),'String');
                        sEnd   = get(edtT10(2),'String');
                        figure(X.Plot(f).Figure); clf;
                        fPlotBeamSlip(oData,X.Data.Witness{1},'Start',sStart,'End',sEnd,'HideDump','Yes','IsSubPlot','No','AutoResize','Off');

                    case 10
                        figure(X.Plot(f).Figure); clf;
                        uiTrackDensity(oData);

                end % switch
                
                if sum(stSettings.Position(f).Pos) > 0
                    aFigSize = get(figure(f), 'Position');
                    figure(f).Position = [stSettings.Position(f).Pos aFigSize(3:4)];
                end % if

            end % if
        end % for
        
    end % function
    
    function fSaveVariables
        
        save(strcat(oData.Temp,'/OsirisAnalyseSettings.mat'),'-struct','stSettings');
        
    end % function

    % Control Functions
    
    function fOut(sText, iType)
        
        stCol = {'#00ff00;','#ffdd66;','#ff6666;'};
        if rand >= 0.99
            stPrefix = {'','OOPS: ','WTF: '};
        else
            stPrefix = {'','Warning: ','Error: '};
        end % if
        aTime  = clock;
        sStamp = sprintf('%02d:%02d:%02.0f> ',aTime(4),aTime(5),floor(aTime(6)));
        sText  = sprintf('<html><font style="color: %s">%s%s%s</font></html>',stCol{iType},sStamp,stPrefix{iType},sText);
        
        stCurr = lstOut.String;
        stCurr = [stCurr;{sText}];
        [iN, ~] = size(stCurr);
        
        if iN > 100
            stCurr(1) = [];
            iN = 100;
        end % if

        lstOut.String = stCurr;
        lstOut.Value  = iN;
        
    end % function
    
    function fFocus(~,~)
        
        for f=1:iXFig
            if X.Plot(f).Enabled
                figure(f);
            end % if
        end % for
        figure(fMain);
        
    end % function

    function fShowSimInfo(~,~)
        
    end % function

    function fKeyPress(~,uiEvt)
        
        % Debug
        %disp(uiEvt.Key);
        
        switch(uiEvt.Key)

            % Dump
            case 'uparrow'
                fDump(0,0,10);
            case 'rightarrow'
                fDump(0,0,1);
            case 'leftarrow'
                fDump(0,0,-1);
            case 'downarrow'
                fDump(0,0,-10);
                
            % Jump
            case 'home'
                fJump(0,0,1);
                fOut('Jumping to start of simulation',1);
            case 'pageup'
                fJump(0,0,2);
                fOut('Jumping to start of plasma',1);
            case 'pagedown'
                fJump(0,0,3);
                fOut('Jumping to end of plasma',1);
            case 'end'
                fJump(0,0,4);
                fOut('Jumping to end of simulation',1);
                
            % Control Functions
            case 'f'
                fFocus(0,0);
            case 'i'
                fShowSimInfo(0,0);
            
        end % switch
        
    end % function

    function fSetLoadTo(~,~,iSet)
        
        X.LoadTo = iSet;

        for i=1:3
            mL(i).Checked = 'Off';
        end % for
        mL(iSet).Checked = 'On';
        
    end % function


    %
    %  Update Plots
    % **************
    %
    
    function fPlotSetBeam(uiSrc,~,f)
        
        iBeam = uiSrc.Value;
        sBeam = X.Data.Beam{iBeam};
        
        X.Plot(f).Data = sBeam;
        if f < 7
            fRefresh(f);
        else
            fRefreshX(f);
        end % if
        
    end % function

    function fPlotSetPlasma(uiSrc,~,f)
        
        iPlasma = uiSrc.Value;
        sPlasma = X.Data.Plasma{iPlasma};
        
        X.Plot(f).Data = sPlasma;
        fRefresh(f);
        
    end % function

    function fPlotSetSpecies(uiSrc,~,f)
        
        iSpecies = uiSrc.Value;
        sSpecies = X.Data.Species{iSpecies};
        
        X.Plot(f).Data = sSpecies;
        switch(X.Plots{X.Figure(f)})
            case 'Phase 2D'
                X.Plot(f).MaxLim = [0.0 0.0 0.0 0.0];
                X.Plot(f).Limits = [0.0 0.0 0.0 0.0];
                X.Plot(f).Scale  = [1.0 1.0];
        end % switch
        
        X.Data.Density = oData.Config.Variables.Density.(sSpecies).Density;
        for i=1:length(X.Data.Density)
            X.Data.Density{i} = fTranslateField(X.Data.Density{i},['Long',X.Data.CoordsPF]);
        end % for
        
        fRefresh(f);
        
    end % function

    function fPlotSetScatter(uiSrc,~,f,s)
        
        iScatter = uiSrc.Value;
        sScatter = X.Plot(f).ScatterOpt{iScatter};
        
        if strcmpi(sScatter,'Off')
            X.Plot(f).Scatter{s} = '';
        else
            X.Plot(f).Scatter{s} = sScatter;
        end % if
        
        fRefresh(f);
        
    end % function

    function fPlotSetScatterNum(uiSrc,~,f,s)

        iValue = floor(str2double(uiSrc.String));
        
        if isempty(iValue)
            iValue = 2000;
        end % if
        
        uiSrc.String = sprintf('%d', iValue);
        X.Plot(f).ScatterNum(s) = iValue;
        
        fRefresh(f);
    
    end % function

    function fPlotSetSample(uiSrc,~,f,s)
        
        iValue = uiSrc.Value;
        X.Plot(f).Sample(s) = iValue;
        fRefresh(f);
        
    end % function

    function fPlotSetField(uiSrc,~,f)
        
        iField = uiSrc.Value;
        sField = X.Data.Field{iField};
        
        X.Plot(f).Data = sField;
        fRefresh(f);
        
    end % function

    function fPlotSetPhase(uiSrc,~,a,f)
        
        iAxis = uiSrc.Value;
        sAxis = X.Data.Axis{iAxis};
        
        X.Plot(f).Axis{a} = sAxis;
        switch(X.Plots{X.Figure(f)})
            case 'Phase 2D'
                X.Plot(f).MaxLim = [0.0 0.0 0.0 0.0];
                X.Plot(f).Limits = [0.0 0.0 0.0 0.0];
                X.Plot(f).Scale  = [1.0 1.0];
        end % switch        
        fRefresh(f);
        
    end % function

    function fPlotSetDensity(uiSrc,~,f)
        
        iDensity = uiSrc.Value;
        sDensity = X.Data.Density{iDensity};
        
        X.Plot(f).Density = sDensity;
        fRefresh(f);
        
    end % function

    function fPlotSetting(uiSrc,~,f,s)
    
        X.Plot(f).Settings(s) = uiSrc.Value;
        fRefresh(f);

    end % function

    function fPlotSetCount(uiSrc,~,f)
    
        iValue = floor(str2double(uiSrc.String));

        if isempty(iValue)
            iValue = 500000;
        end % if
        
        uiSrc.String = sprintf('%d', iValue);
        X.Plot(f).Count = iValue;

        fRefresh(f);

    end % function
   
end % function

% End
