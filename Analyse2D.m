
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
   
    X.Figure = [0 0 0 0 0 0 0];
    X.X1Link = [0 0 0 0 0 0 0];
    X.X2Sym  = [1 1 1 1 1 1 1];
    
    %
    %  Main Figure
    % *************
    %
    
    % Figure Controls
    fMain = figure(1); clf;
    aFPos = get(fMain, 'Position');
    
    % Set figure properties
    
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'Position', [aFPos(1:2) 540 400]);
    set(fMain, 'Color', cBackGround);
    set(fMain, 'Name', 'Osiris 2D Analysis');

    %
    %  Create Controls
    % *****************
    %
    
    set(0, 'CurrentFigure', fMain);
    uicontrol('Style','Text','String','Controls','FontSize',20,'Position',[20 362 140 25],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    
    lblData = uicontrol('Style','Text','String','No data','FontSize',18,'Position',[320 360 200 25],'ForegroundColor',cInfoText,'BackgroundColor',cInfoBack);

    %  Data Set Controls
    % ===================

    bgData = uibuttongroup('Title','Load Data','Units','Pixels','Position',[20 250 250 100],'BackgroundColor',cBackGround);
    
    uicontrol(bgData,'Style','Text','String','#3','Position',[10 12 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgData,'Style','Text','String','#2','Position',[10 37 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgData,'Style','Text','String','#1','Position',[10 62 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    edtSet3 = uicontrol(bgData,'Style','Edit','String',stSettings.LoadData{3},'Position',[35 10 120 20]);
    edtSet2 = uicontrol(bgData,'Style','Edit','String',stSettings.LoadData{2},'Position',[35 35 120 20]);
    edtSet1 = uicontrol(bgData,'Style','Edit','String',stSettings.LoadData{1},'Position',[35 60 120 20]);

    uicontrol(bgData,'Style','PushButton','String','...','Position',[160 10 25 20],'Callback',@fBrowseSet3);
    uicontrol(bgData,'Style','PushButton','String','...','Position',[160 35 25 20],'Callback',@fBrowseSet2);
    uicontrol(bgData,'Style','PushButton','String','...','Position',[160 60 25 20],'Callback',@fBrowseSet1);
    
    btnSet3 = uicontrol(bgData,'Style','PushButton','String','Load','Position',[190 10 50 20],'BackgroundColor',cButtonOff,'Callback',@fLoadSet3);
    btnSet2 = uicontrol(bgData,'Style','PushButton','String','Load','Position',[190 35 50 20],'BackgroundColor',cButtonOff,'Callback',@fLoadSet2);
    btnSet1 = uicontrol(bgData,'Style','PushButton','String','Load','Position',[190 60 50 20],'BackgroundColor',cButtonOff,'Callback',@fLoadSet1);

    
    %  Time Dump Controls
    % ====================

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[280 250 140 100],'BackgroundColor',cBackGround);

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

    %edtDumpN = uicontrol(bgTime,'Style','Edit','String',sprintf('%d',  X.Time.Dump),'Position',[ 145 35 45 20],'Callback',@fEditDump);
    %edtDumpL = uicontrol(bgTime,'Style','Edit','String',sprintf('%.2f',X.Time.ZPos),'Position',[ 145 10 45 20]);

    
    %  Figure Controls
    % =================

    bgFigs = uibuttongroup('Title','Figures','Units','Pixels','Position',[20 40 500 200],'BackgroundColor',cBackGround);
    
    uicontrol(bgFigs,'Style','Text','String','Fig',      'Position',[ 10 160  20 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','Plot Type','Position',[ 35 160 150 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','On',       'Position',[190 160  20 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','X-Min',    'Position',[215 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','| ',       'Position',[275 160  15 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','X-Max',    'Position',[295 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','Y-Min',    'Position',[355 160  55 15],'HorizontalAlignment','Center');
    uicontrol(bgFigs,'Style','Text','String','—',        'Position',[415 160  15 15],'HorizontalAlignment','Left');
    uicontrol(bgFigs,'Style','Text','String','Y-Max',    'Position',[435 160  55 15],'HorizontalAlignment','Center');

    uicontrol(bgFigs,'Style','Text','String','#7','Position',[10  12 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgFigs,'Style','Text','String','#6','Position',[10  37 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgFigs,'Style','Text','String','#5','Position',[10  62 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgFigs,'Style','Text','String','#4','Position',[10  87 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgFigs,'Style','Text','String','#3','Position',[10 112 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    uicontrol(bgFigs,'Style','Text','String','#2','Position',[10 137 20 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    pumFig7 = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35  10 150 20],'Callback',@fSetFig);
    pumFig6 = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35  35 150 20],'Callback',@fSetFig);
    pumFig5 = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35  60 150 20],'Callback',@fSetFig);
    pumFig4 = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35  85 150 20],'Callback',@fSetFig);
    pumFig3 = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35 110 150 20],'Callback',@fSetFig);
    pumFig2 = uicontrol(bgFigs,'Style','PopupMenu','String',X.Plots,'Value',1,'Position',[35 135 150 20],'Callback',@fSetFig);

    btnFig7 = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190  10 20 20],'BackgroundColor',cButtonOff,'Callback',@fToggleFig7);
    btnFig6 = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190  35 20 20],'BackgroundColor',cButtonOff,'Callback',@fToggleFig6);
    btnFig5 = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190  60 20 20],'BackgroundColor',cButtonOff,'Callback',@fToggleFig5);
    btnFig4 = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190  85 20 20],'BackgroundColor',cButtonOff,'Callback',@fToggleFig4);
    btnFig3 = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190 110 20 20],'BackgroundColor',cButtonOff,'Callback',@fToggleFig3);
    btnFig2 = uicontrol(bgFigs,'Style','PushButton','String','','Position',[190 135 20 20],'BackgroundColor',cButtonOff,'Callback',@fToggleFig2);

    %btnCtrl7 = uicontrol(bgFigs,'Style','PushButton','String','Ctrl','Position',[215  10 30 20],'BackgroundColor',cButtonOff,'Callback',@fToggleCtrl7);
    
    edtXMin7 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215  10 55 20],'Callback',@fZoom7);
    edtXMax7 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295  10 55 20],'Callback',@fZoom7);
    edtYMin7 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355  10 55 20],'Callback',@fZoom7);
    edtYMax7 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435  10 55 20],'Callback',@fZoom7);
    
    edtXMin6 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215  35 55 20],'Callback',@fZoom6);
    edtXMax6 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295  35 55 20],'Callback',@fZoom6);
    edtYMin6 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355  35 55 20],'Callback',@fZoom6);
    edtYMax6 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435  35 55 20],'Callback',@fZoom6);
    
    edtXMin5 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215  60 55 20],'Callback',@fZoom5);
    edtXMax5 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295  60 55 20],'Callback',@fZoom5);
    edtYMin5 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355  60 55 20],'Callback',@fZoom5);
    edtYMax5 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435  60 55 20],'Callback',@fZoom5);
    
    edtXMin4 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215  85 55 20],'Callback',@fZoom4);
    edtXMax4 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295  85 55 20],'Callback',@fZoom4);
    edtYMin4 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355  85 55 20],'Callback',@fZoom4);
    edtYMax4 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435  85 55 20],'Callback',@fZoom4);
    
    edtXMin3 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215 110 55 20],'Callback',@fZoom3);
    edtXMax3 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295 110 55 20],'Callback',@fZoom3);
    edtYMin3 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355 110 55 20],'Callback',@fZoom3);
    edtYMax3 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435 110 55 20],'Callback',@fZoom3);
    
    edtXMin2 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[215 135 55 20],'Callback',@fZoom2);
    edtXMax2 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[295 135 55 20],'Callback',@fZoom2);
    edtYMin2 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[355 135 55 20],'Callback',@fZoom2);
    edtYMax2 = uicontrol(bgFigs,'Style','Edit','String',sprintf('%.2f',0),'Position',[435 135 55 20],'Callback',@fZoom2);

    chkX27 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(7),'Position',[415  12 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    chkX26 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(6),'Position',[415  37 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    chkX25 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(5),'Position',[415  62 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    chkX24 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(4),'Position',[415  87 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    chkX23 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(3),'Position',[415 112 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);
    chkX22 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X2Sym(2),'Position',[415 137 15 15],'BackgroundColor',cBackGround,'Callback',@fSymX2);

    chkX17 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(7),'Position',[275  12 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
    chkX16 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(6),'Position',[275  37 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
    chkX15 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(5),'Position',[275  62 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
    chkX14 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(4),'Position',[275  87 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
    chkX13 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(3),'Position',[275 112 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
    chkX12 = uicontrol(bgFigs,'Style','Checkbox','Value',X.X1Link(2),'Position',[275 137 15 15],'BackgroundColor',cBackGround,'Callback',@fLinkX1);
    
    %
    %  Functions
    % ***********
    %
    
    % Load Data Callback
    
    function fLoadSet1(~,~)
        
        set(btnSet1, 'BackgroundColor', cButtonOn);
        set(btnSet2, 'BackgroundColor', cButtonOff);
        set(btnSet3, 'BackgroundColor', cButtonOff);
        
        stSettings.LoadData{1} = get(edtSet1, 'String');
        oData.Path = stSettings.LoadData{1};
        fSaveVariables;
        
    end % function

    function fLoadSet2(~,~)
        
        set(btnSet1, 'BackgroundColor', cButtonOff);
        set(btnSet2, 'BackgroundColor', cButtonOn);
        set(btnSet3, 'BackgroundColor', cButtonOff);
        
        stSettings.LoadData{2} = get(edtSet2, 'String');
        oData.Path = stSettings.LoadData{2};
        fSaveVariables;

    end % function

    function fLoadSet3(~,~)
        
        set(btnSet1, 'BackgroundColor', cButtonOff);
        set(btnSet2, 'BackgroundColor', cButtonOff);
        set(btnSet3, 'BackgroundColor', cButtonOn);
        
        stSettings.LoadData{3} = get(edtSet3, 'String');
        oData.Path = stSettings.LoadData{3};
        fSaveVariables;

    end % function

    % Toggle Figure
    
    function fToggleFig2(~,~)
        
        if X.Figure(2) == 0
            set(btnFig2, 'BackgroundColor', cButtonOn);
            X.Figure(2) = 1;
            figure(2); clf;
        else
            set(btnFig2, 'BackgroundColor', cButtonOff);
            X.Figure(2) = 0;
            close(figure(2));
        end % if
        
    end % function

    function fToggleFig3(~,~)
        
        if X.Figure(3) == 0
            set(btnFig3, 'BackgroundColor', cButtonOn);
            X.Figure(3) = 1;
            figure(3); clf;
        else
            set(btnFig3, 'BackgroundColor', cButtonOff);
            X.Figure(3) = 0;
            close(figure(3));
        end % if
        
    end % function

    function fToggleFig4(~,~)
        
        if X.Figure(4) == 0
            set(btnFig4, 'BackgroundColor', cButtonOn);
            X.Figure(4) = 1;
            figure(4); clf;
        else
            set(btnFig4, 'BackgroundColor', cButtonOff);
            X.Figure(4) = 0;
            close(figure(4));
        end % if
        
    end % function

    function fToggleFig5(~,~)
        
        if X.Figure(5) == 0
            set(btnFig5, 'BackgroundColor', cButtonOn);
            X.Figure(5) = 1;
            figure(5); clf;
        else
            set(btnFig5, 'BackgroundColor', cButtonOff);
            X.Figure(5) = 0;
            close(figure(5));
        end % if
        
    end % function

    function fToggleFig6(~,~)
        
        if X.Figure(6) == 0
            set(btnFig6, 'BackgroundColor', cButtonOn);
            X.Figure(6) = 1;
            figure(6); clf;
        else
            set(btnFig6, 'BackgroundColor', cButtonOff);
            X.Figure(6) = 0;
            close(figure(6));
        end % if
        
    end % function

    function fToggleFig7(~,~)
        
        if X.Figure(7) == 0
            set(btnFig7, 'BackgroundColor', cButtonOn);
            X.Figure(7) = 1;
            figure(7); clf;
        else
            set(btnFig7, 'BackgroundColor', cButtonOff);
            X.Figure(7) = 0;
            close(figure(7));
        end % if
        
    end % function

    % Link and Symmetric Functions
    
    function fLinkX1(~,~)
        
        X.X1Link(2) = get(chkX12, 'Value');
        X.X1Link(3) = get(chkX13, 'Value');
        X.X1Link(4) = get(chkX14, 'Value');
        X.X1Link(5) = get(chkX15, 'Value');
        X.X1Link(6) = get(chkX16, 'Value');
        X.X1Link(7) = get(chkX17, 'Value');
        
    end % function

    function fSymX2(~,~)
        
        X.X2Sym(2) = get(chkX22, 'Value');
        X.X2Sym(3) = get(chkX23, 'Value');
        X.X2Sym(4) = get(chkX24, 'Value');
        X.X2Sym(5) = get(chkX25, 'Value');
        X.X2Sym(6) = get(chkX26, 'Value');
        X.X2Sym(7) = get(chkX27, 'Value');
        
    end % function

    % Common Functions
    
    function fSaveVariables
        
        save('/tmp/osiris_analyse_settings.mat','-struct','stSettings');
        
    end % function

   
end % function
