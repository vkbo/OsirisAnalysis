
%
%  GUI :: Phase Space
% ********************
%

function uiPhaseSpace(oData, varargin)

    %
    %  Input
    % *******
    %

    % Check Input
    if nargin < 1
        fprintf(2,'Error: Please provide an OsirisData object.\n');
        return;
    end %if

    % Read input parameters
    oOpt = inputParser;
    addParameter(oOpt, 'Position', []);
    addParameter(oOpt, 'ReUseFig', 'No');
    parse(oOpt, varargin{:});
    stOpt = oOpt.Results;

    %
    %  Figure
    % ********
    %
    
    if strcmpi(stOpt.ReUseFig,'Yes')
        fMain = findobj('Tag','uiOA-PS');
        set(0,'CurrentFigure',fMain);
        clf;
    else
        fMain = figure('IntegerHandle','Off'); clf;
    end % if
    
    aFPos = get(fMain, 'Position');
    figW  = 1100;
    figH  = 610;
    
    if isempty(stOpt.Position)
        figX = aFPos(1);
        figY = aFPos(2);
    else
        figX = stOpt.Position(1);
        figY = stOpt.Position(2);
    end % if
    
    % Set Figure Properties
    fMain.Units        = 'Pixels';
    fMain.MenuBar      = 'None';
    fMain.Position     = [figX figY figW figH];
    fMain.Name         = 'OsirisAnalysis: Phase Space';
    fMain.NumberTitle  = 'Off';
    fMain.DockControls = 'Off';
    fMain.Tag          = 'uiOA-PS';

    %
    %  Initial Values
    % ****************
    %
    
    % Colors
    cInfoBack   = [0.80 0.80 0.80];
    cInfoRed    = [1.00 0.50 0.50];
    cInfoYellow = [1.00 1.00 0.50];
    cInfoGreen  = [0.50 1.00 0.50];
    
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
    X.Grid    = oData.Config.Simulation.Grid;

    if isempty(X.Species)
        fprintf(2,'Error: Dataset contains no species.\n');
        return;
    end % if

    % Time Limits
    X.Limits(1) = oData.StringToDump('Start');  % Start of simulation
    X.Limits(2) = oData.StringToDump('PStart'); % Start of plasma
    X.Limits(3) = oData.StringToDump('PEnd');   % End of plasma
    X.Limits(4) = oData.StringToDump('End');    % End of simulation
    X.Dump      = X.Limits(1);
    
    % Defaults
    [~,iVal] = incellarray(oData.Config.Particles.DriveBeam{1}, X.Species);
    X.Data.Species = iVal + (iVal == 0);
    
    X.Data.Dims = 1;
    if X.Cyl
        X.Dims = {'Radial' 'Radius on X'};
        X.Data.Dims = 2;
    else
        if X.Dim == 3
            X.Data.Dims = 1;
            X.Dims = {'X Plane' 'Y Plane'};
        else
            X.Data.Dims = 1;
            X.Dims = {'X Plane'};
        end % if
    end % if
    
    X.Data.Grid    = [400 400];
    X.Data.Sample  = 1;
    X.Data.MinPart = 100000;
        
    
    %
    % Controls
    %
    
    iH = figH; % Top of elements
    
    uicontrol('Style','Text','String','Phase Space','FontSize',20,'Position',[20 iH-50 200 35],'HorizontalAlignment','Left');

    % Main Controls
    uicontrol('Style','Text','String',X.Name,'FontSize',18,'Position',[240 iH-40 240 25],'ForegroundColor',[1.00 1.00 0.00],'BackgroundColor',[0.80 0.80 0.80]);
    uicontrol('Style','PushButton','String','i','FontSize',15,'FontName','FixedWidth','FontWeight','Bold','Position',[485 iH-40 25 25],'ForegroundColor',[0.00 0.55 0.88],'Callback',{@fShowSimInfo});
    uicontrol('Style','PushButton','String','d','FontSize',15,'FontName','FixedWidth','FontWeight','Bold','Position',[510 iH-40 25 25],'ForegroundColor',[0.88 0.55 0.55],'Callback',{@fShowInputDeck});
    
    %  Data Controls
    % ===============
    
    bgData = uibuttongroup('Title','Source Data','Units','Pixels','Position',[20 20 170 100]);
    uicontrol(bgData,'Style','Text','String','Species:','Position',[10 60 150 20],'HorizontalAlignment','Left');
    uicontrol(bgData,'Style','PopupMenu','String',X.Species,'Value',X.Data.Species,'Position',[10 40 150 20],'Callback',{@fSetSpecies});
    uicontrol(bgData,'Style','Text','String','Dim:','Position',[10 10 50 20],'HorizontalAlignment','Left');
    uicontrol(bgData,'Style','PopupMenu','String',X.Dims,'Value',X.Data.Dims,'Position',[60 15 100 20],'Callback',{@fSetDim});
    
    %  Time Dump Controls
    % ====================

    bgTime = uibuttongroup('Title','Time Dump','Units','Pixels','Position',[200 20 210 100]);

    uicontrol(bgTime,'Style','PushButton','String','<<','Position',[ 9 60 30 20],'Callback',{@fDump, -10});
    uicontrol(bgTime,'Style','PushButton','String','<', 'Position',[39 60 30 20],'Callback',{@fDump,  -1});
    uicontrol(bgTime,'Style','PushButton','String','>', 'Position',[69 60 30 20],'Callback',{@fDump,   1});
    uicontrol(bgTime,'Style','PushButton','String','>>','Position',[99 60 30 20],'Callback',{@fDump,  10});

    uicontrol(bgTime,'Style','PushButton','String','<S','Position',[ 9 35 30 20],'Callback',{@fJump, 1});
    uicontrol(bgTime,'Style','PushButton','String','<P','Position',[39 35 30 20],'Callback',{@fJump, 2});
    uicontrol(bgTime,'Style','PushButton','String','P>','Position',[69 35 30 20],'Callback',{@fJump, 3});
    uicontrol(bgTime,'Style','PushButton','String','S>','Position',[99 35 30 20],'Callback',{@fJump, 4});

    lblDump(1) = uicontrol(bgTime,'Style','Text','String',X.Limits(1),'Position',[ 10 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(2) = uicontrol(bgTime,'Style','Text','String',X.Limits(2),'Position',[ 40 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(3) = uicontrol(bgTime,'Style','Text','String',X.Limits(3),'Position',[ 70 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(4) = uicontrol(bgTime,'Style','Text','String',X.Limits(4),'Position',[100 11 28 15],'BackgroundColor',cInfoBack);
    lblDump(5) = uicontrol(bgTime,'Style','Text','String',X.Dump,'FontSize',20,'Position',[135 48 63 30],'BackgroundColor',cInfoBack,'ForegroundColor',[0.00 0.55 0.00]);
    
                 uicontrol(bgTime,'Style','Text','String','Goto:','FontSize',8,'Position',[133 25 63 20],'HorizontalAlignment','Left');
    edtDump    = uicontrol(bgTime,'Style','Edit','String',X.Dump,'Position',[135 11 63 20],'Callback',{@fJump, 5});
    
    %  Simulation Info
    % =================

    bgInfo = uibuttongroup('Title','Simulation','Units','Pixels','Position',[420 20 110 100]);
    
    lblInfo(1) = uicontrol(bgInfo,'Style','Text','String','Geometry','Position',[9 60 90 17],'BackgroundColor',cInfoBack);
    lblInfo(2) = uicontrol(bgInfo,'Style','Text','String','Status',  'Position',[9 35 90 17],'BackgroundColor',cInfoBack);
    lblInfo(3) = uicontrol(bgInfo,'Style','Text','String','Tracks',  'Position',[9 10 90 17],'BackgroundColor',cInfoBack);

    % Geometry
    if X.Cyl
        sGeometry = 'Cyl';
    else
        sGeometry = 'Cart';
    end % if
    lblInfo(1).String          = sprintf('%s %dD',sGeometry,X.Dim);
    lblInfo(1).BackgroundColor = cInfoGreen;

    % Simulation Status
    if oData.HasData
        if oData.Completed
            lblInfo(2).String          = 'Completed';
            lblInfo(2).BackgroundColor = cInfoGreen;
        else
            lblInfo(2).String          = 'Incomplete';
            lblInfo(2).BackgroundColor = cInfoYellow;
        end % if
        if ~oData.Consistent
            lblInfo(2).String          = 'Inconsistent';
            lblInfo(2).BackgroundColor = cInfoYellow;
        end % if
    else
        lblInfo(2).String          = 'No Data';
        lblInfo(2).BackgroundColor = cInfoRed;
    end % if

    % Tracking Data
    if oData.HasTracks
        lblInfo(3).String          = 'Has Tracks';
        lblInfo(3).BackgroundColor = cInfoGreen;
    else
        lblInfo(3).String          = 'No Tracks';
        lblInfo(3).BackgroundColor = cInfoYellow;
    end % if

    %  Output Window
    % ===============

    lstOut = uicontrol('Style','Listbox','String','OsirisAnalysis: Phase Space','FontName','FixedWidth','Position',[540 20 540 93],'HorizontalAlignment','Left','BackgroundColor',[0.00 0.00 0.00],'ForegroundColor',[0.00 1.00 0.00]);
    jOut   = findjobj(lstOut);
    jList  = jOut.getViewport.getComponent(0);
    set(jList, 'SelectionBackground', java.awt.Color.black);
    set(jList, 'SelectionForeground', java.awt.Color.green);
    jList.setSelectionAppearanceReflectsFocus(0);
    
    %  Axes
    % ======
    
    axMain = axes('Units','Pixels','Position',[ 80 iH-440 500 350]);
    axHorz = axes('Units','Pixels','Position',[600 iH-440 220 160]); 
    axVert = axes('Units','Pixels','Position',[850 iH-440 220 160]);
    
    %  Settings Box A
    % ================
    
    bgSetA = uibuttongroup('Title','Resolution','Units','Pixels','Position',[600 iH-240 150 175]);

    uicontrol(bgSetA,'Style','Text','String','Sim. Grid', 'FontSize',8,'Position',[ 5 135 60 15],'HorizontalAlignment','Left');
    uicontrol(bgSetA,'Style','Text','String','HAxis',     'FontSize',8,'Position',[ 5 110 60 15],'HorizontalAlignment','Left');
    uicontrol(bgSetA,'Style','Text','String','VAxis',     'FontSize',8,'Position',[ 5  85 60 15],'HorizontalAlignment','Left');
    uicontrol(bgSetA,'Style','Text','String','Samples',   'FontSize',8,'Position',[ 5  60 60 15],'HorizontalAlignment','Left');
    uicontrol(bgSetA,'Style','Text','String','Min. Part.','FontSize',8,'Position',[ 5  35 60 15],'HorizontalAlignment','Left');
    uicontrol(bgSetA,'Style','Text','String','Count',     'FontSize',8,'Position',[ 5  10 60 15],'HorizontalAlignment','Left');
    
    lblSetA(1) = uicontrol(bgSetA,'Style','Text','String','0',     'Position',[69 135 70 17],'BackgroundColor',cInfoBack);
                 uicontrol(bgSetA,'Style','Edit','String','400',   'Position',[69 110 70 17],'Callback',{@fSettingA, 1});
                 uicontrol(bgSetA,'Style','Edit','String','400',   'Position',[69  85 70 17],'Callback',{@fSettingA, 2});
                 uicontrol(bgSetA,'Style','Edit','String','1',     'Position',[69  60 70 17],'Callback',{@fSettingA, 3});
                 uicontrol(bgSetA,'Style','Edit','String','100000','Position',[69  35 70 17],'Callback',{@fSettingA, 4});
    lblSetA(2) = uicontrol(bgSetA,'Style','Text','String','0',     'Position',[69  10 70 17],'BackgroundColor',cInfoBack);

    %  Parameter Set A
    % =================
    
    bgParA = uibuttongroup('Title','Emittance & Twiss','Units','Pixels','Position',[760 iH-240 135 175]);
    
    uicontrol(bgParA,'Style','Text','String','ϵ','FontSize',12,'Position',[ 5 135 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParA,'Style','Text','String','g','FontSize',7, 'Position',[16 133 10 10],'HorizontalAlignment','Left');
    uicontrol(bgParA,'Style','Text','String','ϵ','FontSize',12,'Position',[ 5 110 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParA,'Style','Text','String','n','FontSize',7, 'Position',[16 108 10 10],'HorizontalAlignment','Left');
    uicontrol(bgParA,'Style','Text','String','α','FontSize',12,'Position',[ 5  85 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParA,'Style','Text','String','β','FontSize',12,'Position',[ 5  60 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParA,'Style','Text','String','γ','FontSize',12,'Position',[ 5  35 20 17],'HorizontalAlignment','Left');

    lblParA(1) = uicontrol(bgParA,'Style','Text','String','0.0','Position',[29 135 70 17],'BackgroundColor',cInfoBack);
    lblParA(2) = uicontrol(bgParA,'Style','Text','String','0.0','Position',[29 110 70 17],'BackgroundColor',cInfoBack);
    lblParA(3) = uicontrol(bgParA,'Style','Text','String','0.0','Position',[29  85 70 17],'BackgroundColor',cInfoBack);
    lblParA(4) = uicontrol(bgParA,'Style','Text','String','0.0','Position',[29  60 70 17],'BackgroundColor',cInfoBack);
    lblParA(5) = uicontrol(bgParA,'Style','Text','String','0.0','Position',[29  35 70 17],'BackgroundColor',cInfoBack);
    
    lblUntA(1) = uicontrol(bgParA,'Style','Text','String','mm','FontSize',8,'Position',[102 135 25 15],'HorizontalAlignment','Left');
    lblUntA(2) = uicontrol(bgParA,'Style','Text','String','mm','FontSize',8,'Position',[102 110 25 15],'HorizontalAlignment','Left');
    lblUntA(3) = uicontrol(bgParA,'Style','Text','String','mm','FontSize',8,'Position',[102  85 25 15],'HorizontalAlignment','Left');
    lblUntA(4) = uicontrol(bgParA,'Style','Text','String','mm','FontSize',8,'Position',[102  60 25 15],'HorizontalAlignment','Left');
    lblUntA(5) = uicontrol(bgParA,'Style','Text','String','mm','FontSize',8,'Position',[102  35 25 15],'HorizontalAlignment','Left');
    
    %  Parameter Set B
    % =================
    
    bgParB = uibuttongroup('Title','Dimensions','Units','Pixels','Position',[905 iH-240 155 175]);
    
    uicontrol(bgParB,'Style','Text','String','H',   'FontSize',12,'Position',[ 5 135 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','RMS', 'FontSize',5, 'Position',[17 133 25 10],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','V',   'FontSize',12,'Position',[ 5 110 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','RMS', 'FontSize',5, 'Position',[17 105 25 10],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','H',   'FontSize',12,'Position',[ 5  85 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','FWHM','FontSize',5, 'Position',[17  83 25 10],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','V',   'FontSize',12,'Position',[ 5  60 20 17],'HorizontalAlignment','Left');
    uicontrol(bgParB,'Style','Text','String','FWHM','FontSize',5, 'Position',[17  58 25 10],'HorizontalAlignment','Left');

    lblParB(1) = uicontrol(bgParB,'Style','Text','String','0.0','Position',[44 135 70 17],'BackgroundColor',cInfoBack);
    lblParB(2) = uicontrol(bgParB,'Style','Text','String','0.0','Position',[44 110 70 17],'BackgroundColor',cInfoBack);
    lblParB(3) = uicontrol(bgParB,'Style','Text','String','0.0','Position',[44  85 70 17],'BackgroundColor',cInfoBack);
    lblParB(4) = uicontrol(bgParB,'Style','Text','String','0.0','Position',[44  60 70 17],'BackgroundColor',cInfoBack);
    
    lblUntB(1) = uicontrol(bgParB,'Style','Text','String','mm','FontSize',8,'Position',[117 135 35 15],'HorizontalAlignment','Left');
    lblUntB(2) = uicontrol(bgParB,'Style','Text','String','mm','FontSize',8,'Position',[117 110 35 15],'HorizontalAlignment','Left');
    lblUntB(3) = uicontrol(bgParB,'Style','Text','String','mm','FontSize',8,'Position',[117  85 35 15],'HorizontalAlignment','Left');
    lblUntB(4) = uicontrol(bgParB,'Style','Text','String','mm','FontSize',8,'Position',[117  60 35 15],'HorizontalAlignment','Left');

    %  Done Setup
    % ============
    
    oM = [];
    fRefreshSpecies;
    fRefreshDim;
    fRefresh;

    %
    %  Callback Functions
    % ********************
    %
    
    function fRefresh
        
        %  Main Plot
        % ===========
        
        % Prepare Data
        switch X.Data.Dims
            case 1
                sDims  = 'Rad';
                sDName = 'R';
            case 2
                sDims  = 'RadToX';
                sDName = 'X';
            case 3
                sDims  = 'X';
                sDName = 'X';
            case 4
                sDims  = 'Y';
                sDName = 'Y';
        end % switch

        oM.Time = X.Dump;
        stData  = oM.PhaseSpace('Histogram','Yes','Grid',X.Data.Grid,'Dimension',sDims,'Samples',X.Data.Sample,'MinParticles',X.Data.MinPart);
        
        aData  = stData.Hist;
        aHAxis = stData.HAxis;
        aVAxis = stData.VAxis;
        
        axes(axMain); cla;
        hold on;
        
        imagesc(aHAxis, aVAxis, aData);
        set(gca,'YDir','Normal');
        colormap('hot');
        hCol = colorbar();

        hold off;
        
        xlim([aHAxis(1) aHAxis(end)]);
        ylim([aVAxis(1) aVAxis(end)]);

        title(sprintf('%s%s'' Phase Space %s',sDName,sDName,oM.PlasmaPosition));
        xlabel(sprintf('%s [%s]',lower(sDName),stData.XUnit));
        ylabel(sprintf('%s'' [%s]',lower(sDName),stData.XPrimeUnit));
        
        %  Horizontal Plot
        % =================
        
        aLine  = sum(aData,1);
        aLine  = aLine/max(aLine);
        dHRMS  = wstd(aHAxis,aLine);
        dHFWHM = fwhm(aHAxis,aLine);

        axes(axHorz); cla;
        plot(aHAxis, aLine);
        
        axHorz.YTick = [];
        title('Horizontal');
        xlabel(sprintf('%s [%s]',lower(sDName),stData.XUnit));
        
        ylim([0 1.05]);
        
        %  Vertical Plot
        % ===============

        aLine  = sum(aData,2);
        aLine  = aLine/max(aLine);
        dVRMS  = wstd(aVAxis,aLine);
        dVFWHM = fwhm(aVAxis,aLine);

        axes(axVert); cla;
        plot(aVAxis, aLine);

        axVert.YTick = [];
        title('Vertical');
        xlabel(sprintf('%s'' [%s]',lower(sDName),stData.XPrimeUnit));

        ylim([0 1.05]);
        
        %  Set Values
        % ============
        
        [dERMS, sERMS]  = fAutoScale(stData.ERMS*1e-6, 'm',1e-15);
        [dENorm,sENorm] = fAutoScale(stData.ENorm*1e-6,'m',1e-15);
        [dAlpha,sAlpha] = fAutoScale(stData.Alpha     ,'m',1e-15);
        [dBeta, sBeta]  = fAutoScale(stData.Beta      ,'m',1e-15);
        [dGamma,sGamma] = fAutoScale(stData.Gamma     ,'m',1e-15);
        
        lblParA(1).String = sprintf('%.2f',dERMS);
        lblUntA(1).String = sprintf('%s',  sERMS);
        lblParA(2).String = sprintf('%.2f',dENorm);
        lblUntA(2).String = sprintf('%s',  sENorm);
        lblParA(3).String = sprintf('%.2f',dAlpha);
        lblUntA(3).String = sprintf('%s',  sAlpha);
        lblParA(4).String = sprintf('%.2f',dBeta);
        lblUntA(4).String = sprintf('%s',  sBeta);
        lblParA(5).String = sprintf('%.2f',dGamma);
        lblUntA(5).String = sprintf('%s',  sGamma);
        
        [dHRMS,  sHRMS]  = fAutoScale(dHRMS*1e-3, 'm',  1e-15);
        [dVRMS,  sVRMS]  = fAutoScale(dVRMS*1e-3, 'rad',1e-15);
        [dHFWHM, sHFWHM] = fAutoScale(dHFWHM*1e-3,'m',  1e-15);
        [dVFWHM, sVFWHM] = fAutoScale(dVFWHM*1e-3,'rad',1e-15);

        lblParB(1).String = sprintf('%.2f',dHRMS);
        lblUntB(1).String = sprintf('%s',  sHRMS);
        lblParB(2).String = sprintf('%.2f',dVRMS);
        lblUntB(2).String = sprintf('%s',  sVRMS);
        lblParB(3).String = sprintf('%.2f',dHFWHM);
        lblUntB(3).String = sprintf('%s',  sHFWHM);
        lblParB(4).String = sprintf('%.2f',dVFWHM);
        lblUntB(4).String = sprintf('%s',  sVFWHM);
        
        
        lblSetA(2).String = sprintf('%d',  stData.Count);

    end % function

    function fRefreshSpecies

        vSpecies = oData.Translate.Lookup(X.Species{X.Data.Species},'Species');
        fOut(['Source Data: ' vSpecies.Full],1);
        oM = Momentum(oData,vSpecies.Name,'Units','SI','Scale','mm');

    end % finction

    function fRefreshDim
        
        if  X.Data.Dims == 4
            lblSetA(1).String = sprintf('%d',X.Grid(3));
        else
            lblSetA(1).String = sprintf('%d',X.Grid(2));
        end % if
        
    end % function
    
    %  Operations
    % ============
    
    function fSetSpecies(uiSrc,~)
        
        X.Data.Species = uiSrc.Value;
        fRefreshSpecies;
        fRefresh;
        
    end % function

    function fSetDim(uiSrc,~)
        
        sDims = uiSrc.String{uiSrc.Value};
        if strcmpi(sDims, 'Radial')
            X.Data.Dims = 1;
        elseif strcmpi(sDims, 'Radius on X')
            X.Data.Dims = 2;
        elseif strcmpi(sDims, 'X Plane')
            X.Data.Dims = 3;
        elseif strcmpi(sDims, 'Y Plane')
            X.Data.Dims = 4;
        end % if
        fRefreshDim;
        fRefresh;
        
    end % function

    function fSettingA(uiSrc,~,iSet)

        if iSet == 1 || iSet == 2
            iValue = floor(str2double(uiSrc.String)/2)*2;
            if iValue <= 0
                iValue = 2;
            end % if
            uiSrc.String = sprintf('%d',iValue);
            X.Data.Grid(iSet) = iValue;
        end % if

        if iSet == 3 || iSet == 4
            iValue = floor(str2double(uiSrc.String));
            if iValue <= 0
                iValue = 1;
            end % if
            uiSrc.String = sprintf('%d',iValue);
            if iSet == 3
                X.Data.Sample = iValue;
            end % if
            if iSet == 4
                X.Data.MinPart = iValue;
            end % if
        end % if

        fRefresh;

    end % if

    function fDump(~,~,iStep)
        
        X.Dump = X.Dump + iStep;
        
        if X.Dump < X.Limits(1)
            X.Dump = X.Limits(1);
            fOut('At the start of the dataset',2);
        end % if

        if X.Dump > X.Limits(4)
            X.Dump = X.Limits(4);
            fOut('At the end of the dataset',2);
        end % if
        
        lblDump(5).String = sprintf('%d',X.Dump);

        fRefresh;
        
    end % function

    function fJump(~,~,iJump)
        
        if iJump == 5
            iValue = floor(str2double(edtDump.String));
            X.Dump = iValue;
        else
            X.Dump = X.Limits(iJump);
        end % if

        lblDump(5).String = sprintf('%d',X.Dump);
        
        fRefresh;
        
    end % function

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

    function fShowSimInfo(~,~)
        
        msgbox(oData.Config.Details,'Simulation Description');
        
    end % function

    function fShowInputDeck(~,~)
        
        sFile = [oData.Config.Path '/' oData.Config.File];
        system(['gedit ' sFile ' &']);
        fOut(['Opening ' sFile],1);
        
    end % function
    
end % end GUI function
