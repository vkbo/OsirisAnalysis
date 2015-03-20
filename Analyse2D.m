
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
    cInfoText    = [1.00 1.00 0.00];
    cGreyText    = [0.50 0.50 0.50];
    cInfoBack    = [0.80 0.80 0.80];
    cInfoR       = [1.00 0.50 0.50];
    cInfoY       = [1.00 1.00 0.50];
    cInfoG       = [0.50 1.00 0.50];
    cWarningBack = [1.00 0.50 0.50];
    cButtonOff   = [0.80 0.80 0.80];
    cButtonOn    = [0.85 0.40 0.85];
    
    % Data
    
    oData = OsirisData('Silent','Yes');

    X.DataSet     = 0;
    X.Time.Dump   = 0;
    X.Time.Limits = [0 0 0 0];
    
    % Settings
    
    if exist(strcat(oData.Temp, '/OsirisAnalyseSettings.mat'), 'file')
        stSettings = load(strcat(oData.Temp, '/OsirisAnalyseSettings.mat'));
    else
        stSettings.LoadData = {'','',''};
    end % if

    X.Plots{1} = 'Beam Density';
    X.Plots{2} = 'Plasma Density';
    X.Plots{3} = 'Field Density';

    X.Figure = [0 0 0 0 0 0];
    X.X1Link = [0 0 0 0 0 0];
    X.X2Link = [0 0 0 0 0 0];
    X.X2Sym  = [0 0 0 0 0 0];
    
    for f=1:6
        X.Plot(f).Figure  = f+1;
        X.Plot(f).Enabled = 0;
        X.Plot(f).MaxLim  = [0.0 0.0 0.0 0.0];
        X.Plot(f).Limits  = [0.0 0.0 0.0 0.0];
    end % for

    
    %
    %  Main Figure
    % *************
    %
    
    % Figure Controls
    fMain = figure(1); clf;
    aFPos = get(fMain, 'Position');
    
    % Set figure properties
    
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'Position', [aFPos(1:2) 560 540]);
    set(fMain, 'Name', 'Osiris 2D Analysis');
    
    % Set background color to default
    cBackGround = get(fMain, 'Color');

    %
    %  Create Controls
    % *****************
    %
    
    set(0, 'CurrentFigure', fMain);
    uicontrol('Style','Text','String','Controls','FontSize',20,'Position',[20 502 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    
    lblData = uicontrol('Style','Text','String','No Data','FontSize',18,'Position',[240 500 300 25],'ForegroundColor',cInfoText,'BackgroundColor',cInfoBack);


    %  Data Set Controls
    % ===================

    bgData = uibuttongroup('Title','Load Data','Units','Pixels','Position',[20 390 250 100],'BackgroundColor',cBackGround);
    
    aY = [60 35 10];
    for i=1:3
        uicontrol(bgData,'Style','Text','String',sprintf('#%d',i),'Position',[9 aY(i)+2 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgData,'Style','PushButton','String','...','Position',[159 aY(i) 25 20],'BackgroundColor',cButtonOff,'Callback',{@fBrowseSet,i});
        
        edtSet(i) = uicontrol(bgData,'Style','Edit','String',stSettings.LoadData{i},'Position',[34 aY(i) 120 20],'BackgroundColor',cWhite);
        btnSet(i) = uicontrol(bgData,'Style','PushButton','String','Load','Position',[189 aY(i) 50 20],'BackgroundColor',cButtonOff,'Callback',{@fLoadSet,i});
    end % for
    

    %  Time Dump Controls
    % ====================

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[280 390 140 100],'BackgroundColor',cBackGround);

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

    bgInfo = uibuttongroup('Title','Sim. Info','Units','Pixels','Position',[430 390 110 100],'BackgroundColor',cBackGround);
    
    lblInfo(1) = uicontrol(bgInfo,'Style','Text','String','Geometry','Position',[9 60 90 17],'BackgroundColor',cInfoBack);
    lblInfo(2) = uicontrol(bgInfo,'Style','Text','String','Status',  'Position',[9 35 90 17],'BackgroundColor',cInfoBack);
    lblInfo(3) = uicontrol(bgInfo,'Style','Text','String','Tracks',  'Position',[9 10 90 17],'BackgroundColor',cInfoBack);

    
    %  Figure Controls
    % =================

    bgFigs = uibuttongroup('Title','Figures','Units','Pixels','Position',[20 180 520 200],'BackgroundColor',cBackGround);
    
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
    for f=1:6
        uicontrol(bgFigs,'Style','Text','String',sprintf('#%d',f+1),'Position',[9 aY(f)+1 25 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        
        pumFig(f)  = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[34 aY(f) 150 20]);
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

    s = warning('off', 'MATLAB:uitabgroup:OldVersion');
    hTabGroup = uitabgroup('Units','Pixels','Position',[20 20 520 150]);
    warning(s);
    
    for t=1:6
        hTabs(t) = uitab(hTabGroup,'Title',sprintf('Plot %d', t+1));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','BorderType','None','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Text','String','No settings','FontSize',15,'Position',[10 85 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround,'ForegroundColor',cGreyText);
    end % for
    
    
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
        uicontrol(bgTab(t),'Style','Text','String','Beam','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        pumData(t) = uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Beam,'Value',1,'Position',[85 iY 150 20],'Callback',{@fPlotSetBeam,t});
        
    end % function

    function fCtrlPlasmaDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Plasma','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        pumData(t) = uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Plasma,'Value',1,'Position',[85 iY 150 20],'Callback',{@fPlotSetPlasma,t});

        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Scatter 1','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Plot(t).ScatterOpt,'Position',[85 iY 150 20],'Callback',{@fPlotSetScatter,t,1});
        uicontrol(bgTab(t),'Style','Text','String','Particles','Position',[240 iY+1 60 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Edit','String',sprintf('%d',X.Plot(t).ScatterNum(1)),'Position',[305 iY 60 20],'Callback',{@fPlotSetScatterNum,t,1});

        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Scatter 2','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','PopupMenu','String',X.Plot(t).ScatterOpt,'Position',[85 iY 150 20],'Callback',{@fPlotSetScatter,t,2});
        uicontrol(bgTab(t),'Style','Text','String','Particles','Position',[240 iY+1 60 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Edit','String',sprintf('%d',X.Plot(t).ScatterNum(2)),'Position',[305 iY 60 20],'Callback',{@fPlotSetScatterNum,t,2});
        
    end % function
    
    function fCtrlFieldDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 514 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Field','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        pumData(t) = uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Field,'Value',1,'Position',[85 iY 150 20],'Callback',{@fPlotSetField,t});
        
    end % function


    %
    %  Functions
    % ***********
    %
    
    % Load Data Callback
    
    function fLoadSet(~,~,iSet)
        
        for i=1:3
            set(btnSet(i), 'BackgroundColor', cButtonOff);
            stSettings.LoadData{i} = get(edtSet(i), 'String');
        end % for
        set(btnSet(iSet), 'BackgroundColor', cButtonOn);

        oData.Path = stSettings.LoadData{iSet};
        X.DataSet  = iSet;
        X.Data     = {};

        X.Data.Name      = oData.Config.Name;
        X.Data.Beam      = oData.Config.Variables.Species.Beam;
        X.Data.Plasma    = oData.Config.Variables.Species.Plasma;
        X.Data.Field     = oData.Config.Variables.Fields.Field;
        X.Data.Completed = oData.Config.Completed;
        X.Data.HasData   = oData.Config.HasData;
        X.Data.HasTracks = oData.Config.HasTracks;
        X.Data.Coords    = oData.Config.Variables.Simulation.Coordinates;
        
        % Geometry
        if strcmpi(X.Data.Coords, 'cylindrical')
            set(lblInfo(1),'String','Cylindrical','BackgroundColor',cInfoG);
            X.Data.CoordsPF = 'Cyl';
        else
            set(lblInfo(1),'String','Cartesian','BackgroundColor',cInfoG);
            X.Data.CoordsPF = '';
        end % if
        
        % Translate Fields
        for i=1:length(X.Data.Field)
            X.Data.Field{i} = fTranslateField(X.Data.Field{i},['Long',X.Data.CoordsPF]);
        end % for
        
        % Simulation Status
        if X.Data.HasData
            if X.Data.Completed
                set(lblInfo(2),'String','Completed','BackgroundColor',cInfoG);
            else
                set(lblInfo(2),'String','Incomplete','BackgroundColor',cInfoY);
            end % if

            X.Time.Limits(1) = fStringToDump(oData, 'Start');
            X.Time.Limits(2) = fStringToDump(oData, 'PStart');
            X.Time.Limits(3) = fStringToDump(oData, 'PEnd');
            X.Time.Limits(4) = fStringToDump(oData, 'End');
        else
            set(lblInfo(2),'String','No Data','BackgroundColor',cInfoR);
            X.Time.Limits = [0 0 0 0];
        end % if
        
        % Tracking Data
        if X.Data.HasTracks
            set(lblInfo(3),'String','Has Tracks','BackgroundColor',cInfoG);
        else
            set(lblInfo(3),'String','No Tracks','BackgroundColor',cInfoY);
        end % if
                
        % Reset dump boxes
        for i=1:4
            set(lblDump(i), 'BackgroundColor', cInfoBack);
        end % for

        % Check that plasma start/end does not extend past the end of the simulation
        if X.Time.Limits(2) > X.Time.Limits(4)
            X.Time.Limits(2) = X.Time.Limits(4);
            set(lblDump(2), 'BackgroundColor', cWarningBack);
        end % if
        if X.Time.Limits(3) > X.Time.Limits(4)
            X.Time.Limits(3) = X.Time.Limits(4);
            set(lblDump(3), 'BackgroundColor', cWarningBack);
        end % if
        
        % Update Time Dump labels
        for i=1:4
            set(lblDump(i), 'String', X.Time.Limits(i));
        end % for
        
        % Refresh
        fRefresh;
        
        % save settings to file
        fSaveVariables;
        
    end % function

    % Time Dump
    
    function fDump(~,~,iStep)
        
        X.Time.Dump = X.Time.Dump + iStep;
        
        if X.Time.Dump < X.Time.Limits(1)
            X.Time.Dump = X.Time.Limits(1);
        end % if

        if X.Time.Dump > X.Time.Limits(4)
            X.Time.Dump = X.Time.Limits(4);
        end % if
        
        fRefresh;
        
    end % function

    function fJump(~,~,iJump)
        
        X.Time.Dump = X.Time.Limits(iJump);
        
        fRefresh;
        
    end % function

    % Zoom
    
    function fZoom(uiSrc,~,iDim,f)
        
        % Collect values
        dValue = str2num(get(uiSrc,'String'));
        
        if ~isempty(dValue)
            X.Plot(f).Limits(iDim) = dValue;
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
                    X.Plot(i).Limits(1:2) = X.Plot(f).Limits(1:2);
                end % if
            end % for
        end % if

        % Check to update other Y limit
        if X.X2Sym(f)
            switch(iDim)
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
                    X.Plot(i).Limits(3:4) = X.Plot(f).Limits(3:4);
                end % if
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

            iOpt = get(pumFig(f), 'Value');

            set(btnFig(f), 'BackgroundColor', cButtonOn);
            X.Figure(f) = iOpt;
            figure(f+1); clf;

            switch(X.Plots{iOpt})

                case 'Beam Density'
                    X.Plot(f).Data = X.Data.Beam{1};
                    fCtrlBeamDensity(f);
                    fFigureSize(figure(f+1), [900 500]);

                case 'Plasma Density'
                    X.Plot(f).Data = X.Data.Plasma{1};
                    X.Plot(f).ScatterOpt = ['Off'; X.Data.Beam];
                    X.Plot(f).Scatter = {'',''};
                    X.Plot(f).ScatterNum = [2000 2000];
                    fCtrlPlasmaDensity(f);
                    fFigureSize(figure(f+1), [900 500]);
                    
                case 'Field Density'
                    X.Plot(f).Data = X.Data.Field{1};
                    fCtrlFieldDensity(f);
                    fFigureSize(figure(f+1), [900 500]);

            end % switch

            set(hTabGroup,'SelectedTab',hTabs(f));
            fRefresh(f);

        else
            
            set(btnFig(f), 'BackgroundColor', cButtonOff);
            X.Figure(f) = 0;
            X.X1Link(f) = 0;
            X.X2Sym(f)  = 0;
            X.Plot(f).MaxLim = [0.0 0.0 0.0 0.0];
            X.Plot(f).Limits = [0.0 0.0 0.0 0.0];
            close(figure(f+1));
            fResetTab(f);
            fRefresh(f);

        end % if
        
    end % function

    % Link and Symmetric Functions
    
    function fLinkX1(~,~)
        
        for f=1:6
            X.X1Link(f) = get(chkX1(f), 'Value');
        end % for
        
    end % function

    function fLinkX2(~,~)
        
        for f=1:6
            X.X2Link(f) = get(chkX2(f), 'Value');
        end % for
        
    end % function

    function fSymX2(~,~)
        
        for f=1:6
            X.X2Sym(f) = get(chkS2(f), 'Value');
        end % for
        
    end % function

    % Common Functions
    
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

                % Apply limits if > 0
                if sum(X.Plot(f).Limits) > 0
                    aLim = X.Plot(f).Limits;
                else
                    aLim = [];
                end % if
                
                switch(X.Plots{X.Figure(f)})
                    
                    case 'Beam Density'
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotBeamDensity(oData,X.Time.Dump,X.Plot(f).Data, ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes','Absolute','Yes','ShowOverlay','Yes','Limits',aLim);

                    case 'Plasma Density'
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotPlasmaDensity(oData,X.Time.Dump,X.Plot(f).Data, ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes','Absolute', 'Yes', ...
                            'Scatter1',X.Plot(f).Scatter{1},'Scatter2',X.Plot(f).Scatter{2}, ...
                            'Sample1',X.Plot(f).ScatterNum(1),'Sample2',X.Plot(f).ScatterNum(2), ...
                            'Overlay1',X.Plot(f).Scatter{1},'Overlay2',X.Plot(f).Scatter{2}, ...
                            'Limits',aLim,'CAxis',[0 5]);
                        
                    case 'Field Density'
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotField2D(oData,X.Time.Dump,fTranslateField(X.Plot(f).Data,'FromLong'), ...
                            'IsSubPlot','No','AutoResize','Off','HideDump','Yes','Limits',aLim);

                    otherwise
                        return;
                                                                       
                end % switch
                
                % Set default zoom levels
                if sum(X.Plot(f).MaxLim) == 0.0

                    X.Plot(f).MaxLim = X.Plot(f).Return.AxisRange(1:4);
                    
                    if strcmpi(X.Data.Coords,'cylindrical')
                        X.Plot(f).MaxLim(3) = -X.Plot(f).MaxLim(4);
                        X.X2Sym(f) = 1;
                    else
                        X.X2Sym(f) = 0;
                    end % if
                    
                    X.Plot(f).Limits = X.Plot(f).MaxLim;

                end % if
                
            end % if
            
            set(edtXMin(f), 'String', sprintf('%.2f', X.Plot(f).Limits(1)));
            set(edtXMax(f), 'String', sprintf('%.2f', X.Plot(f).Limits(2)));
            set(edtYMin(f), 'String', sprintf('%.2f', X.Plot(f).Limits(3)));
            set(edtYMax(f), 'String', sprintf('%.2f', X.Plot(f).Limits(4)));

            set(chkX1(f), 'Value', X.X1Link(f));
            set(chkX2(f), 'Value', X.X2Link(f));
            set(chkS2(f), 'Value', X.X2Sym(f));

        end % for
        
    end % function
    
    function fSaveVariables
        
        save(strcat(oData.Temp,'/OsirisAnalyseSettings.mat'),'-struct','stSettings');
        
    end % function


    %
    %  Update Plots
    % **************
    %
    
    function fPlotSetBeam(uiSrc,~,f)
        
        iBeam = get(uiSrc,'Value');
        sBeam = X.Data.Beam{iBeam};
        
        X.Plot(f).Data = sBeam;
        fRefresh(f);
        
    end % function

    function fPlotSetPlasma(uiSrc,~,f)
        
        iPlasma = get(uiSrc,'Value');
        sPlasma = X.Data.Plasma{iPlasma};
        
        X.Plot(f).Data = sPlasma;
        fRefresh(f);
        
    end % function

    function fPlotSetScatter(uiSrc,~,f,s)
        
        iScatter = get(uiSrc,'Value');
        sScatter = X.Plot(f).ScatterOpt{iScatter};
        
        if strcmpi(sScatter,'Off')
            X.Plot(f).Scatter{s} = '';
        else
            X.Plot(f).Scatter{s} = sScatter;
        end % if
        
        fRefresh(f);
        
    end % function

    function fPlotSetScatterNum(uiSrc,~,f,s)

        iValue = str2num(get(uiSrc,'String'));
        iValue = floor(iValue);
        
        if isempty(iValue)
            iValue = 2000;
        end % if
        
        set(uiSrc, 'String', sprintf('%d', iValue));
        X.Plot(f).ScatterNum(s) = iValue;
        
        fRefresh(f);
    
    end % function

    function fPlotSetField(uiSrc,~,f)
        
        iField = get(uiSrc,'Value');
        sField = X.Data.Field{iField};
        
        X.Plot(f).Data = sField;
        fRefresh(f);
        
    end % function
   
end % function

% End