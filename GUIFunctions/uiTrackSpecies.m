
%
%  GUI :: Track Species
% **********************
%

function uiTrackSpecies(oData)

    %
    %  Data Struct
    % *************
    %
    
    % Check Input
    if nargin < 1
        fprintf(2,'Error: Please provide an OsirisData object.\n');
        return;
    end %if
    
    % Get Values
    iDumps  = oData.Elements.FLD.e1.Info.Files-1;
    dPStart = oData.Config.Simulation.PlasmaStart;
    dTFac   = oData.Config.Convert.SI.TimeFac;
    dLFac   = oData.Config.Convert.SI.LengthFac;

    % Get DataSet Info
    X.Name    = oData.Config.Name;                          % Name of dataset
    X.Species = fieldnames(oData.Config.Particles.Species); % All species in dataset
    X.Cyl     = oData.Config.Simulation.Cylindrical;

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

    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(2);
    
    % Data Objects
    oDN = Density(oData,X.Track.Species,'Units','SI','Scale','mm');
    oDN.Time = X.Dump;
    
    % Limits
    X.XLim = oDN.AxisRange*1e-3;
    if X.Cyl
        X.XLim(3) = -X.XLim(4);
    end % if
    X.Plot.Limits  = [oDN.AxisRange(1:4) 0 0];
    X.Track.Limits = [X.XLim 0 X.XLim(4) 0 1 0 1 0 1 0 1];
    X.Track.Scale  = ones(8,1);
    X.Track.Units  = {'m','m','m','m','eV','eV','eV','C'};
    

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
    fMain.Name         = 'OsirisAnalysis: Track Species';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-TS';
    
    % Axes
    axMain = axes('Units','Pixels','Position',[340 iH-290 550 230]);
    
    %
    % Controls
    %
    
    uicontrol('Style','Text','String','Track Species','FontSize',20,'Position',[20 iH-50 200 35],'HorizontalAlignment','Left');

    % Output Window
    lstOut = uicontrol('Style','Listbox','String','OsirisAnalysis: Track Species','FontName','FixedWidth','HorizontalAlignment','Left','BackgroundColor',[0 0 0],'ForegroundColor',[0 1 0]);
    lstOut.Position = [20 iH-590 560 87];
    jOut   = findjobj(lstOut);
    jList  = jOut.getViewport.getComponent(0);
    set(jList, 'SelectionBackground', java.awt.Color.black);
    set(jList, 'SelectionForeground', java.awt.Color.green);
    jList.setSelectionAppearanceReflectsFocus(0);
    
    % Main Controls
    bgCtrl = uibuttongroup('Title','Controls','Units','Pixels','Position',[20 iH-380 250 330]);
    uicontrol(bgCtrl,'Style','Text','String',X.Name,'FontSize',18,'Position',[10 285 225 25],'ForegroundColor',[1.00 1.00 0.00],'BackgroundColor',[0.80 0.80 0.80]); 

    uicontrol(bgCtrl,'Style','Text','String','Track Start','Position',[10 255 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Track Stop', 'Position',[10 230 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Species',    'Position',[10 205 100 20],'HorizontalAlignment','Left');
    
    uicontrol(bgCtrl,'Style','PushButton','String','<S','Position',[155 260 40 20],'Callback',{@fJump, 1});
    uicontrol(bgCtrl,'Style','PushButton','String','<P','Position',[195 260 40 20],'Callback',{@fJump, 2});
    uicontrol(bgCtrl,'Style','PushButton','String','P>','Position',[155 235 40 20],'Callback',{@fJump, 3});
    uicontrol(bgCtrl,'Style','PushButton','String','S>','Position',[195 235 40 20],'Callback',{@fJump, 4});

    edtStart   = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Time(1), 'Position',[95 260  55 20],'Callback',{@fSetStart});
    edtStop    = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Time(2), 'Position',[95 235  55 20],'Callback',{@fSetStop});
    pumSpecies = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Species,       'Position',[95 210 140 20],'Callback',{@fSetSpecies});

    %
    % Plot Limits
    %

    bgPLim = uibuttongroup('Title','Plot Limits','Units','Pixels','Position',[280 iH-490 185 150]);

    % Labels
    uicontrol(bgPLim,'Style','Text','String','Min',  'Position',[ 50 108 55 20]);
    uicontrol(bgPLim,'Style','Text','String','Max',  'Position',[115 108 55 20]);
    uicontrol(bgPLim,'Style','Text','String','Hor.', 'Position',[ 10  85 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Vert.','Position',[ 10  60 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Col.', 'Position',[ 10  35 60 20],'HorizontalAlignment','Left');
    uicontrol(bgPLim,'Style','Text','String','Map',  'Position',[ 10  10 60 20],'HorizontalAlignment','Left');

    % Fields
    edtPHMin = uicontrol(bgPLim,'Style','Edit',     'Position',[ 50 87  55 20],'Callback',{@fSetPlotLim,1});
    edtPHMax = uicontrol(bgPLim,'Style','Edit',     'Position',[115 87  55 20],'Callback',{@fSetPlotLim,2});
    edtPVMin = uicontrol(bgPLim,'Style','Edit',     'Position',[ 50 62  55 20],'Callback',{@fSetPlotLim,3});
    edtPVMax = uicontrol(bgPLim,'Style','Edit',     'Position',[115 62  55 20],'Callback',{@fSetPlotLim,4});
    edtPCMin = uicontrol(bgPLim,'Style','Edit',     'Position',[ 50 37  55 20],'Callback',{@fSetPlotLim,5});
    edtPCMax = uicontrol(bgPLim,'Style','Edit',     'Position',[115 37  55 20],'Callback',{@fSetPlotLim,6});
    pumPCMap = uicontrol(bgPLim,'Style','PopupMenu','Position',[ 50 12 120 20],'Callback',{@fSetPlotLim,7},'String','N');
    
    % Defaults
    edtPHMin.String = sprintf('%.2f',X.Plot.Limits(1));
    edtPHMax.String = sprintf('%.2f',X.Plot.Limits(2));
    edtPVMin.String = sprintf('%.2f',X.Plot.Limits(3));
    edtPVMax.String = sprintf('%.2f',X.Plot.Limits(4));
    edtPCMin.String = '0.00';
    edtPCMax.String = '0.00';


    %
    % Track Limits
    %

    iY = 360;
    bgTLim = uibuttongroup('Title','Tracking Limits','Units','Pixels','Position',[900 iH-380 250 iY]);

    % Labels
    uicontrol(bgTLim,'Style','Text','String','X1 Lim','Position',[10 iY-45  55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','X2 Lim','Position',[10 iY-70  55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','X3 Lim','Position',[10 iY-95  55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','Radius','Position',[10 iY-120 55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','P1 Lim','Position',[10 iY-155 55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','P2 Lim','Position',[10 iY-180 55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','P3 Lim','Position',[10 iY-205 55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','Charge','Position',[10 iY-240 55 20],'HorizontalAlignment','Left');

    % Enabled
    chkTLim(1)  = uicontrol(bgTLim,'Style','Checkbox','Value',1,'Position',[70 iY-43  15 15],'Callback',{@fEnableTrackLim,1});
    chkTLim(2)  = uicontrol(bgTLim,'Style','Checkbox','Value',1,'Position',[70 iY-68  15 15],'Callback',{@fEnableTrackLim,2});
    chkTLim(3)  = uicontrol(bgTLim,'Style','Checkbox','Value',0,'Position',[70 iY-93  15 15],'Callback',{@fEnableTrackLim,3});
    chkTLim(4)  = uicontrol(bgTLim,'Style','Checkbox','Value',0,'Position',[70 iY-118 15 15],'Callback',{@fEnableTrackLim,4});
    chkTLim(5)  = uicontrol(bgTLim,'Style','Checkbox','Value',0,'Position',[70 iY-153 15 15],'Callback',{@fEnableTrackLim,5});
    chkTLim(6)  = uicontrol(bgTLim,'Style','Checkbox','Value',0,'Position',[70 iY-178 15 15],'Callback',{@fEnableTrackLim,6});
    chkTLim(7)  = uicontrol(bgTLim,'Style','Checkbox','Value',0,'Position',[70 iY-203 15 15],'Callback',{@fEnableTrackLim,7});
    chkTLim(8)  = uicontrol(bgTLim,'Style','Checkbox','Value',0,'Position',[70 iY-238 15 15],'Callback',{@fEnableTrackLim,8});

    % Values
    edtTLim(1)  = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-43  55 20],'Callback',{@fSetTrackLim,1});
    edtTLim(2)  = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-43  55 20],'Callback',{@fSetTrackLim,2});
    edtTLim(3)  = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-68  55 20],'Callback',{@fSetTrackLim,3});
    edtTLim(4)  = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-68  55 20],'Callback',{@fSetTrackLim,4});
    edtTLim(5)  = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-93  55 20],'Callback',{@fSetTrackLim,5});
    edtTLim(6)  = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-93  55 20],'Callback',{@fSetTrackLim,6});
    edtTLim(7)  = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-118 55 20],'Callback',{@fSetTrackLim,7});
    edtTLim(8)  = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-118 55 20],'Callback',{@fSetTrackLim,8});

    edtTLim(9)  = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-153 55 20],'Callback',{@fSetTrackLim,9});
    edtTLim(10) = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-153 55 20],'Callback',{@fSetTrackLim,10});
    edtTLim(11) = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-178 55 20],'Callback',{@fSetTrackLim,11});
    edtTLim(12) = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-178 55 20],'Callback',{@fSetTrackLim,12});
    edtTLim(13) = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-203 55 20],'Callback',{@fSetTrackLim,13});
    edtTLim(14) = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-203 55 20],'Callback',{@fSetTrackLim,14});

    edtTLim(15) = uicontrol(bgTLim,'Style','Edit','Position',[ 90 iY-238 55 20],'Callback',{@fSetTrackLim,15});
    edtTLim(16) = uicontrol(bgTLim,'Style','Edit','Position',[150 iY-238 55 20],'Callback',{@fSetTrackLim,16});

    % Units
    lblTLim(1)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-45  40 20],'HorizontalAlignment','Left');
    lblTLim(2)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-70  40 20],'HorizontalAlignment','Left');
    lblTLim(3)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-95  40 20],'HorizontalAlignment','Left');
    lblTLim(4)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-120 40 20],'HorizontalAlignment','Left');
    lblTLim(5)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-155 40 20],'HorizontalAlignment','Left');
    lblTLim(6)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-180 40 20],'HorizontalAlignment','Left');
    lblTLim(7)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-205 40 20],'HorizontalAlignment','Left');
    lblTLim(8)  = uicontrol(bgTLim,'Style','Text','Position',[210 iY-240 40 20],'HorizontalAlignment','Left');

    % Options
    uicontrol(bgTLim,'Style','Text','String','Units', 'Position',[10 iY-275 55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','Method','Position',[10 iY-300 55 20],'HorizontalAlignment','Left');
    uicontrol(bgTLim,'Style','Text','String','Count', 'Position',[10 iY-325 55 20],'HorizontalAlignment','Left');

    cUnits  = {'SI/eV','Normalised'};
    cMethod = {'Random','WRandom','W2Random','Top','Bottom'};
    uicontrol(bgTLim,'Style','PopupMenu', 'String',cUnits,      'Position',[90 iY-273 115 20],'Callback',{@fSetTrackOpt,1});
    uicontrol(bgTLim,'Style','PopupMenu', 'String',cMethod,     'Position',[90 iY-298 115 20],'Callback',{@fSetTrackOpt,2});
    uicontrol(bgTLim,'Style','Edit',      'String','All',       'Position',[90 iY-323 115 20],'Callback',{@fSetTrackOpt,3});
    uicontrol(bgTLim,'Style','PushButton','String','Get Values','Position',[90 iY-350 115 20],'Callback',{@fGetTrackValues});
    
    % Defaults
    fAutoScaleTrack;

    
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

    function fSetTrackLim(uiSrc,~,iDim)
        
        dValue = str2double(uiSrc.String);
        iVar   = ceil(iDim/2);
        dValue = dValue/X.Track.Scale(iVar);

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

        if iDim == 5 || iDim == 6
            if dValue > X.XLim(iDim)
                dValue = X.XLim(iDim);
            end % if
        end % if

        if iDim == 7
            if dValue < 0.0
                dValue = 0.0;
            end % if
        end % if

        if iDim == 8
            if dValue > X.XLim(4)
                dValue = X.XLim(4);
            end % if
        end % if
        
        X.Track.Limits(iDim) = dValue;
        fAutoScaleTrack(iVar);
        
    end % function

    function fSetTrackOpt(uiSrc,~,iOpt)
        
        iValue = uiSrc.Value;
        
        % Units to SI/eV
        if iOpt == 1 && iValue == 1
            X.Track.Units(1:4) = {'m','m','m','m'};
            X.Track.Units(5:8) = {'eV','eV','eV','C'};
            X.Track.Scale(1:4) = [1 1 1 1]*1e3;
            X.Track.Scale(5:8) = [1 1 1 1];
            for i=1:8
                lblTLim(i).String = X.Track.Units{i};
            end % for
            fAutoScaleTrack;
        end % if
        
        % Units to Normalised
        if iOpt == 1 && iValue == 2
            X.Track.Units(1:4) = {'c/ω','c/ω','c/ω','c/ω'};
            X.Track.Units(5:8) = {'γβ','γβ','γβ','N'};
            X.Track.Scale(1:8) = [1 1 1 1 1 1 1 1];
            for i=1:8
                lblTLim(i).String = X.Track.Units{i};
            end % for
            fAutoScaleTrack;
        end % if
        
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

    function fOut(sText, iType)
        
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
        cOut = [cOut;{sText}];
        [iN, ~] = size(cOut);
        
        if iN > 100
            cOut(1) = [];
            iN = 100;
        end % if

        lstOut.String = cOut;
        lstOut.Value  = iN;
        
    end % function

    function fAutoScaleTrack(iVar)
        
        if nargin < 1
            iS = 1;
            iE = 8;
        else
            iS = iVar;
            iE = iVar;
        end % if
        
        for i=iS:iE
            
            iA = (2*i)-1;
            iB = 2*i;

            aVal = X.Track.Limits(iA:iB);
            if aVal(1) > aVal(2)
                dTemp   = aVal(1);
                aVal(1) = aVal(2);
                aVal(2) = dTemp;
                X.Track.Limits(iA:iB) = aVal;
            end %  if
            dMax = max(abs(aVal));
            
            [dVal,sUnit] = fAutoScale(dMax,X.Track.Units{i});
            
            if dMax ~= 0
                dScale = dVal/dMax;
            else
                dScale = 1.0;
            end % if
            
            X.Track.Scale(i)   = dScale;
            edtTLim(iA).String = sprintf('%.2f',aVal(1)*dScale);
            edtTLim(iB).String = sprintf('%.2f',aVal(2)*dScale);
            lblTLim(i).String  = sUnit;

        end % for
        
    end % function

end % function
