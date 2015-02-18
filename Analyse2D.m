
%
%  GUI :: Analyse 2D Data
% ************************
%

function X = Analyse2D

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
    cButtonOff   = [0.7 0.7 0.7];
    cButtonOn    = [0.8 0.4 0.8];
    
    % Data
    
    oData = OsirisData;
    
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
    X.X2Sym  = [1 1 1 1 1 1];
    
    for f=1:6
        X.Plot(f).Figure  = f+1;
        X.Plot(f).Enabled = 0;
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
    
    lblData = uicontrol('Style','Text','String','No data','FontSize',18,'Position',[320 500 200 25],'ForegroundColor',cInfoText,'BackgroundColor',cInfoBack);


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

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[280 390 140 100],'BackgroundColor',cBackGround);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 10 60 30 20],'Callback',@fJumpPrev);
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[ 40 60 30 20],'Callback',@fSkipPrev);
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[ 70 60 30 20],'Callback',@fSkipNext);
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[100 60 30 20],'Callback',@fJumpNext);

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 10 35 30 20],'Callback',@fGoStart);
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[ 40 35 30 20],'Callback',@fGoPStart);
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[ 70 35 30 20],'Callback',@fGoPEnd);
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[100 35 30 20],'Callback',@fGoEnd);

    lblStart  = uicontrol(bgTime,'Style','Text','String','0',  'Position',[ 11 12 28 15]);
    lblPStart = uicontrol(bgTime,'Style','Text','String','10', 'Position',[ 41 12 28 15]);
    lblPEnd   = uicontrol(bgTime,'Style','Text','String','105','Position',[ 71 12 28 15]);
    lblEnd    = uicontrol(bgTime,'Style','Text','String','110','Position',[101 12 28 15]);

    
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
        
        pumFig(f)  = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35 aY(f) 150 20],'Callback',@fSetFig);
        btnFig(f)  = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190 aY(f) 20 20],'BackgroundColor',cButtonOff,'Callback',{@fToggleFig,f});
        
        edtXMin(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215 aY(f) 55 20],'Callback',{@fZoom,f});
        edtXMax(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295 aY(f) 55 20],'Callback',{@fZoom,f});
        edtYMin(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355 aY(f) 55 20],'Callback',{@fZoom,f});
        edtYMax(f) = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435 aY(f) 55 20],'Callback',{@fZoom,f});

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
        
        delete(bgTab(t));
        bgTab(t) = uibuttongroup(hTabs(t),'Title','','Units','Pixels','Position',[3 3 400 120],'BackgroundColor',cBackGround);
        
        iY = 115;
        
        iY = iY - 25;
        uicontrol(bgTab(t),'Style','Text','String','Beam:','Position',[10 iY+1 50 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
        pumBeam(t) = uicontrol(bgTab(t),'Style','PopupMenu','String',X.Data.Beam,'Value',1,'Position',[65 iY 150 20],'Callback',{@fPlotSetBeam,t});
        
    end % function
    

    %
    %  Functions
    % ***********
    %
    
    % Load Data Callback
    
    function fLoadSet(~,~,iSet)
        
        for i=1:3
            set(btnSet(i), 'BackgroundColor', cButtonOff);
        end % for
        set(btnSet(iSet), 'BackgroundColor', cButtonOn);
        
        stSettings.LoadData{i} = get(edtSet(i), 'String');

        oData.Path = stSettings.LoadData{i};
        X.Data     = {};

        X.Data.Beam   = oData.Config.Variables.Species.Beam;
        X.Data.Plasma = oData.Config.Variables.Species.Plasma;
        
        fSaveVariables;
        
    end % function

    % Toggle Figure
    
    function fToggleFig(~,~,f)
        
        if X.Figure(f) == 0

            iOpt = get(pumFig(f), 'Value');

            set(btnFig(f), 'BackgroundColor', cButtonOn);
            X.Figure(f) = iOpt;
            figure(f+1); clf;

            switch(iOpt)

                % Plot Beam Density
                case 1
                    fCtrlBeamDensity(f);
                    X.Plot(f).Beam = X.Data.Beam{1};
                    
            end % switch

            set(hTabGroup,'SelectedTab',hTabs(f));
            fRefresh;

        else
            
            set(btnFig(f), 'BackgroundColor', cButtonOff);
            X.Figure(f) = 0;
            close(figure(f+1));
            fResetTab(f);

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
                
                switch(X.Figure(f))
                    
                    % Plot Beam Density
                    case 1
                        figure(X.Plot(f).Figure); clf;
                        X.Plot(f).Return = fPlotBeamDensity(oData, 0, X.Plot(f).Beam, ...
                                                'IsSubPlot', 'No', ...
                                                'HideDump', 'Yes', ...
                                                'Absolute', 'Yes', ...
                                                'ShowOverlay', 'Yes');
                        
                end % switch
                
            end % if
            
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
        
        X.Plot(f).Beam = sBeam;
        fRefresh(f);
        
    end % function

   
end % function
