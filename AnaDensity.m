%
%  GUI :: Analyse Density
% ************************
%

function AnaDensity(oData)

    cBackGround = [0.8 0.8 0.8];
    cWhite      = [1.0 1.0 1.0];
    
    iTime   = 0;
    iStart  = fStringToDump(oData, 'Start');
    iEnd    = fStringToDump(oData, 'End');
    iPStart = fStringToDump(oData, 'PStart');
    iPEnd   = fStringToDump(oData, 'PEnd');
    
    dZPos   = 0.0;
    
    sName   = oData.Config.Name;
    aBeam   = oData.Config.Variables.Species.Beam;
    aPlasma = oData.Config.Variables.Species.Plasma;
    
    sData   = 'ProtonBeam';
    
    aScatt1 = ['Off'; aBeam];
    aScatt2 = ['Off'; aBeam];
    
    aProj   = {'Off','Density'};
    
    dX1Min  = 0.0;
    dX1Max  = 0.0;
    dX2Min  = 0.0;
    dX2Max  = 0.0;

    dP1Min  = 0.0;
    dP1Max  = 0.0;
    dP2Min  = 0.0;
    dP2Max  = 0.0;
    
    iX2Sym  = 1;
    iCharge = 1;
    iProj   = 2;
    
    sScatt1 = '';
    sScatt2 = '';
    iScatt1 = 2000;
    iScatt2 = 2000;
    
    iType   = 1;

    % Create figure
    
    f = figure(1);
    clf;
    aFigPos = get(f, 'Position');
    
    % Set figure properties

    set(f, 'Units', 'Pixels');
    set(f, 'Position', [aFigPos(1:2) 1200 600]);
    set(f, 'Color', cBackGround);
    set(f, 'Name', sprintf('Beam Density (%s #%d)', sName, iTime));
    
    h = axes('Units','Pixels','Position',[50,50,900,500]); 
    fPlot;
    
    dP1Min = dX1Min;
    dP1Max = dX1Max;
    dP2Min = dX2Min;
    dP2Max = dX2Max;

    % Plot Types
    
    bgType    = uibuttongroup('Title','Plot Type','Units','Pixels','Position',[975 490 200 65],'BackgroundColor',cBackGround);
    
    optBeam   = uicontrol(bgType,'Style','RadioButton','String','Plot beam density','Value',1,'Position',[ 10 30 180 15],'BackgroundColor',cBackGround,'HandleVisibility','Off');
    optPlasma = uicontrol(bgType,'Style','RadioButton','String','Plot plasma density','Value',0,'Position',[ 10 10 180 15],'BackgroundColor',cBackGround,'HandleVisibility','Off');
    
    set(bgType,'SelectionChangeFcn',@optType_Callback);

    % Time Dump Controls
    
    bgTime    = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[975 405 200 80],'BackgroundColor',cBackGround);

    lblDumpN  = uicontrol(bgTime,'Style','Text','String','#','Position',[132 37 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    lblDumpL  = uicontrol(bgTime,'Style','Text','String','L','Position',[133 12 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    edtDumpN  = uicontrol(bgTime,'Style','Edit','String',sprintf('%d',iTime),'Position',[ 145 35 45 20],'Callback',@edtDumpN_Callback);
    edtDumpL  = uicontrol(bgTime,'Style','Edit','String',sprintf('%.2f',dZPos),'Position',[ 145 10 45 20]);

    btnTPrev2 = uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 10 35 30 22],'Callback',@btnTPrev2_Callback);
    btnTPrev1 = uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[ 40 35 30 22],'Callback',@btnTPrev1_Callback);
    btnTNext1 = uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[ 70 35 30 22],'Callback',@btnTNext1_Callback);
    btnTNext2 = uicontrol(bgTime,'Style','PushButton','String','>>','Position',[100 35 30 22],'Callback',@btnTNext2_Callback);

    btnSStart = uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 10 10 30 22],'Callback',@btnSStart_Callback);
    btnPStart = uicontrol(bgTime,'Style','PushButton','String','<P','Position',[ 40 10 30 22],'Callback',@btnPStart_Callback);
    btnPEnd   = uicontrol(bgTime,'Style','PushButton','String','P>','Position',[ 70 10 30 22],'Callback',@btnPEnd_Callback);
    btnSEnd   = uicontrol(bgTime,'Style','PushButton','String','S>','Position',[100 10 30 22],'Callback',@btnSEnd_Callback);
    
    % Data Controls

    bgData    = uibuttongroup('Title','Data Selection','Units','Pixels','Position',[975 305 200 95],'BackgroundColor',cBackGround);

    lblData   = uicontrol(bgData,'Style','Text','String','Data','Position',[10 57 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    lblProj   = uicontrol(bgData,'Style','Text','String','Overlay','Position',[10 32 55 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    pumData   = uicontrol(bgData,'Style','PopupMenu','String',aBeam,'Value',1,'Position',[65 55 125 22],'Callback',@pumData_Callback);
    pumProj   = uicontrol(bgData,'Style','PopupMenu','String',aProj,'Value',iProj,'Position',[65 30 125 22],'Callback',@pumProj_Callback);
    
    chkCharge = uicontrol(bgData,'Style','Checkbox','String','Show total charge','Value',iCharge,'Position',[55 10 135 15],'BackgroundColor',cBackGround);

    % Scatter Controls

    bgScatter = uibuttongroup('Title','Scatter Selection','Units','Pixels','Position',[975 225 200 75],'BackgroundColor',cBackGround);

    lblScatt1 = uicontrol(bgScatter,'Style','Text','String','#','Position',[122 37 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    lblScatt2 = uicontrol(bgScatter,'Style','Text','String','#','Position',[122 12 10 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);

    pumScatt1 = uicontrol(bgScatter,'Style','PopupMenu','String',aScatt1,'Position',[10 35 110 22],'Callback',@pumScatt1_Callback);
    pumScatt2 = uicontrol(bgScatter,'Style','PopupMenu','String',aScatt2,'Position',[10 10 110 22],'Callback',@pumScatt2_Callback);

    edtScatt1 = uicontrol(bgScatter,'Style','Edit','String',sprintf('%d',iScatt1),'Position',[135 35 55 20],'Callback',@edtScatt1_Callback);
    edtScatt2 = uicontrol(bgScatter,'Style','Edit','String',sprintf('%d',iScatt2),'Position',[135 10 55 20],'Callback',@edtScatt2_Callback);
    
    % Zoom Controls

    bgZoom    = uibuttongroup('Title','Zoom','Units','Pixels','Position',[975 45 200 175],'BackgroundColor',cBackGround);

    lblX1Zoom = uicontrol(bgZoom,'Style','Text','String','X1 Lim','Position',[10 137 45 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    lblX2Zoom = uicontrol(bgZoom,'Style','Text','String','X2 Lim','Position',[10 112 45 15],'HorizontalAlignment','Left','BackgroundColor',cBackGround);
    
    lblX1Dash = uicontrol(bgZoom,'Style','Text','String','–','Position',[120 137 10 15],'BackgroundColor',cBackGround);
    lblX2Dash = uicontrol(bgZoom,'Style','Text','String','–','Position',[120 112 10 15],'BackgroundColor',cBackGround);
    
    edtX1Min  = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',dP1Min),'Position',[ 60 135 60 20],'Callback',@edtX1Min_Callback);
    edtX1Max  = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',dP1Max),'Position',[130 135 60 20],'Callback',@edtX1Max_Callback);
    edtX2Min  = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',dP2Min),'Position',[ 60 110 60 20],'Callback',@edtX2Min_Callback);
    edtX2Max  = uicontrol(bgZoom,'Style','Edit','String',sprintf('%.2f',dP2Max),'Position',[130 110 60 20],'Callback',@edtX2Max_Callback);
    
    sldX1Min  = uicontrol(bgZoom,'Style','Slider','Min',dX1Min,'Max',dX1Max,'Value',dP1Min,'Position',[ 10 90 180 15],'Callback',@sldX1Min_Callback);
    sldX1Max  = uicontrol(bgZoom,'Style','Slider','Min',dX1Min,'Max',dX1Max,'Value',dP1Max,'Position',[ 10 70 180 15],'Callback',@sldX1Max_Callback);
    sldX2Min  = uicontrol(bgZoom,'Style','Slider','Min',dX2Min,'Max',dX2Max,'Value',dP2Min,'Position',[ 10 50 180 15],'Callback',@sldX2Min_Callback);
    sldX2Max  = uicontrol(bgZoom,'Style','Slider','Min',dX2Min,'Max',dX2Max,'Value',dP2Max,'Position',[ 10 30 180 15],'Callback',@sldX2Max_Callback);

    chkX2Sym  = uicontrol(bgZoom,'Style','Checkbox','String','Symmetric X2 axis','Value',iX2Sym,'Position',[ 50 10 140 15],'BackgroundColor',cBackGround,'Callback',@chkX2Sym_Callback);
                      
    
    %
    %  Functions
    % ***********
    %
    
    % Type Callback
    
    function optType_Callback(source, eventdata)
        
        sValue = get(eventdata.NewValue, 'String');
        switch(sValue)
            case 'Plot beam density'
                iType = 1;
                set(pumData, 'String', aBeam, 'Value', 1);
                sData = aBeam{1};
            case 'Plot plasma density'
                iType = 2;
                set(pumData, 'String', aPlasma, 'Value', 1);
                sData = aPlasma{1};
        end % switch
        
        fPlot;
        
    end % function
    
    % Time Callback
    
    function btnTNext1_Callback(source, eventdata) 

        iTime = iTime + 1;
        if iTime > iEnd
            iTime = iEnd;
        end % if

        fPlot;
        fUpdateTime;

    end % function

    function btnTNext2_Callback(source, eventdata) 
    
        iTime = iTime + 10;
        if iTime > iEnd
            iTime = iEnd;
        end % if

        fPlot;
        fUpdateTime;

    end % function

    function btnTPrev1_Callback(source, eventdata)

        iTime = iTime - 1;
        if iTime < 0
            iTime = 0;
        end % if
        
        fPlot;
        fUpdateTime;

    end % function

    function btnTPrev2_Callback(source, eventdata)

        iTime = iTime - 10;
        if iTime < 0
            iTime = 0;
        end % if
        
        fPlot;
        fUpdateTime;

    end % function

    function btnSStart_Callback(source, eventdata)
        
        iTime = iStart;
        fPlot;
        fUpdateTime;
        
    end % function

    function btnSEnd_Callback(source, eventdata)
        
        iTime = iEnd;
        fPlot;
        fUpdateTime;
        
    end % function

    function btnPStart_Callback(source, eventdata)
        
        iTime = iPStart;
        fPlot;
        fUpdateTime;
        
    end % function

    function btnPEnd_Callback(source, eventdata)
        
        iTime = iPEnd;
        fPlot;
        fUpdateTime;
        
    end % function

    function edtDumpN_Callback(source, eventdata)
        
        sValue = num2str(get(source, 'Value'));
        iTime  = fStringToDump(oData, sValue);
        fPlot;
        fUpdateTime;
        
    end % function

    % Data Callback
    
    function pumData_Callback(source, eventdata)
        
        iValue = get(source, 'Value');

        switch(iType)
            case 1
                sData = aBeam{iValue};
            case 2
                sData = sPlasma{iValue};
        end % switch
        
        fPlot;
        
    end % function

    function pumProj_Callback(source, eventdata)
        
        iProj = get(source, 'Value');
        fPlot;
        
    end % function
    
    % Scatter Callpack
    
    function pumScatt1_Callback(source, eventdata)
        
        iValue = get(source, 'Value');

        sScatt1 = aScatt1{iValue};
        if strcmp(sScatt1, 'Off')
            sScatt1 = '';
        end % if
        
        fPlot;
        
    end % function

    function pumScatt2_Callback(source, eventdata)
        
        iValue = get(source, 'Value');

        sScatt2 = aScatt2{iValue};
        if strcmp(sScatt2, 'Off')
            sScatt2 = '';
        end % if
        
        fPlot;
        
    end % function

    function edtScatt1_Callback(source, eventdata)
        
        iValue = str2num(get(source, 'String'));
        iValue = floor(iValue);
        
        if isempty(iValue)
            iValue = 2000;
        end % if
        
        set(source, 'String', num2str(iValue));
        
        iScatt1 = iValue;
        fPlot;
        
    end % function

    function edtScatt2_Callback(source, eventdata)
        
        iValue = str2num(get(source, 'String'));
        iValue = floor(iValue);
        
        if isempty(iValue)
            iValue = 2000;
        end % if
        
        set(source, 'String', num2str(iValue));
        
        iScatt2 = iValue;
        fPlot;
        
    end % function

    % Zoom Callback

    function sldX1Min_Callback(source, eventdata) 

        dP1Min = get(source, 'Value');
        fUpdateZoom;

    end % function

    function sldX1Max_Callback(source, eventdata) 

        dP1Max = get(source, 'Value');
        fUpdateZoom;

    end % function

    function sldX2Min_Callback(source, eventdata) 

        dP2Min = get(source, 'Value');
        if iX2Sym == 1
            dP2Max = -dP2Min;
        end % if
        fUpdateZoom;

    end % function

    function sldX2Max_Callback(source, eventdata) 

        dP2Max = get(source, 'Value');
        if iX2Sym == 1
            dP2Min = -dP2Max;
        end % if
        fUpdateZoom;

    end % function

    function edtX1Min_Callback(source, eventdata)
        
        iValue = str2num(get(source, 'String'));
        
        if isempty(iValue)
            iValue = dP1Min;
        end % if
        
        dMin = get(sldX1Min, 'Min');
        dMax = get(sldX1Min, 'Max');
        
        if iValue < dMin
            iValue = dMin;
        end % if
        
        if iValue > dMax
            iValue = dMax;
        end % if
        
        dP1Min = iValue;
        fUpdateZoom;
        
    end % function

    function edtX1Max_Callback(source, eventdata)
        
        iValue = str2num(get(source, 'String'));
        
        if isempty(iValue)
            iValue = dP1Max;
        end % if
        
        dMin = get(sldX1Max, 'Min');
        dMax = get(sldX1Max, 'Max');
        
        if iValue < dMin
            iValue = dMin;
        end % if
        
        if iValue > dMax
            iValue = dMax;
        end % if
        
        dP1Max = iValue;
        fUpdateZoom;
        
    end % function

    function edtX2Min_Callback(source, eventdata)
        
        iValue = str2num(get(source, 'String'));
        
        if isempty(iValue)
            iValue = dP2Min;
        end % if
        
        dMin = get(sldX2Min, 'Min');
        dMax = get(sldX2Min, 'Max');
        
        if iValue < dMin
            iValue = dMin;
        end % if
        
        if iValue > dMax
            iValue = dMax;
        end % if

        dP2Min = iValue;
        if iX2Sym == 1
            dP2Max = -dP2Min;
        end % if
        
        fUpdateZoom;
        
    end % function

    function edtX2Max_Callback(source, eventdata)
        
        iValue = str2num(get(source, 'String'));
        
        if isempty(iValue)
            iValue = dP2Max;
        end % if
        
        dMin = get(sldX2Max, 'Min');
        dMax = get(sldX2Max, 'Max');
        
        if iValue < dMin
            iValue = dMin;
        end % if
        
        if iValue > dMax
            iValue = dMax;
        end % if
        
        dP2Max = iValue;
        if iX2Sym == 1
            dP2Min = -dP2Max;
        end % if

        fUpdateZoom;
        
    end % function

    function chkX2Sym_Callback(source, eventdata) 

        iX2Sym = get(source, 'Value');
        if iX2Sym == 1
            set(sldX2Max, 'Value', -get(sldX2Min, 'Value'));
        end % if
        fUpdateZoom;

    end % function

    % Update Functions

    function fUpdateTime
        
        set(edtDumpN, 'String', sprintf('%d', iTime));
        set(edtDumpL, 'String', sprintf('%.2f', dZPos));
        
    end % function

    function fUpdateZoom

        set(edtX1Min,'String',sprintf('%.2f',dP1Min));
        set(edtX1Max,'String',sprintf('%.2f',dP1Max));
        set(edtX2Min,'String',sprintf('%.2f',dP2Min));
        set(edtX2Max,'String',sprintf('%.2f',dP2Max));

        set(sldX1Min,'Value',dP1Min);
        set(sldX1Max,'Value',dP1Max);
        set(sldX2Min,'Value',dP2Min);
        set(sldX2Max,'Value',dP2Max);
        
        fPlot;

    end % function

    % Plot Function

    function fPlot

        if dP1Max > 0 && dP2Max > 0
            aLimits = [dP1Min dP1Max dP2Min dP2Max];
        else
            aLimits = [];
        end % if
        
        sOverlay1 = '';
        sOverlay2 = '';
        
        switch(iProj)
            case 1
                sOverlay  = 'No';
            case 2
                sOverlay  = 'Yes';
                sOverlay1 = sScatt1;
                sOverlay2 = sScatt2;
        end % if
        
        switch(iType)
            
            case 1
                stPlot = fPlotBeamDensity(oData, iTime, sData, ...
                                          'IsSubPlot', 'Yes', ...
                                          'HideDump', 'Yes', ...
                                          'Absolute', 'Yes', ...
                                          'ShowOverlay', sOverlay, ...
                                          'Limits', aLimits);
                                      
            case 2
                stPlot = fPlotPlasmaDensity(oData, iTime, sData, ...
                                            'IsSubPlot', 'Yes', ...
                                            'HideDump', 'Yes', ...
                                            'Absolute', 'Yes', ...
                                            'Overlay1', sOverlay1, ...
                                            'Overlay2', sOverlay2, ...
                                            'Scatter1', sScatt1, ...
                                            'Scatter2', sScatt2, ...
                                            'Sample1', iScatt1, ...
                                            'Sample2', iScatt2, ...
                                            'Limits', aLimits, ...
                                            'CAxis', [0 5]);

        end % switch

        set(f, 'Name', sprintf('Analyse Density (%s #%d)', sName, iTime));
        
        dX1Min = stPlot.X1Axis(1);
        dX1Max = stPlot.X1Axis(end);
        dX2Min = stPlot.X2Axis(1);
        dX2Max = stPlot.X2Axis(end);
        
        dZPos  = stPlot.ZPos;
        
    end % function 
   
end % function
