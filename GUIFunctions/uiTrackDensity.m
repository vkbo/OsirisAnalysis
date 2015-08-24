
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
    X.Track.Width = 0.5;
    X.Track.Pos   = X.Track.Width/2;
    X.Track.Anchor = X.Track.Pos;
    X.Track.Target = X.Track.Anchor;

    % Figure
    fMain = gcf; clf;
    aFPos = get(fMain, 'Position');
    
    % Set figure properties
    set(fMain, 'Units', 'Pixels');
    set(fMain, 'Position', [aFPos(1:2) 900 900]);
    set(fMain, 'Name', 'Track Density');
    
    % Density Class
    oField = EField(oData, 'e1', 'Units', 'SI', 'X1Scale', 'mm');
    oField.Time = 10;

    X.Range = oField.AxisRange(1:2);
    if X.Size > X.Range(2)
        X.Size = X.Range(2);
        X.Lim(2) = X.Size;
    end % if


    %  Controls
    % **********
    
    % Axes
    axMain  = axes('Units','Pixels','Position',[60 600 600 250]);
    axTrack = axes('Units','Pixels','Position',[60 200 300 250]);
    
    dMax = X.Range(2) - X.Size;
    sldMain = uicontrol('Style','Slider','Min',0.0,'Max',dMax,'Value',0.0,'Position',[60 550 600 20],'Callback',{@fMainPos});

    sldTrack = uicontrol('Style','Slider','Min',X.Lim(1),'Max',X.Lim(2),'Value',X.Lim(1),'Position',[60 520 600 20],'Callback',{@fTrackPos});
    
    fLoadField();
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
        end % if
        if sldTrack.Value > sldTrack.Max
            sldTrack.Value = sldTrack.Max;
        end % if

        xlim(axMain,X.Lim);
        
    end % function

    function fTrackPos(uiSrc,~)
        
        dTrack = uiSrc.Value;
        X.Track.Pos = dTrack;
        fRefreshTrack();
        
    end % function
    
    %
    %  Data Functions
    % ****************
    %
    
    function fLoadField()
        
        X.Field = oField.Lineout(3,3);
        
    end % function

    
    %
    %  Refresh Functions
    % *******************
    %

    function fRefreshMain()

        aLine   = X.Field.Data;
        aX1Axis = X.Field.X1Axis;
        
        axes(axMain);
        plot(aX1Axis, aLine);
        xlim(X.Lim);

    end % function

    function fRefreshTrack()
        
        aLine = X.Field.Data;
        aAxis = X.Field.X1Axis;
        
        dXMin = X.Track.Pos - X.Track.Width;
        dXMax = X.Track.Pos + X.Track.Width;
        iXMin = fGetIndex(aAxis, dXMin);
        iXMax = fGetIndex(aAxis, dXMax);
        
        dYMax = max(abs(aLine(iXMin:iXMax)));
        dYMin = -dYMax;
        
        dFMin = X.Track.Pos - X.Track.Width/2;
        dFMax = X.Track.Pos + X.Track.Width/2;
        iFMin = fGetIndex(aAxis, dFMin);
        iFMax = fGetIndex(aAxis, dFMax);
        
        [dP,~,dMu] = polyfit(aAxis(iFMin:iFMax),aLine(iFMin:iFMax),3);
        
        aFit = polyval(dP,(aAxis(iXMin:iXMax)-dMu(1))/dMu(2));
        aFitT = polyval(dP,(aAxis(iFMin:iFMax)-dMu(1))/dMu(2));
        [~,iTMin] = min(abs(aFitT));
        dTrack = aAxis(iFMin+iTMin-1);
        X.Track.Anchor = dTrack;
        
        axes(axTrack);
        cla;
        hold on;
        plot(aAxis, aLine, 'Color', [0.0 0.0 1.0]);
        plot(aAxis(iXMin:iXMax), aFit, 'Color', [1.0 0.0 0.0],'LineStyle','--');
        line([dFMin dFMin],[dYMin dYMax],'Color',[1.0 0.0 0.0]);
        line([dFMax dFMax],[dYMin dYMax],'Color',[1.0 0.0 0.0]);
        line([dTrack dTrack],[dYMin dYMax],'Color',[0.0 0.0 0.0]);
        hold off;
        xlim([dXMin dXMax]);
        ylim([dYMin dYMax]);
        
    end % function

end % function
