
%
%  GUI :: Track Fields
% *********************
%

function uiTrackFields(oData, varargin)

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
    X.Name    = oData.Config.Name;                          % Name of dataset
    X.Species = fieldnames(oData.Config.Particles.Species); % All species in dataset
    X.Cyl     = oData.Config.Simulation.Cylindrical;
    X.Dim     = oData.Config.Simulation.Dimensions;

    if isempty(X.Species)
        fprintf(2,'Error: Dataset contains no species.\n');
        return;
    end % if

    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(2);
    
    % Get Time Axis
    X.TAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
    
    % Tracking
    X.Track.Time    = [X.Limits(2) X.Limits(3)];
    X.Track.Species = X.Species{1};
    X.Track.Details = oData.Translate.Lookup(X.Species{1},'Species');

    % Data Objects
    oDN = Density(oData,X.Track.Species,'Units','SI','Scale','mm');
    oDN.Time = X.Dump;
    
    % Limits
    X.XLim         = oDN.AxisRange*1e-3;
    X.Plot.Limits  = [oDN.AxisRange(1:4) 0 0];
    if X.Cyl
        X.XLim(3)        = -X.XLim(4);
        X.Plot.Limits(3) = -X.Plot.Limits(4);
    end % if
    X.Track.Limits = [X.XLim 0 X.XLim(4) 0 1 0 1 0 1 0 1];
    X.Track.Scale  = ones(8,1);
    X.Track.Units  = {'m','m','m','m','eV','eV','eV','C'};
    
    % Options
    switch(X.Dim)
        case 1
            fprintf(2,'Error: 1D simulations not supported.\n');
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
    iH    = 610;
    
    % Set Figure Properties
    fMain.Units        = 'Pixels';
    fMain.MenuBar      = 'None';
    fMain.Position     = [aFPos(1:2) 1170 iH];
    fMain.Name         = 'OsirisAnalysis: Track Fields';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-TF';

    if ~isempty(stOpt.Position) && sum(size(stOpt.Position) == [1 2]) == 2
        aOPos = fMain.OuterPosition;
        fMain.OuterPosition = [stOpt.Position-[-5 aOPos(4)] aOPos(3:4)];
    end % if
    
    % Axes
    axMain = axes('Units','Pixels','Position',[340 iH-290 550 230]);
    
    %
    % Controls
    %
    
    uicontrol('Style','Text','String','Track Fields','FontSize',20,'Position',[20 iH-50 200 35],'HorizontalAlignment','Left');

    % Output Window
    lstOut = uicontrol('Style','Listbox','String','OsirisAnalysis: Track Species','FontName','FixedWidth','HorizontalAlignment','Left','BackgroundColor',[0 0 0],'ForegroundColor',[0 1 0]);
    lstOut.Position = [20 iH-590 560 87];
    jOut   = findjobj(lstOut);
    jList  = jOut.getViewport.getComponent(0);
    set(jList, 'SelectionBackground', java.awt.Color.black);
    set(jList, 'SelectionForeground', java.awt.Color.green);
    jList.setSelectionAppearanceReflectsFocus(0);
    
    % Main Controls
    bgCtrl = uibuttongroup('Title','Controls','Units','Pixels','Position',[20 iH-180 250 130]);
    uicontrol(bgCtrl,'Style','Text','String',X.Name,'FontSize',18,'Position',[10 85 225 25],'ForegroundColor',[1.00 1.00 0.00],'BackgroundColor',[0.80 0.80 0.80]); 

    uicontrol(bgCtrl,'Style','Text','String','Species',    'Position',[10 5 100 20],'HorizontalAlignment','Left');
    pumSpecies = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Species,       'Position',[95 10 140 20],'Callback',{@fSetSpecies});

    %
    % Time Dump
    %

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[20 iH-330 140 100]);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 9 60 30 20],'Callback',{@fDump, -10});
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[39 60 30 20],'Callback',{@fDump,  -1});
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[69 60 30 20],'Callback',{@fDump,   1});
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[99 60 30 20],'Callback',{@fDump,  10});

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 9 35 30 20],'Callback',{@fJump, 1});
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[39 35 30 20],'Callback',{@fJump, 2});
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[69 35 30 20],'Callback',{@fJump, 3});
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[99 35 30 20],'Callback',{@fJump, 4});

    lblDump(1) = uicontrol(bgTime,'Style','Text','String','0','Position',[ 10 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);
    lblDump(2) = uicontrol(bgTime,'Style','Text','String','0','Position',[ 40 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);
    lblDump(3) = uicontrol(bgTime,'Style','Text','String','0','Position',[ 70 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);
    lblDump(4) = uicontrol(bgTime,'Style','Text','String','0','Position',[100 11 28 15],'BackgroundColor',[0.80 0.80 0.80]);

    
    %
    % Plot Limits
    %

    bgPLim = uibuttongroup('Title','Plot Limits','Units','Pixels','Position',[280 iH-490 295 150]);

    % Labels
    uicontrol(bgPLim,'Style','Text','String','Slice','Position',[ 10 108 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Axis', 'Position',[ 10  85 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Pos',  'Position',[ 10  60 60 20],'HorizontalAlignment','Left');

    uicontrol(bgPLim,'Style','Text','String','Min',  'Position',[160 108 55 20]);
    uicontrol(bgPLim,'Style','Text','String','Max',  'Position',[225 108 55 20]);
    uicontrol(bgPLim,'Style','Text','String','HAxis','Position',[120  85 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','VAxis','Position',[120  60 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','CAxis','Position',[120  35 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','CMap', 'Position',[120  10 60 20],'HorizontalAlignment','Left');

    % Fields
    pumSlice = uicontrol(bgPLim,'Style','PopupMenu','Position',[ 50 87  55 20],'Callback',{@fSetAliceAxis},'String',X.Opt.SliceAxis);
    edtSlPos = uicontrol(bgPLim,'Style','Edit',     'Position',[ 50 62  55 20],'Callback',{@fSetSlicePos});

    edtPHMin = uicontrol(bgPLim,'Style','Edit',     'Position',[160 87  55 20],'Callback',{@fSetPlotLim,1});
    edtPHMax = uicontrol(bgPLim,'Style','Edit',     'Position',[225 87  55 20],'Callback',{@fSetPlotLim,2});
    edtPVMin = uicontrol(bgPLim,'Style','Edit',     'Position',[160 62  55 20],'Callback',{@fSetPlotLim,3});
    edtPVMax = uicontrol(bgPLim,'Style','Edit',     'Position',[225 62  55 20],'Callback',{@fSetPlotLim,4});
    edtPCMin = uicontrol(bgPLim,'Style','Edit',     'Position',[160 37  55 20],'Callback',{@fSetPlotLim,5});
    edtPCMax = uicontrol(bgPLim,'Style','Edit',     'Position',[225 37  55 20],'Callback',{@fSetPlotLim,6});
    pumPCMap = uicontrol(bgPLim,'Style','PopupMenu','Position',[160 12 120 20],'Callback',{@fSetPlotLim,7},'String','N');
    
    % Defaults
    pumSlice.Value  = X.SliceAxis;
    edtSlPos.String = sprintf('%.2f',X.SlicePos);
    edtPHMin.String = sprintf('%.2f',X.Plot.Limits(1));
    edtPHMax.String = sprintf('%.2f',X.Plot.Limits(2));
    edtPVMin.String = sprintf('%.2f',X.Plot.Limits(3));
    edtPVMax.String = sprintf('%.2f',X.Plot.Limits(4));
    edtPCMin.String = '0.00';
    edtPCMax.String = '0.00';



    
    %
    % Init
    %
    
    fRefreshDensity;
    fOut(sprintf('Loaded ''%s''',X.Track.Species),1);
    
    
    %
    %  Data Functions
    %

    function fRefreshDensity()

        oDN.Time = X.Dump;
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
        
        title(sprintf('%s Charge Density',X.Track.Details.Full));
        xlabel(sprintf('%s [mm]',vHAxis.Tex));
        ylabel(sprintf('%s [mm]',vVAxis.Tex));
        title(hCol,sprintf('%s [%s]',sLabel,sSUnit));
        
    end % function
    
    %
    %  Callback Functions
    %

    function fSetStart(uiSrc,~)
        
        iTime = round(str2double(uiSrc.String));
        if iTime < X.Limits(1)
            iTime = X.Limits(1);
        end % if
        uiSrc.String = iTime;

        X.Track.Time(1) = iTime;
        %sldTime.Min     = iTime;
        %if sldTime.Value < sldTime.Min
        %    sldTime.Value = sldTime.Min;
        %end % if
        
        %fTrackTime(sldTime,0);
        
    end % function

    function fSetStop(uiSrc,~)

        iTime = round(str2double(uiSrc.String));
        if iTime > X.Limits(4)
            iTime = X.Limits(4);
        end % if
        uiSrc.String = iTime;

        X.Track.Time(2) = iTime;
        %sldTime.Max     = iTime;
        %if sldTime.Value > sldTime.Max
        %    sldTime.Value = sldTime.Max;
        %end % if

        %fTrackTime(sldTime,0);

    end % function

    function fSetSpecies(uiSrc,~)

        X.Track.Species = X.Species{uiSrc.Value};
        X.Track.Details = oData.Translate.Lookup(X.Species{1},'Species');
    
        oDN = Density(oData,X.Track.Species,'Units','SI','Scale','mm');
        fOut(sprintf('Loaded ''%s''',X.Track.Species),1);
        
        fRefreshDensity;

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
        fRefreshDensity
        
    end % function

    function fJump(~,~,iJump)
        
        iTime = X.Limits(iJump);

        switch(iJump)
            case 1
                edtStart.String = iTime;
                fSetStart(edtStart,0);
            case 2
                edtStart.String = iTime;
                fSetStart(edtStart,0);
            case 3
                edtStop.String = iTime;
                fSetStop(edtStop,0);
            case 4
                edtStop.String = iTime;
                fSetStop(edtStop,0);
        end % switch
        
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
