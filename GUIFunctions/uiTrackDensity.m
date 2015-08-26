
%
%  GUI :: Track Density
% *************************
%

function uiTrackDensity(oData)


    % Data
    
    X.Size  = 30.0;
    X.Lim   = [0.0 30.0];
    X.Range = [0 1];
    X.Field = struct();
    X.Track.Name = '';
    X.Track.Source = 1;
    X.Track.Width = 0.5;
    X.Track.Pos   = X.Track.Width/2;
    X.Track.Anchor = X.Track.Pos;
    X.Limits(1) = fStringToDump(oData,'Start');
    X.Limits(2) = fStringToDump(oData,'PStart');
    X.Limits(3) = fStringToDump(oData,'PEnd');
    X.Limits(4) = fStringToDump(oData,'End');
    X.Dump = X.Limits(2);
    
    X.Track.Time = [X.Limits(2) X.Limits(3)];
    X.Track.Data = [];
    X.Track.Tracking = 0;
    
    X.Track.Point = 1;
    X.Track.PolyFit = 3;
    
    X.Sets.E1 = {};
    X.Sets.E2 = {};
    X.Sets.EB = {};
    X.Sets.PB = {};
    
    X.Values.Point = {'Zero','Minimum','Maximum'};
    X.Values.PolyFit = {'PolyFit 1','PolyFit 2','PolyFit 3','PolyFit 4','PolyFit 5'};
    X.Values.Source = {'EField 1','EField 2','EBeam','PBeam'};

    % Get Time Axis
    iDumps  = oData.Elements.FLD.e1.Info.Files-1;
    dPStart = oData.Config.Variables.Plasma.PlasmaStart;
    dTFac   = oData.Config.Variables.Convert.SI.TimeFac;
    dLFac   = oData.Config.Variables.Convert.SI.LengthFac;
    X.TAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
    
    % Figure
    fMain = gcf; clf;
    aFPos = get(fMain, 'Position');
    iH    = 770;
    
    % Set figure properties
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'Position', [aFPos(1:2) 915 iH]);
    set(fMain, 'Name', 'Track Density');
    
    % Density Class
    oFieldE1 = [];
    oFieldE2 = [];
    oDensEB  = [];
    oDensPB  = [];
    
    fLoadField();

    X.Range = oFieldE1.AxisRange(1:2);
    if X.Size > X.Range(2)
        X.Size = X.Range(2);
        X.Lim(2) = X.Size;
    end % if


    %  Controls
    % **********
    
    % Axes
    axMain   = axes('Units','Pixels','Position',[340 iH-290 550 230]);
    axTrack  = axes('Units','Pixels','Position',[ 70 iH-700 300 250]);
    axResult = axes('Units','Pixels','Position',[450 iH-700 400 250]);
    
    uicontrol('Style','Text','String','Track Density','FontSize',20,'Position',[20 iH-50 200 35],'HorizontalAlignment','Left');
    
    % Controls

    bgCtrl = uibuttongroup('Title','Controls','Units','Pixels','Position',[20 iH-240 250 190]);
    
    uicontrol(bgCtrl,'Style','Text','String','Track Start','Position',[10 140 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Track Stop', 'Position',[10 115 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Source Data','Position',[10  90 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Fit Method', 'Position',[10  65 100 20],'HorizontalAlignment','Left');
    uicontrol(bgCtrl,'Style','Text','String','Track Point','Position',[10  40 100 20],'HorizontalAlignment','Left');

    uicontrol(bgCtrl,'Style','PushButton','String','<S','Position',[175 145 30 20],'Callback',{@fJump, 1});
    uicontrol(bgCtrl,'Style','PushButton','String','<P','Position',[205 145 30 20],'Callback',{@fJump, 2});
    uicontrol(bgCtrl,'Style','PushButton','String','P>','Position',[175 120 30 20],'Callback',{@fJump, 3});
    uicontrol(bgCtrl,'Style','PushButton','String','S>','Position',[205 120 30 20],'Callback',{@fJump, 4});

    edtStart   = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Time(1),           'Position',[115 145  55 20],'Callback',{@fSetStart});
    edtStop    = uicontrol(bgCtrl,'Style','Edit',     'String',X.Track.Time(2),           'Position',[115 120  55 20],'Callback',{@fSetStop});
    pumSource  = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Values.Source, 'Value',1,'Position',[115  95 120 20],'Callback',{@fSetSource});
    pumPolyFit = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Values.PolyFit,'Value',3,'Position',[115  70 120 20],'Callback',{@fTrackPolyFit});
    pumPoint   = uicontrol(bgCtrl,'Style','PopupMenu','String',X.Values.Point,  'Value',1,'Position',[115  45 120 20],'Callback',{@fTrackPoint});

    btnTrack   = uicontrol(bgCtrl,'Style','PushButton','String','Start Tracking','Position',[ 10 10 120 25],'Callback',{@fStartTrack});
    btnReset   = uicontrol(bgCtrl,'Style','PushButton','String','Reset',         'Position',[135 10 100 25],'Callback',{@fResetTrack});

    % Tracking Sets
    
    bgSets = uibuttongroup('Title','Tracking Data','Units','Pixels','Position',[20 iH-380 250 140]);
    
    lstSets   = uicontrol(bgSets,'Style','Listbox','Position',[10 35 225 80],'Callback',{@fTrackSets});
    btnLoad   = uicontrol(bgSets,'Style','PushButton','String','Load',  'Position',[ 110 10 60 20],'Callback',{@fSetLoad});
    btnDelete = uicontrol(bgSets,'Style','PushButton','String','Delete','Position',[ 175 10 60 20],'Callback',{@fSetLoad});

    
    dMax = X.Range(2)-X.Size;
    lblMain  = uicontrol('Style','Text','String','Window','Position',[280 iH-365 60 20],'HorizontalAlignment','Left');
    sldMain  = uicontrol('Style','Slider','Position',[340 iH-360 550 15],'Callback',{@fMainPos});
               set(sldMain, 'Min',        0.0);
               set(sldMain, 'Max',        dMax);
               set(sldMain, 'Value',      0.0);
               set(sldMain, 'SliderStep', [0.02 0.2]);

    lblTrack = uicontrol('Style','Text','String','Tracking','Position',[280 iH-385 60 20],'HorizontalAlignment','Left');
    sldTrack = uicontrol('Style','Slider','Position',[340 iH-380 550 15],'Callback',{@fTrackPos});
               set(sldTrack, 'Min',        X.Lim(1));
               set(sldTrack, 'Max',        X.Lim(2));
               set(sldTrack, 'Value',      X.Lim(1));
               set(sldTrack, 'SliderStep', [0.002 0.02]);
    
    iWidth   = X.Track.Time(2)-X.Track.Time(1);
    lblTime  = uicontrol('Style','Text','String','Time','Position',[20 iH-415 60 20],'HorizontalAlignment','Left');
    sldTime  = uicontrol('Style','Slider','Position',[80 iH-410 810 15],'Callback',{@fTrackTime});
               set(sldTime, 'Min',        X.Track.Time(1));
               set(sldTime, 'Max',        X.Track.Time(2));
               set(sldTime, 'Value',      X.Track.Time(1));
               set(sldTime, 'SliderStep', [1/iWidth 1/iWidth]);
    
    % Init

    fRefreshMain();
    fRefreshTrack();
    
    
    %
    %  Callback Functions
    % ********************
    %

    function fMainPos(uiSrc,~)
        
        dPos = uiSrc.Value;
        X.Lim = [dPos dPos+X.Size];
        
        sldTrack.Min = X.Lim(1);
        sldTrack.Max = X.Lim(2);

        % Check Values
        if sldTrack.Value < sldTrack.Min
            sldTrack.Value = sldTrack.Min;
            fTrackPos(sldTrack,0);
        end % if
        if sldTrack.Value > sldTrack.Max
            sldTrack.Value = sldTrack.Max;
            fTrackPos(sldTrack,0);
        end % if

        xlim(axMain,X.Lim);
        
    end % function

    function fTrackPos(uiSrc,~)
        
        dTrack = uiSrc.Value;
        X.Track.Pos = dTrack;
        fRefreshTrack();
        fRefreshMain();
        
    end % function

    function fStartTrack(~,~)
        
        X.Track.Data = [];
        X.Track.Tracking = 1;
        X.Track.Name = X.Values.Source{X.Track.Source};
        
        for t=X.Track.Time(1):X.Track.Time(2)
            X.Dump = t;
            oField.Time = t;
            sldTime.Value = t;
            fLoadField();
            X.Track.Pos = X.Track.Anchor;
            fRefreshMain();
            fRefreshTrack();
            drawnow;
        end % for
        
        switch(X.Track.Source)
            case 1
                X.Sets.E1 = X.Track;
            case 2
                X.Sets.E2 = X.Track;
            case 3
                X.Sets.EB = X.Track;
            case 4
                X.Sets.PB = X.Track;
        end % Switch
        
        fRefreshResult();
        
    end % function

    function fResetTrack(~,~)
        
        X.Track.Data = [];
        X.Track.Tracking = 0;
        X.Track.Width = 0.5;
        %X.Track.Pos = X.Track.Width/2;
        %X.Track.Anchor = X.Track.Pos;

        X.Dump = X.Track.Time(1);
        
        %sldMain.Value  = sldMain.Min;
        %sldTrack.Value = sldTrack.Min;
        sldTime.Value = X.Track.Time(1);
        
        fLoadField();
        fRefreshMain();
        fRefreshTrack();
        drawnow;

    end % function

    function fTrackTime(uiSrc,~)
        
        iTime = round(uiSrc.Value);
        X.Dump = iTime;
        fLoadField();
        if X.Track.Tracking
            X.Track.Pos = X.Track.Data(iTime);
        end % if
        fRefreshMain();
        fRefreshTrack();
        drawnow;

    end % function

    % Options
    
    function fTrackPoint(uiSrc,~)

        X.Track.Point = uiSrc.Value;
        fRefreshMain();
        fRefreshTrack();
        drawnow;
    
    end % function

    function fTrackPolyFit(uiSrc,~)

        X.Track.PolyFit = uiSrc.Value;
        fRefreshMain();
        fRefreshTrack();
        drawnow;

    end % function

    function fSetStart(uiSrc,~)
        
        iTime = round(str2num(uiSrc.String));
        if iTime < X.Limits(1)
            iTime = X.Limits(1);
        end % if
        uiSrc.String = iTime;

        X.Track.Time(1) = iTime;
        sldTime.Min     = iTime;
        if sldTime.Value < sldTime.Min
            sldTime.Value = sldTime.Min;
        end % if
        
        fTrackTime(sldTime,0);
        
    end % function

    function fSetStop(uiSrc,~)

        iTime = round(str2num(uiSrc.String));
        if iTime > X.Limits(4)
            iTime = X.Limits(4);
        end % if
        uiSrc.String = iTime;

        X.Track.Time(2) = iTime;
        sldTime.Max     = iTime;
        if sldTime.Value > sldTime.Max
            sldTime.Value = sldTime.Max;
        end % if

        fTrackTime(sldTime,0);

    end % function

    function fSetSource(uiSrc,~)

        X.Track.Source = uiSrc.Value;
        fTrackTime(sldTime,0);

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
    %  Data Functions
    % ****************
    %
    
    function fLoadField()
        
        oFieldE1 = EField(oData, 'e1', 'Units', 'SI', 'X1Scale', 'mm');
        oFieldE1.Time = X.Dump;
        X.Field.E1 = oFieldE1.Lineout(3,3);

        oFieldE2 = EField(oData, 'e2', 'Units', 'SI', 'X1Scale', 'mm');
        oFieldE2.Time = X.Dump;
        X.Field.E2 = oFieldE2.Lineout(3,3);
        
        oDensEB = Charge(oData, 'EB', 'Units', 'SI', 'X1Scale', 'mm');
        oDensEB.Time = X.Dump;
        X.Field.EB = oDensEB.Lineout(3,3);

        oDensPB = Charge(oData, 'PB', 'Units', 'SI', 'X1Scale', 'mm');
        oDensPB.Time = X.Dump;
        X.Field.PB = oDensPB.Lineout(3,3);

    end % function

    
    %
    %  Refresh Functions
    % *******************
    %

    function fRefreshMain()

        % EField

        switch(X.Track.Source)
            case 2
                aLine = X.Field.E2.Data;
                aAxis = X.Field.E2.X1Axis;
                aCol  = [0.7 0.7 0.0];
            otherwise
                aLine = X.Field.E1.Data;
                aAxis = X.Field.E1.X1Axis;
                aCol  = [0.0 0.7 0.0];
        end % switch
        
        dMax = max(abs(aLine));
        [dValue, sUnit] = fAutoScale(dMax, 'eV');
        dFac = dValue/dMax;
        
        dYMax = 1.1*dMax*dFac;
        dYMin = -dYMax;
        dXMin = X.Track.Pos - X.Track.Width/2;
        
        % Beams
        
        aEBeam = abs(X.Field.EB.Data);
        aPBeam = abs(X.Field.PB.Data);
        
        aEBeam = dYMax*aEBeam/max(aEBeam)+dYMin;
        aPBeam = dYMax*aPBeam/max(aPBeam)+dYMin;
        
        
        axes(axMain); cla;
        hold on;

        rectangle('Position',[dXMin dYMin X.Track.Width dYMax-dYMin], ...
                  'FaceColor',[0.9 0.9 0.9], ...
                  'EdgeColor',[0.5 0.5 0.5]);
        
        plot(aAxis, aLine*dFac, 'Color', aCol);
        plot(aAxis, aEBeam,     'Color', [0.7 0.0 0.0]);
        plot(aAxis, aPBeam,     'Color', [0.0 0.0 0.7]);

        hold off;

        xlim(X.Lim);
        ylim([dYMin dYMax]);
        
        title('Current Data Set');
        xlabel('\xi [mm]');
        ylabel(sprintf('E (%s)',sUnit));

    end % function

    function fRefreshTrack()
        
        switch(X.Track.Source)
            case 1
                aLine = X.Field.E1.Data;
                aAxis = X.Field.E1.X1Axis;
            case 2
                aLine = X.Field.E2.Data;
                aAxis = X.Field.E2.X1Axis;
            case 3
                aLine = X.Field.EB.Data;
                aAxis = X.Field.EB.X1Axis;
            case 4
                aLine = X.Field.PB.Data;
                aAxis = X.Field.PB.X1Axis;
        end % switch
        
        if X.Track.Source < 3
            dMax = max(abs(aLine));
            [dValue, sUnit] = fAutoScale(dMax, 'eV');
            dFac = dValue/dMax;
            aLine = aLine*dFac;
        else
            aLine = abs(aLine);
            aLine = aLine/max(aLine);
        end % if

        dXMin = X.Track.Pos - X.Track.Width;
        dXMax = X.Track.Pos + X.Track.Width;
        iXMin = fGetIndex(aAxis, dXMin);
        iXMax = fGetIndex(aAxis, dXMax);
        
        if X.Track.Source < 3
            dYMax = 1.1*max(abs(aLine(iXMin:iXMax)));
            dYMin = -dYMax;
        else
            dYMax =  1.05;
            dYMin = -0.05;
        end % if
        
        dFMin = X.Track.Pos - X.Track.Width/2;
        dFMax = X.Track.Pos + X.Track.Width/2;
        iFMin = fGetIndex(aAxis, dFMin);
        iFMax = fGetIndex(aAxis, dFMax);
        
        [dP,~,dMu] = polyfit(aAxis(iFMin:iFMax),aLine(iFMin:iFMax),X.Track.PolyFit);
        
        aFit = polyval(dP,(aAxis(iXMin:iXMax)-dMu(1))/dMu(2));
        aFitT = polyval(dP,(aAxis(iFMin:iFMax)-dMu(1))/dMu(2));
        
        switch(X.Track.Point)
            case 1
                [~,iTMin] = min(abs(aFitT));
                dTrack = aAxis(iFMin+iTMin-1);
            case 2
                [~,iTMin] = min(aFitT);
                dTrack = aAxis(iFMin+iTMin-1);
            case 3
                [~,iTMax] = max(aFitT);
                dTrack = aAxis(iFMin+iTMax-1);
        end % Switch
        X.Track.Anchor = dTrack;
        
        if X.Track.Tracking
            X.Track.Data(end+1) = dTrack;
        end % if
        
        axes(axTrack); cla;
        hold on;

        rectangle('Position',[dFMin dYMin dFMax-dFMin dYMax-dYMin], ...
                  'FaceColor',[0.9 0.9 0.9], ...
                  'EdgeColor',[0.5 0.5 0.5]);
        
        plot(aAxis, aLine, 'Color', [0.0 0.0 1.0]);
        plot(aAxis(iXMin:iXMax), aFit, 'Color', [1.0 0.0 0.0]);

        line([dTrack dTrack],[dYMin dYMax],'Color',[0.2 0.2 0.2]);
        
        hold off;
        
        xlim([dXMin dXMax]);
        ylim([dYMin dYMax]);

        title(sprintf('Tracking: Dump %d',X.Dump));
        xlabel('\xi [mm]');
        if X.Track.Source < 3
            ylabel(sprintf('E (%s)',sUnit));
        else
            ylabel('Q/max(Q)');
        end % if
        
    end % function

    function fRefreshResult()
        
        aAxis = X.TAxis(X.Track.Time(1):X.Track.Time(2));
        
        dTMax = 0.0;
        if ~isempty(X.Sets.E1)
            aDataE1 = (X.Sets.E1.Data - X.Sets.E1.Data(1))*1e-3;
            dMax = max(abs(aDataE1));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        if ~isempty(X.Sets.E2)
            aDataE2 = (X.Sets.E2.Data - X.Sets.E2.Data(1))*1e-3;
            dMax = max(abs(aDataE2));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        if ~isempty(X.Sets.EB)
            aDataEB = (X.Sets.EB.Data - X.Sets.EB.Data(1))*1e-3;
            dMax = max(abs(aDataEB));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        if ~isempty(X.Sets.PB)
            aDataPB = (X.Sets.PB.Data - X.Sets.PB.Data(1))*1e-3;
            dMax = max(abs(aDataPB));
            if dMax > dTMax
                dTMax = dMax;
            end % if
        end % if
        [dValue, sUnit] = fAutoScale(dTMax, 'm');
        dFac = dValue/dTMax;
        
        axes(axResult); cla;
        hold on;
        if ~isempty(X.Sets.E1)
            plot(aAxis,aDataE1*dFac);
        end % for
        if ~isempty(X.Sets.E2)
            plot(aAxis,aDataE2*dFac);
        end % for
        if ~isempty(X.Sets.EB)
            plot(aAxis,aDataEB*dFac);
        end % for
        if ~isempty(X.Sets.PB)
            plot(aAxis,aDataPB*dFac);
        end % for
        hold off;
        
        xlim([aAxis(1) aAxis(end)]);

        title('Tracking Result');
        xlabel('z [m]');
        ylabel(sprintf('\\xi [%s]',sUnit));
        
    end % function

end % function
