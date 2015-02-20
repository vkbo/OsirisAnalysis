
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
    
    cBackGround  = [0.8 0.8 0.8];
    cWhite       = [1.0 1.0 1.0];
    cInfoText    = [1.0 0.9 0.0];
    cGreyText    = [0.5 0.5 0.5];
    cInfoBack    = [0.7 0.7 0.7];
    cInfoR       = [1.0 0.5 0.5];
    cInfoY       = [1.0 1.0 0.5];
    cInfoG       = [0.5 1.0 0.5];
    cWarningBack = [1.0 0.5 0.5];
    cButtonOff   = [0.7 0.7 0.7];
    cButtonOn    = [0.8 0.4 0.8];
    
    % Data
    
    oData = OsirisData;

    X.Time.Dump   = 0;
    X.Time.Limits = [0 0 0 0];
    
    % Settings
    
    if exist('/tmp/osiris_analyse_settings.mat', 'file')
        stSettings = load('/tmp/osiris_analyse_settings.mat');
    else
        stSettings.LoadData = {'','',''};
    end % if

    X.Plots{1} = 'Beam Density';
    X.Plots{2} = 'Plasma Density';

    X.Figure = [0 0 0 0 0 0];
    X.X1Link = [0 0 0 0 0 0];
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
    set(fMain, 'Position', [aFPos(1:2) 540 540]);
    set(fMain, 'Color', cBackGround);
    set(fMain, 'Name', 'Osiris 2D Analysis');


    %
    %  Create Controls
    % *****************
    %
    
    set(0, 'CurrentFigure', fMain);
    uicontrol('Style','Text','String','Controls','FontSize',20,'Position',[20 502 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    
    lblData = uicontrol('Style','Text','String','No Data','FontSize',18,'Position',[220 500 300 25],'ForegroundColor',cInfoText,'BackgroundColor',cInfoBack);


    %  Data Set Controls
    % ===================

    bgData = uibuttongroup('Title','Load Data','Units','Pixels','Position',[20 390 250 100],'BackgroundColor',cBackGround);
    
    aY = [60 35 10];
    for i=1:3
        uicontrol(bgData,'Style','Text','String',sprintf('#%d',i),'Position',[10 aY(i)+2 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        uicontrol(bgData,'Style','PushButton','String','...','Position',[160 aY(i) 25 20],'Callback',{@fBrowseSet,i});
        
        edtSet(i) = uicontrol(bgData,'Style','Edit','String',stSettings.LoadData{i},'Position',[35 aY(i) 120 20]);
        btnSet(i) = uicontrol(bgData,'Style','PushButton','String','Load','Position',[190 aY(i) 50 20],'BackgroundColor',cButtonOff,'Callback',{@fLoadSet,i});
    end % for
    

    %  Time Dump Controls
    % ====================

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[280 390 240 100],'BackgroundColor',cBackGround);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 10 60 30 20],'Callback',{@fDump, -10});
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[ 40 60 30 20],'Callback',{@fDump,  -1});
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[ 70 60 30 20],'Callback',{@fDump,   1});
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[100 60 30 20],'Callback',{@fDump,  10});

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 10 35 30 20],'Callback',{@fJump, 1});
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[ 40 35 30 20],'Callback',{@fJump, 2});
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[ 70 35 30 20],'Callback',{@fJump, 3});
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[100 35 30 20],'Callback',{@fJump, 4});

    lblDump(1) = uicontrol(bgTime,'Style','Text','String','0',  'Position',[ 11 11 28 15]);
    lblDump(2) = uicontrol(bgTime,'Style','Text','String','10', 'Position',[ 41 11 28 15]);
    lblDump(3) = uicontrol(bgTime,'Style','Text','String','105','Position',[ 71 11 28 15]);
    lblDump(4) = uicontrol(bgTime,'Style','Text','String','110','Position',[101 11 28 15]);
    
    lblInfo(1) = uicontrol(bgTime,'Style','Text','String','Geometry','Position',[140 61 90 15]);
    lblInfo(2) = uicontrol(bgTime,'Style','Text','String','Status','Position',[140 36 90 15]);
    lblInfo(3) = uicontrol(bgTime,'Style','Text','String','Tracks','Position',[140 11 90 15]);

    
    %  Figure Controls
    % =================

    bgFigs = uibuttongroup('Title','Figures','Units','Pixels','Position',[20 180 500 200],'BackgroundColor',cBackGround);
    
    uicontrol(bgFigs,'Style','Text','String','Fig',      'Position',[ 10 160  20 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','Plot Type','Position',[ 35 160 150 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','On',       'Position',[190 160  20 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','X-Min',    'Position',[215 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','| ',       'Position',[275 160  15 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','X-Max',    'Position',[295 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','Y-Min',    'Position',[355 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','—',        'Position',[415 160  15 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','Y-Max',    'Position',[435 160  55 15],'HorizontalAlignment','Center');

    aY = [135 110 85 60 35 10];
    for f=1:6
        uicontrol(bgFigs,'Style','Text','String',sprintf('#%d',f+1),'Position',[10 aY(f)+1 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        
        pumFig(f)  = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35 aY(f) 150 20]);
        btnFig(f)  = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190 aY(f) 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleFig,f});
        
        edtXMin(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215 aY(f) 55 20],'Callback',{@fZoom,1,f});
        edtXMax(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295 aY(f) 55 20],'Callback',{@fZoom,2,f});
        edtYMin(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355 aY(f) 55 20],'Callback',{@fZoom,3,f});
        edtYMax(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435 aY(f) 55 20],'Callback',{@fZoom,4,f});

        chkX1(f)   = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(f),'Position',[275 aY(f)+2 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
        chkX2(f)   = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(f), 'Position',[415 aY(f)+2 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    end % for
    

    %  Tabs
    % ======

    s = warning('off', 'MATLAB:uitabgroup:OldVersion');
    hTabGroup = uitabgroup('Units','Pixels','Position',[17 20 406 150],'BackgroundColor',cBackGround);
    warning(s);
    
    for t=1:6
        hTabs(t) = uitab(hTabGroup,'Title',sprintf('Plot %d', t+1));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 400 120],'BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Text','String','No settings','FontSize',15,'Position',[10 85 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround,'ForegroundColor',cGreyText);
    end % for
    
    
    %
    %  Tab Controls
    % **************
    %
    
    function fResetTab(t)

        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 400 120],'BackgroundColor',cBackGround);
        uicontrol(bgTab(t),'Style','Text','String','No settings','FontSize',15,'Position',[10 85 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround,'ForegroundColor',cGreyText);

    end % function
    
    function fCtrlBeamDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 400 120],'BackgroundColor',cBackGround);
        
        % Create Controls
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Beam','Position',[10 iY+1 70 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        pumData(t) = uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Beam,'Value',1,'Position',[85 iY 150 20],'Callback',{@fPlotSetBeam,t});
        
    end % function

    function fCtrlPlasmaDensity(t)
        
        % Clear panel
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 400 120],'BackgroundColor',cBackGround);
        
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
        X.Data     = {};

        X.Data.Name      = oData.Config.Name;
        X.Data.Beam      = oData.Config.Variables.Species.Beam;
        X.Data.Plasma    = oData.Config.Variables.Species.Plasma;
        X.Data.Completed = oData.Config.Completed;
        X.Data.HasData   = oData.Config.HasData;
        X.Data.HasTracks = oData.Config.HasTracks;
        X.Data.Coords    = oData.Config.Variables.Simulation.Coordinates;
        
        % Geometry
        if strcmpi(X.Data.Coords, 'cylindrical')
            set(lblInfo(1),'String','Cylindrical','BackgroundColor',cInfoG);
        else
            set(lblInfo(1),'String','Cartesian','BackgroundColor',cInfoG);
        end % if
        
        % Simulation Status
        if X.Data.HasData
            if X.Data.Completed
                set(lblInfo(2),'String','Completed','BackgroundColor',cInfoG);
            else
                set(lblInfo(2),'String','Incomplete','BackgroundColor',cInfoY);
            end % if
        else
            set(lblInfo(2),'String','No Data','BackgroundColor',cInfoR);
        end % if
        
        % Tracking Data
        if X.Data.HasTracks
            set(lblInfo(3),'String','Has Tracks','BackgroundColor',cInfoG);
        else
            set(lblInfo(3),'String','No Tracks','BackgroundColor',cInfoY);
        end % if
        
        X.Time.Limits(1) = fStringToDump(oData, 'Start');
        X.Time.Limits(2) = fStringToDump(oData, 'PStart');
        X.Time.Limits(3) = fStringToDump(oData, 'PEnd');
        X.Time.Limits(4) = fStringToDump(oData, 'End');
        
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
        
        if X.X1Link(f)
            fRefresh;
        else
            fRefresh(f);
        end % if
        
    end % function

    % Toggle Figure
    
    function fToggleFig(~,~,f)
        
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

    function fSymX2(~,~)
        
        for f=1:6
            X.X2Sym(f) = get(chkX2(f), 'Value');
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
            set(chkX2(f), 'Value', X.X2Sym(f));

        end % for
        
    end % function
    
    function fSaveVariables
        
        save('/tmp/osiris_analyse_settings.mat','-struct','stSettings');
        
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
   
end % function





% End