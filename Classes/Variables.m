
%
%  Class Object :: Translates Variable Name
% ******************************************
%

classdef Variables

    %
    % Properties
    %

    properties(GetAccess='public', SetAccess='private')
        
        Coords  = 1;    % 0 = cylindrical, 1 = cartesian
        Running = true; % 0 = returns z, 1 = return \xi

    end % properties

    properties(GetAccess='private', SetAccess='private')

        Types = {};
        Map   = {};

    end % properties

    %
    % Constructor
    %

    methods

        function obj = Variables(vCoords, bRunning)
            
            %
            %  Variables :: Constructor
            % **************************
            %  The constructor generates the full translation map on the fly.
            %

            %
            % Check Inputs
            %

            if nargin < 2
                bRunning = true;
            end % if
            if nargin < 1
                vCoords = 'cylindrical';
            end % if
            
            obj.Running = bRunning;

            % Coordinates
            switch lower(vCoords)
                case 'cylindrical'
                    iCoords = 1;
                case 'cartesian'
                    iCoords = 2;
                otherwise
                    iCoords = 1;
            end % switch
            obj.Coords = iCoords;

            obj.Types = {'Beam','Plasma','Species', ...
                         'Axis','Momentum','Angular','Current', ...
                         'EField','BField','EFieldExt','BFieldExt', ...
                         'EFieldPart','BFieldPart','EFieldEnergy','BFieldEnergy', ...
                         'Field','FieldEnergy','FieldDiv','Wakefield', ...
                         'Quantity','Flux','Poynting','Ufl','Uth'};


            %
            %  Create Translation Map
            % ************************
            %

            % Species names used in OsirisAnalysis
            stMap.Allowed.Beam    = {'ElectronBeam','PositronBeam','ProtonBeam','IonBeam'};
            stMap.Allowed.Plasma  = {'PlasmaElectrons','PlasmaProtons','PlasmaIons'};
            stMap.Allowed.Species = [stMap.Allowed.Beam,stMap.Allowed.Plasma];

            % Osiris variables
            stMap.Allowed.Axis         = {'x1','x2','x3','xi'};
            stMap.Allowed.Momentum     = {'p1','p2','p3'};
            stMap.Allowed.Angular      = {'l1','l2','l3'};
            stMap.Allowed.Current      = {'j1','j2','j3'};
            stMap.Allowed.EField       = {'e1','e2','e3','e'};
            stMap.Allowed.BField       = {'b1','b2','b3','b'};
            stMap.Allowed.EFieldExt    = {'ext_e1','ext_e2','ext_e3'};
            stMap.Allowed.BFieldExt    = {'ext_b1','ext_b2','ext_b3'};
            stMap.Allowed.EFieldPart   = {'part_e1','part_e2','part_e3'};
            stMap.Allowed.BFieldPart   = {'part_b1','part_b2','part_b3'};
            stMap.Allowed.EFieldEnergy = {'ene_e1','ene_e2','ene_e3','ene_e'};
            stMap.Allowed.BFieldEnergy = {'ene_b1','ene_b2','ene_b3','ene_b'};
            stMap.Allowed.Field        = [stMap.Allowed.EField,stMap.Allowed.BField];
            stMap.Allowed.FieldEnergy  = [stMap.Allowed.EFieldEnergy,stMap.Allowed.BFieldEnergy,{'ene_emf'}];
            stMap.Allowed.FieldDiv     = {'div_e','div_b'};
            stMap.Allowed.Quantity     = {'charge','|charge|','chargecons','m','ene','g','gl','psi','t'};
            stMap.Allowed.Flux         = {'q1','q2','q3'};
            stMap.Allowed.Poynting     = {'s1','s2','s3'};
            stMap.Allowed.UDist        = {'ufl1','ufl2','ufl3','uth1','uth2','uth3'};
            stMap.Allowed.RawAxis      = {'x1','x2','x3','p1','p2','p3','ene','charge','tag1','tag2'};

            % Calculated quantities (not in Osiris)
            stMap.Allowed.Wakefield    = {'w1','w2','w3'}; % Calculated from e1, e2, e3, b1 and b3

            % Osiris diagnostics options
            stMap.Diag.EMF        = {'e1','e2','e3','b1','b2','b3', ...
                                     'ext_e1','ext_e2','ext_e3','ext_b1','ext_b2','ext_b3', ...
                                     'part_e1','part_e2','part_e3','part_b1','part_b2','part_b3', ...
                                     'ene_e1','ene_e2','ene_e3','ene_b1','ene_b2','ene_b3', ...
                                     'ene_e','ene_b','ene_emf', ...
                                     'div_e','div_b','chargecons','psi', ...
                                     's1','s2','s3'};
            stMap.Diag.Species    = {'charge','m','ene','q1','q2','q3','j1','j2','j3'};
            stMap.Diag.PhaseSpace = {'x1','x2','x3','p1','p2','p3','l1','l2','l3','gl','g'};
            stMap.Diag.Deposit    = {'charge','m','ene','|charge|','q1','q2','q3','j1','j2','j3'};
            stMap.Diag.UDist      = {'ufl1','ufl2','ufl3','uth1','uth2','uth3'};

            % Alternative names used in input deck
            LocalConfig;
            stMap.Deck.Species = stInput;

            %
            % Translations
            %

            % Beam

            stMap.Translate.Beam(1).Name   = 'ElectronBeam';
            stMap.Translate.Beam(1).Alt    = horzcat({'eb','e-'},stMap.Deck.Species.ElectronBeam);
            stMap.Translate.Beam(1).Full   = {'Electron Beam','Electron Beam'};
            stMap.Translate.Beam(1).Short  = {'EB','EB'};
            stMap.Translate.Beam(1).Tex    = {'e-','e-'};
            stMap.Translate.Beam(1).Unit   = {'',''};
            stMap.Translate.Beam(1).Dim    = 0;

            stMap.Translate.Beam(2).Name   = 'PositronBeam';
            stMap.Translate.Beam(2).Alt    = horzcat({'e+b','e+'},stMap.Deck.Species.PositronBeam);
            stMap.Translate.Beam(2).Full   = {'Positron Beam','Positron Beam'};
            stMap.Translate.Beam(2).Short  = {'E+B','E+B'};
            stMap.Translate.Beam(2).Tex    = {'e+','e+'};
            stMap.Translate.Beam(2).Unit   = {'',''};
            stMap.Translate.Beam(2).Dim    = 0;

            stMap.Translate.Beam(3).Name   = 'ProtonBeam';
            stMap.Translate.Beam(3).Alt    = horzcat({'pb','p+'},stMap.Deck.Species.ProtonBeam);
            stMap.Translate.Beam(3).Full   = {'Proton Beam','Proton Beam'};
            stMap.Translate.Beam(3).Short  = {'PB','PB'};
            stMap.Translate.Beam(3).Tex    = {'p+','p+'};
            stMap.Translate.Beam(3).Unit   = {'',''};
            stMap.Translate.Beam(3).Dim    = 0;

            stMap.Translate.Beam(4).Name   = 'IonBeam';
            stMap.Translate.Beam(4).Alt    = horzcat({'ib','i+'},stMap.Deck.Species.IonBeam);
            stMap.Translate.Beam(4).Full   = {'Ion Beam','Ion Beam'};
            stMap.Translate.Beam(4).Short  = {'IB','IB'};
            stMap.Translate.Beam(4).Tex    = {'i+','i+'};
            stMap.Translate.Beam(4).Unit   = {'',''};
            stMap.Translate.Beam(4).Dim    = 0;

            % Plasma

            stMap.Translate.Plasma(1).Name   = 'PlasmaElectrons';
            stMap.Translate.Plasma(1).Alt    = horzcat({'pe','pe-'},stMap.Deck.Species.PlasmaElectrons);
            stMap.Translate.Plasma(1).Full   = {'Plasma Electron','Plasma Electron'};
            stMap.Translate.Plasma(1).Short  = {'PE','PE'};
            stMap.Translate.Plasma(1).Tex    = {'e-','e-'};
            stMap.Translate.Plasma(1).Unit   = {'',''};
            stMap.Translate.Plasma(1).Dim    = 0;

            stMap.Translate.Plasma(2).Name   = 'PlasmaProtons';
            stMap.Translate.Plasma(2).Alt    = horzcat({'pp','pp+'},stMap.Deck.Species.PlasmaProtons);
            stMap.Translate.Plasma(2).Full   = {'Plasma Proton','Plasma Proton'};
            stMap.Translate.Plasma(2).Short  = {'PP','PP'};
            stMap.Translate.Plasma(2).Tex    = {'p+','p+'};
            stMap.Translate.Plasma(2).Unit   = {'',''};
            stMap.Translate.Plasma(2).Dim    = 0;

            stMap.Translate.Plasma(3).Name   = 'PlasmaIons';
            stMap.Translate.Plasma(3).Alt    = horzcat({'pi','pi+','ion'},stMap.Deck.Species.PlasmaIons);
            stMap.Translate.Plasma(3).Full   = {'Plasma Ion','Plasma Ion'};
            stMap.Translate.Plasma(3).Short  = {'Ion','Ion'};
            stMap.Translate.Plasma(3).Tex    = {'i+','i+'};
            stMap.Translate.Plasma(3).Unit   = {'',''};
            stMap.Translate.Plasma(3).Dim    = 0;

            % Species

            stMap.Translate.Species = horzcat(stMap.Translate.Beam,stMap.Translate.Plasma);

            % Axis

            stMap.Translate.Axis(1).Name  = 'x1';
            stMap.Translate.Axis(1).Alt   = {'z'};
            stMap.Translate.Axis(1).Full  = {'Longitudinal Axis','Longitudinal Axis'};
            stMap.Translate.Axis(1).Short = {'z','z'};
            stMap.Translate.Axis(1).Tex   = {'z','z'};
            stMap.Translate.Axis(1).Unit  = {'m','m'};
            stMap.Translate.Axis(1).Dim   = 1;

            stMap.Translate.Axis(2).Name  = 'x2';
            stMap.Translate.Axis(2).Alt   = {'r','x'};
            stMap.Translate.Axis(2).Full  = {'Radial Axis','Horizontal Axis'};
            stMap.Translate.Axis(2).Short = {'r','x'};
            stMap.Translate.Axis(2).Tex   = {'r','x'};
            stMap.Translate.Axis(2).Unit  = {'m','m'};
            stMap.Translate.Axis(2).Dim   = 2;

            stMap.Translate.Axis(3).Name  = 'x3';
            stMap.Translate.Axis(3).Alt   = {'th','y'};
            stMap.Translate.Axis(3).Full  = {'Azimuthal Axis','Vertical Axis'};
            stMap.Translate.Axis(3).Short = {'th','y'};
            stMap.Translate.Axis(3).Tex   = {'\theta','y'};
            stMap.Translate.Axis(3).Unit  = {'rad','m'};
            stMap.Translate.Axis(3).Dim   = 3;

            stMap.Translate.Axis(4).Name  = 'xi';
            stMap.Translate.Axis(4).Alt   = {};
            stMap.Translate.Axis(4).Full  = {'Longitudinal Axis','Longitudinal Axis'};
            stMap.Translate.Axis(4).Short = {'xi','xi'};
            stMap.Translate.Axis(4).Tex   = {'\xi','\xi'};
            stMap.Translate.Axis(4).Unit  = {'m','m'};
            stMap.Translate.Axis(4).Dim   = 1;

            % Momentum

            stMap.Translate.Momentum(1).Name  = 'p1';
            stMap.Translate.Momentum(1).Alt   = {'pz','p_z'};
            stMap.Translate.Momentum(1).Full  = {'Longitudinal Momentum','Longitudinal Momentum'};
            stMap.Translate.Momentum(1).Short = {'Pz','Pz'};
            stMap.Translate.Momentum(1).Tex   = {'p_{z}','p_{z}'};
            stMap.Translate.Momentum(1).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Momentum(1).Dim   = 1;

            stMap.Translate.Momentum(2).Name  = 'p2';
            stMap.Translate.Momentum(2).Alt   = {'px','p_x','pr','p_r'};
            stMap.Translate.Momentum(2).Full  = {'Radial Momentum','Horizontal Momentum'};
            stMap.Translate.Momentum(2).Short = {'Pr','Px'};
            stMap.Translate.Momentum(2).Tex   = {'p_{r}','p_{x}'};
            stMap.Translate.Momentum(2).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Momentum(2).Dim   = 2;

            stMap.Translate.Momentum(3).Name  = 'p3';
            stMap.Translate.Momentum(3).Alt   = {'py','p_y','pth','p_th'};
            stMap.Translate.Momentum(3).Full  = {'Azimuthal Momentum','Vertical Momentum'};
            stMap.Translate.Momentum(3).Short = {'Pth','Py'};
            stMap.Translate.Momentum(3).Tex   = {'p_{\theta}','p_{y}'};
            stMap.Translate.Momentum(3).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Momentum(3).Dim   = 3;

            % Angular Momentum

            stMap.Translate.Angular(1).Name  = 'l1';
            stMap.Translate.Angular(1).Alt   = {'lz','l_z'};
            stMap.Translate.Angular(1).Full  = {'Longitudinal Angular Momentum','Longitudinal Angular Momentum'};
            stMap.Translate.Angular(1).Short = {'Lz','Lz'};
            stMap.Translate.Angular(1).Tex   = {'l_{z}','l_{z}'};
            stMap.Translate.Angular(1).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Angular(1).Dim   = 1;

            stMap.Translate.Angular(2).Name  = 'l2';
            stMap.Translate.Angular(2).Alt   = {'lx','l_x','lr','l_r'};
            stMap.Translate.Angular(2).Full  = {'Radial Angular Momentum','Horizontal Angular Momentum'};
            stMap.Translate.Angular(2).Short = {'Pr','Px'};
            stMap.Translate.Angular(2).Tex   = {'p_{r}','p_{x}'};
            stMap.Translate.Angular(2).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Angular(2).Dim   = 2;

            stMap.Translate.Angular(3).Name  = 'l3';
            stMap.Translate.Angular(3).Alt   = {'ly','l_y','lth','l_th'};
            stMap.Translate.Angular(3).Full  = {'Azimuthal Angular Momentum','Vertical Angular Momentum'};
            stMap.Translate.Angular(3).Short = {'Lth','Ly'};
            stMap.Translate.Angular(3).Tex   = {'l_{\theta}','l_{y}'};
            stMap.Translate.Angular(3).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Angular(3).Dim   = 3;

            % Current

            stMap.Translate.Current(1).Name  = 'j1';
            stMap.Translate.Current(1).Alt   = {'jz','j_z'};
            stMap.Translate.Current(1).Full  = {'Longitudinal Current','Longitudinal Current'};
            stMap.Translate.Current(1).Short = {'Jz','Jz'};
            stMap.Translate.Current(1).Tex   = {'j_{z}','j_{z}'};
            stMap.Translate.Current(1).Unit  = {'A/m^2','A/m^2'};
            stMap.Translate.Current(1).Dim   = 1;

            stMap.Translate.Current(2).Name  = 'j2';
            stMap.Translate.Current(2).Alt   = {'jx','j_x','jr','j_r'};
            stMap.Translate.Current(2).Full  = {'Radial Current','Horizontal Current'};
            stMap.Translate.Current(2).Short = {'Jr','Jx'};
            stMap.Translate.Current(2).Tex   = {'j_{r}','j_{x}'};
            stMap.Translate.Current(2).Unit  = {'A/m^2','A/m^2'};
            stMap.Translate.Current(2).Dim   = 2;

            stMap.Translate.Current(3).Name  = 'j3';
            stMap.Translate.Current(3).Alt   = {'jy','j_y','jth','j_th'};
            stMap.Translate.Current(3).Full  = {'Azimuthal Current','Vertical Current'};
            stMap.Translate.Current(3).Short = {'Jth','Jy'};
            stMap.Translate.Current(3).Tex   = {'j_{\theta}','j_{y}'};
            stMap.Translate.Current(3).Unit  = {'A/m^2','A/m^2'};
            stMap.Translate.Current(3).Dim   = 3;

            % Electric Field

            stMap.Translate.EField(1).Name  = 'e1';
            stMap.Translate.EField(1).Alt   = {'ez','e_z'};
            stMap.Translate.EField(1).Full  = {'Longitudinal E-Field','Longitudinal E-Field'};
            stMap.Translate.EField(1).Short = {'Ez','Ez'};
            stMap.Translate.EField(1).Tex   = {'E_{z}','E_{z}'};
            stMap.Translate.EField(1).Unit  = {'V/m','V/m'};
            stMap.Translate.EField(1).Dim   = 1;

            stMap.Translate.EField(2).Name  = 'e2';
            stMap.Translate.EField(2).Alt   = {'ex','e_x','er','e_r'};
            stMap.Translate.EField(2).Full  = {'Radial E-Field','Horizontal E-Field'};
            stMap.Translate.EField(2).Short = {'Er','Ex'};
            stMap.Translate.EField(2).Tex   = {'E_{r}','E_{x}'};
            stMap.Translate.EField(2).Unit  = {'V/m','V/m'};
            stMap.Translate.EField(2).Dim   = 2;

            stMap.Translate.EField(3).Name  = 'e3';
            stMap.Translate.EField(3).Alt   = {'ey','e_y','eth','e_th'};
            stMap.Translate.EField(3).Full  = {'Azimuthal E-Field','Vertical E-Field'};
            stMap.Translate.EField(3).Short = {'Eth','Ey'};
            stMap.Translate.EField(3).Tex   = {'E_{\theta}','E_{y}'};
            stMap.Translate.EField(3).Unit  = {'V/m','V/m'};
            stMap.Translate.EField(3).Dim   = 3;

            stMap.Translate.EField(4).Name  = 'e';
            stMap.Translate.EField(4).Alt   = {};
            stMap.Translate.EField(4).Full  = {'Electric Field','Electric Field'};
            stMap.Translate.EField(4).Short = {'|E|','|E|'};
            stMap.Translate.EField(4).Tex   = {'|E|','|E|'};
            stMap.Translate.EField(4).Unit  = {'V/m','V/m'};
            stMap.Translate.EField(4).Dim   = 0;

            % Magnetic Field

            stMap.Translate.BField(1).Name  = 'b1';
            stMap.Translate.BField(1).Alt   = {'bz','b_z'};
            stMap.Translate.BField(1).Full  = {'Longitudinal B-Field','Longitudinal B-Field'};
            stMap.Translate.BField(1).Short = {'Bz','Bz'};
            stMap.Translate.BField(1).Tex   = {'B_{z}','B_{z}'};
            stMap.Translate.BField(1).Unit  = {'T','T'};
            stMap.Translate.BField(1).Dim   = 1;

            stMap.Translate.BField(2).Name  = 'b2';
            stMap.Translate.BField(2).Alt   = {'bx','b_x','br','b_r'};
            stMap.Translate.BField(2).Full  = {'Radial B-Field','Horizontal B-Field'};
            stMap.Translate.BField(2).Short = {'Br','Bx'};
            stMap.Translate.BField(2).Tex   = {'B_{r}','B_{x}'};
            stMap.Translate.BField(2).Unit  = {'T','T'};
            stMap.Translate.BField(2).Dim   = 2;

            stMap.Translate.BField(3).Name  = 'b3';
            stMap.Translate.BField(3).Alt   = {'by','b_y','bth','b_th'};
            stMap.Translate.BField(3).Full  = {'Azimuthal B-Field','Vertical B-Field'};
            stMap.Translate.BField(3).Short = {'Bth','By'};
            stMap.Translate.BField(3).Tex   = {'B_{\theta}','B_{y}'};
            stMap.Translate.BField(3).Unit  = {'T','T'};
            stMap.Translate.BField(3).Dim   = 3;

            stMap.Translate.BField(4).Name  = 'b';
            stMap.Translate.BField(4).Alt   = {};
            stMap.Translate.BField(4).Full  = {'Magnetic Field','Magnetic Field'};
            stMap.Translate.BField(4).Short = {'|B|','|B|'};
            stMap.Translate.BField(4).Tex   = {'|B|','|B|'};
            stMap.Translate.BField(4).Unit  = {'T','T'};
            stMap.Translate.BField(4).Dim   = 0;

            % External Electric Field

            stMap.Translate.EFieldExt(1).Name  = 'ext_e1';
            stMap.Translate.EFieldExt(1).Alt   = {'ext_ez','ext_e_z'};
            stMap.Translate.EFieldExt(1).Full  = {'External Longitudinal E-Field','External Longitudinal E-Field'};
            stMap.Translate.EFieldExt(1).Short = {'Ext. Ez','Ext. Ez'};
            stMap.Translate.EFieldExt(1).Tex   = {'E_{z}^{ext}','E_{z}^{ext}'};
            stMap.Translate.EFieldExt(1).Unit  = {'V/m','V/m'};
            stMap.Translate.EFieldExt(1).Dim   = 1;

            stMap.Translate.EFieldExt(2).Name  = 'ext_e2';
            stMap.Translate.EFieldExt(2).Alt   = {'ext_ex','ext_e_x','ext_er','ext_e_r'};
            stMap.Translate.EFieldExt(2).Full  = {'External Radial E-Field','External Horizontal E-Field'};
            stMap.Translate.EFieldExt(2).Short = {'Ext. Er','Ext. Ex'};
            stMap.Translate.EFieldExt(2).Tex   = {'E_{r}^{ext}','E_{x}^{ext}'};
            stMap.Translate.EFieldExt(2).Unit  = {'V/m','V/m'};
            stMap.Translate.EFieldExt(2).Dim   = 2;

            stMap.Translate.EFieldExt(3).Name  = 'ext_e3';
            stMap.Translate.EFieldExt(3).Alt   = {'ext_ey','ext_e_y','ext_eth','ext_e_th'};
            stMap.Translate.EFieldExt(3).Full  = {'External Azimuthal E-Field','External Vertical E-Field'};
            stMap.Translate.EFieldExt(3).Short = {'Ext. Eth','Ext. Ey'};
            stMap.Translate.EFieldExt(3).Tex   = {'E_{\theta}^{ext}','E_{y}^{ext}'};
            stMap.Translate.EFieldExt(3).Unit  = {'V/m','V/m'};
            stMap.Translate.EFieldExt(3).Dim   = 3;

            % External Magnetic Field

            stMap.Translate.BFieldExt(1).Name  = 'ext_b1';
            stMap.Translate.BFieldExt(1).Alt   = {'ext_bz','ext_b_z'};
            stMap.Translate.BFieldExt(1).Full  = {'External Longitudinal B-Field','External Longitudinal B-Field'};
            stMap.Translate.BFieldExt(1).Short = {'Ext. Bz','Ext. Bz'};
            stMap.Translate.BFieldExt(1).Tex   = {'B_{z}^{ext}','B_{z}^{ext}'};
            stMap.Translate.BFieldExt(1).Unit  = {'T','T'};
            stMap.Translate.BFieldExt(1).Dim   = 1;

            stMap.Translate.BFieldExt(2).Name  = 'ext_b2';
            stMap.Translate.BFieldExt(2).Alt   = {'ext_bx','ext_b_x','ext_br','ext_b_r'};
            stMap.Translate.BFieldExt(2).Full  = {'External Radial B-Field','External Horizontal B-Field'};
            stMap.Translate.BFieldExt(2).Short = {'Ext. Br','Ext. Bx'};
            stMap.Translate.BFieldExt(2).Tex   = {'B_{r}^{ext}','B_{x}^{ext}'};
            stMap.Translate.BFieldExt(2).Unit  = {'T','T'};
            stMap.Translate.BFieldExt(2).Dim   = 2;

            stMap.Translate.BFieldExt(3).Name  = 'ext_b3';
            stMap.Translate.BFieldExt(3).Alt   = {'ext_by','ext_b_y','ext_bth','ext_b_th'};
            stMap.Translate.BFieldExt(3).Full  = {'External Azimuthal B-Field','External Vertical B-Field'};
            stMap.Translate.BFieldExt(3).Short = {'Ext. Bth','Ext. By'};
            stMap.Translate.BFieldExt(3).Tex   = {'B_{\theta}^{ext}','B_{y}^{ext}'};
            stMap.Translate.BFieldExt(3).Unit  = {'T','T'};
            stMap.Translate.BFieldExt(3).Dim   = 3;

            % Particle Electric Field

            stMap.Translate.EFieldPart(1).Name  = 'part_e1';
            stMap.Translate.EFieldPart(1).Alt   = {'part_ez','part_e_z'};
            stMap.Translate.EFieldPart(1).Full  = {'Particle Longitudinal E-Field','Particle Longitudinal E-Field'};
            stMap.Translate.EFieldPart(1).Short = {'Part. Ez','Part. Ez'};
            stMap.Translate.EFieldPart(1).Tex   = {'E_{z}^{part}','E_{z}^{part}'};
            stMap.Translate.EFieldPart(1).Unit  = {'V/m','V/m'};
            stMap.Translate.EFieldPart(1).Dim   = 1;

            stMap.Translate.EFieldPart(2).Name  = 'part_e2';
            stMap.Translate.EFieldPart(2).Alt   = {'part_ex','part_e_x','part_er','part_e_r'};
            stMap.Translate.EFieldPart(2).Full  = {'Particle Radial E-Field','Particle Horizontal E-Field'};
            stMap.Translate.EFieldPart(2).Short = {'Part. Er','Part. Ex'};
            stMap.Translate.EFieldPart(2).Tex   = {'E_{r}^{part}','E_{x}^{part}'};
            stMap.Translate.EFieldPart(2).Unit  = {'V/m','V/m'};
            stMap.Translate.EFieldPart(2).Dim   = 2;

            stMap.Translate.EFieldPart(3).Name  = 'part_e3';
            stMap.Translate.EFieldPart(3).Alt   = {'part_ey','part_e_y','part_eth','part_e_th'};
            stMap.Translate.EFieldPart(3).Full  = {'Particle Azimuthal E-Field','Particle Vertical E-Field'};
            stMap.Translate.EFieldPart(3).Short = {'Part. Eth','Part. Ey'};
            stMap.Translate.EFieldPart(3).Tex   = {'E_{\theta}^{part}','E_{y}^{part}'};
            stMap.Translate.EFieldPart(3).Unit  = {'V/m','V/m'};
            stMap.Translate.EFieldPart(3).Dim   = 3;

            % Particle Magnetic Field

            stMap.Translate.BFieldPart(1).Name  = 'part_b1';
            stMap.Translate.BFieldPart(1).Alt   = {'part_bz','part_b_z'};
            stMap.Translate.BFieldPart(1).Full  = {'Particle Longitudinal B-Field','Particle Longitudinal B-Field'};
            stMap.Translate.BFieldPart(1).Short = {'Part. Bz','Part. Bz'};
            stMap.Translate.BFieldPart(1).Tex   = {'B_{z}^{part}','B_{z}^{part}'};
            stMap.Translate.BFieldPart(1).Unit  = {'T','T'};
            stMap.Translate.BFieldPart(1).Dim   = 1;

            stMap.Translate.BFieldPart(2).Name  = 'part_b2';
            stMap.Translate.BFieldPart(2).Alt   = {'part_bx','part_b_x','part_br','part_b_r'};
            stMap.Translate.BFieldPart(2).Full  = {'Particle Radial B-Field','Particle Horizontal B-Field'};
            stMap.Translate.BFieldPart(2).Short = {'Part. Br','Part. Bx'};
            stMap.Translate.BFieldPart(2).Tex   = {'B_{r}^{part}','B_{x}^{part}'};
            stMap.Translate.BFieldPart(2).Unit  = {'T','T'};
            stMap.Translate.BFieldPart(2).Dim   = 2;

            stMap.Translate.BFieldPart(3).Name  = 'part_b3';
            stMap.Translate.BFieldPart(3).Alt   = {'part_by','part_b_y','part_bth','part_b_th'};
            stMap.Translate.BFieldPart(3).Full  = {'Particle Azimuthal B-Field','Particle Vertical B-Field'};
            stMap.Translate.BFieldPart(3).Short = {'Part. Bth','Part. By'};
            stMap.Translate.BFieldPart(3).Tex   = {'B_{\theta}^{part}','B_{y}^{part}'};
            stMap.Translate.BFieldPart(3).Unit  = {'T','T'};
            stMap.Translate.BFieldPart(3).Dim   = 3;

            % Electric Field Energy

            stMap.Translate.EFieldEnergy(1).Name  = 'ene_e1';
            stMap.Translate.EFieldEnergy(1).Alt   = {'ene_ez','ene_e_z'};
            stMap.Translate.EFieldEnergy(1).Full  = {'Energy in Longitudinal E-Field','Energy in Longitudinal E-Field'};
            stMap.Translate.EFieldEnergy(1).Short = {'E²z','E²z'};
            stMap.Translate.EFieldEnergy(1).Tex   = {'E_{z}^{2}','E_{z}^{2}'};
            stMap.Translate.EFieldEnergy(1).Unit  = {'eV','eV'};
            stMap.Translate.EFieldEnergy(1).Dim   = 1;

            stMap.Translate.EFieldEnergy(2).Name  = 'ene_e2';
            stMap.Translate.EFieldEnergy(2).Alt   = {'ene_ex','ene_e_x','ene_er','ene_e_r'};
            stMap.Translate.EFieldEnergy(2).Full  = {'Energy in Radial E-Field','Energy in Horizontal E-Field'};
            stMap.Translate.EFieldEnergy(2).Short = {'E²r','E²x'};
            stMap.Translate.EFieldEnergy(2).Tex   = {'E_{r}^{2}','E_{x}^{2}'};
            stMap.Translate.EFieldEnergy(2).Unit  = {'eV','eV'};
            stMap.Translate.EFieldEnergy(2).Dim   = 2;

            stMap.Translate.EFieldEnergy(3).Name  = 'ene_e3';
            stMap.Translate.EFieldEnergy(3).Alt   = {'ene_ey','ene_e_y','ene_eth','ene_e_th'};
            stMap.Translate.EFieldEnergy(3).Full  = {'Energy in Azimuthal E-Field','Energy in Vertical E-Field'};
            stMap.Translate.EFieldEnergy(3).Short = {'E²th','E²y'};
            stMap.Translate.EFieldEnergy(3).Tex   = {'E_{\theta}^{2}','E_{y}^{2}'};
            stMap.Translate.EFieldEnergy(3).Unit  = {'eV','eV'};
            stMap.Translate.EFieldEnergy(3).Dim   = 3;

            stMap.Translate.EFieldEnergy(4).Name  = 'ene_e';
            stMap.Translate.EFieldEnergy(4).Alt   = {};
            stMap.Translate.EFieldEnergy(4).Full  = {'Energy in Electric Field','Energy in Electric Field'};
            stMap.Translate.EFieldEnergy(4).Short = {'E²','E²'};
            stMap.Translate.EFieldEnergy(4).Tex   = {'\sum E_{i}^{2}','\sum E_{i}^{2}'};
            stMap.Translate.EFieldEnergy(4).Unit  = {'eV','eV'};
            stMap.Translate.EFieldEnergy(4).Dim   = 0;

            % Magnetic Field Energy

            stMap.Translate.BFieldEnergy(1).Name  = 'ene_b1';
            stMap.Translate.BFieldEnergy(1).Alt   = {'ene_bz','ene_b_z'};
            stMap.Translate.BFieldEnergy(1).Full  = {'Energy in Longitudinal B-Field','Energy in Longitudinal B-Field'};
            stMap.Translate.BFieldEnergy(1).Short = {'B²z','B²z'};
            stMap.Translate.BFieldEnergy(1).Tex   = {'B_{z}^{2}','B_{z}^{2}'};
            stMap.Translate.BFieldEnergy(1).Unit  = {'eV','eV'};
            stMap.Translate.BFieldEnergy(1).Dim   = 1;

            stMap.Translate.BFieldEnergy(2).Name  = 'ene_b2';
            stMap.Translate.BFieldEnergy(2).Alt   = {'ene_bx','ene_b_x','ene_br','ene_b_r'};
            stMap.Translate.BFieldEnergy(2).Full  = {'Energy in Radial B-Field','Energy in Horizontal B-Field'};
            stMap.Translate.BFieldEnergy(2).Short = {'B²r','B²x'};
            stMap.Translate.BFieldEnergy(2).Tex   = {'B_{r}^{2}','B_{x}^{2}'};
            stMap.Translate.BFieldEnergy(2).Unit  = {'eV','eV'};
            stMap.Translate.BFieldEnergy(2).Dim   = 2;

            stMap.Translate.BFieldEnergy(3).Name  = 'ene_b3';
            stMap.Translate.BFieldEnergy(3).Alt   = {'ene_by','ene_b_y','ene_bth','ene_b_th'};
            stMap.Translate.BFieldEnergy(3).Full  = {'Energy in Azimuthal B-Field','Energy in Vertical B-Field'};
            stMap.Translate.BFieldEnergy(3).Short = {'B²th','B²y'};
            stMap.Translate.BFieldEnergy(3).Tex   = {'B_{\theta}^{2}','B_{y}^{2}'};
            stMap.Translate.BFieldEnergy(3).Unit  = {'eV','eV'};
            stMap.Translate.BFieldEnergy(3).Dim   = 3;

            stMap.Translate.BFieldEnergy(4).Name  = 'ene_b';
            stMap.Translate.BFieldEnergy(4).Alt   = {};
            stMap.Translate.BFieldEnergy(4).Full  = {'Energy in Magnetic Field','Energy in Magnetic Field'};
            stMap.Translate.BFieldEnergy(4).Short = {'B²','B²'};
            stMap.Translate.BFieldEnergy(4).Tex   = {'\sum B_{i}^{2}','\sum B_{i}^{2}'};
            stMap.Translate.BFieldEnergy(4).Unit  = {'eV','eV'};
            stMap.Translate.BFieldEnergy(4).Dim   = 0;

            % EM Field Energy

            stMap.Translate.Field                = horzcat(stMap.Translate.EField,stMap.Translate.BField);
            stMap.Translate.FieldEnergy          = horzcat(stMap.Translate.EFieldEnergy,stMap.Translate.BFieldEnergy);

            stMap.Translate.FieldEnergy(9).Name  = 'ene_emf';
            stMap.Translate.FieldEnergy(9).Alt   = {'ene_em'};
            stMap.Translate.FieldEnergy(9).Full  = {'Energy in Electromagnetic Field','Energy in Electromagnetic Field'};
            stMap.Translate.FieldEnergy(9).Short = {'E²+B²','E²+B²'};
            stMap.Translate.FieldEnergy(9).Tex   = {'E^{2}+B^{2}','E^{2}+B^{2}'};
            stMap.Translate.FieldEnergy(9).Unit  = {'eV','eV'};
            stMap.Translate.FieldEnergy(9).Dim   = 0;

            % Field Divergence

            stMap.Translate.FieldDiv(1).Name  = 'div_e';
            stMap.Translate.FieldDiv(1).Alt   = {};
            stMap.Translate.FieldDiv(1).Full  = {'E-Field Divergence','E-Field Divergence'};
            stMap.Translate.FieldDiv(1).Short = {'Div. E²','Div. E'};
            stMap.Translate.FieldDiv(1).Tex   = {'\Nabla \cdot E','\Nabla \cdot E'};
            stMap.Translate.FieldDiv(1).Unit  = {'V/m','V/m'};
            stMap.Translate.FieldDiv(1).Dim   = 0;

            stMap.Translate.FieldDiv(2).Name  = 'div_b';
            stMap.Translate.FieldDiv(2).Alt   = {};
            stMap.Translate.FieldDiv(2).Full  = {'B-Field Divergence','B-Field Divergence'};
            stMap.Translate.FieldDiv(2).Short = {'Div. B²','Div. B'};
            stMap.Translate.FieldDiv(2).Tex   = {'\Nabla \cdot B','\Nabla \cdot B'};
            stMap.Translate.FieldDiv(2).Unit  = {'T','T'};
            stMap.Translate.FieldDiv(2).Dim   = 0;

            % Quantity

            stMap.Translate.Quantity(1).Name  = 'charge';
            stMap.Translate.Quantity(1).Alt   = {'q'};
            stMap.Translate.Quantity(1).Full  = {'Charge','Charge'};
            stMap.Translate.Quantity(1).Short = {'Q','Q'};
            stMap.Translate.Quantity(1).Tex   = {'q','q'};
            stMap.Translate.Quantity(1).Unit  = {'C','C'};
            stMap.Translate.Quantity(1).Dim   = 0;

            stMap.Translate.Quantity(2).Name  = '|charge|';
            stMap.Translate.Quantity(2).Alt   = {'|q|'};
            stMap.Translate.Quantity(2).Full  = {'Absolute Charge','Absolute Charge'};
            stMap.Translate.Quantity(2).Short = {'|Q|','|Q|'};
            stMap.Translate.Quantity(2).Tex   = {'|q|','|q|'};
            stMap.Translate.Quantity(2).Unit  = {'C','C'};
            stMap.Translate.Quantity(2).Dim   = 0;

            stMap.Translate.Quantity(3).Name  = 'chargecons';
            stMap.Translate.Quantity(3).Alt   = {'qcons'};
            stMap.Translate.Quantity(3).Full  = {'Charge Conservation','Charge Conservation'};
            stMap.Translate.Quantity(3).Short = {'QCons','QCons'};
            stMap.Translate.Quantity(3).Tex   = {'\nabla\cdot E - \rho','\nabla\cdot E - \rho'};
            stMap.Translate.Quantity(3).Unit  = {'V/m','V/m'};
            stMap.Translate.Quantity(3).Dim   = 0;

            stMap.Translate.Quantity(4).Name  = 'm';
            stMap.Translate.Quantity(4).Alt   = {'mass'};
            stMap.Translate.Quantity(4).Full  = {'Mass','Mass'};
            stMap.Translate.Quantity(4).Short = {'Mass','Mass'};
            stMap.Translate.Quantity(4).Tex   = {'m','m'};
            stMap.Translate.Quantity(4).Unit  = {'eV/m^2','eV/m^2'};
            stMap.Translate.Quantity(4).Dim   = 0;

            stMap.Translate.Quantity(5).Name  = 'ene';
            stMap.Translate.Quantity(5).Alt   = {'energy','e_k'};
            stMap.Translate.Quantity(5).Full  = {'Kinetic Energy','Kinetic Energy'};
            stMap.Translate.Quantity(5).Short = {'Ek','Ek'};
            stMap.Translate.Quantity(5).Tex   = {'E_{k}','E_{k}'};
            stMap.Translate.Quantity(5).Unit  = {'eV','eV'};
            stMap.Translate.Quantity(5).Dim   = 0;

            stMap.Translate.Quantity(6).Name  = 'g';
            stMap.Translate.Quantity(6).Alt   = {'gamma'};
            stMap.Translate.Quantity(6).Full  = {'Lorentz Factor','Lorentz Factor'};
            stMap.Translate.Quantity(6).Short = {'Gamma','Gamma'};
            stMap.Translate.Quantity(6).Tex   = {'\gamma','\gamma'};
            stMap.Translate.Quantity(6).Unit  = {'',''};
            stMap.Translate.Quantity(6).Dim   = 0;

            stMap.Translate.Quantity(7).Name  = 'gl';
            stMap.Translate.Quantity(7).Alt   = {'log_gamma'};
            stMap.Translate.Quantity(7).Full  = {'Lorentz Factor','Lorentz Factor'};
            stMap.Translate.Quantity(7).Short = {'Log(Gamma)','Log(Gamma)'};
            stMap.Translate.Quantity(7).Tex   = {'\log(\gamma)','\log(\gamma)'};
            stMap.Translate.Quantity(7).Unit  = {'',''};
            stMap.Translate.Quantity(7).Dim   = 0;

            stMap.Translate.Quantity(8).Name  = 'psi';
            stMap.Translate.Quantity(8).Alt   = {};
            stMap.Translate.Quantity(8).Full  = {'Pseudopotential','Pseudopotential'};
            stMap.Translate.Quantity(8).Short = {'Psi','Psi'};
            stMap.Translate.Quantity(8).Tex   = {'\Psi','\Psi'};
            stMap.Translate.Quantity(8).Unit  = {'a.u.','a.u.'};
            stMap.Translate.Quantity(8).Dim   = 0;

            stMap.Translate.Quantity(9).Name  = 't';
            stMap.Translate.Quantity(9).Alt   = {};
            stMap.Translate.Quantity(9).Full  = {'Time','Time'};
            stMap.Translate.Quantity(9).Short = {'Time','Time'};
            stMap.Translate.Quantity(9).Tex   = {'t','t'};
            stMap.Translate.Quantity(9).Unit  = {'\omega^{-1}','\omega^{-1}'};
            stMap.Translate.Quantity(9).Dim   = 4;

            % Heat Flux

            stMap.Translate.Flux(1).Name  = 'q1';
            stMap.Translate.Flux(1).Alt   = {'qz','q_z'};
            stMap.Translate.Flux(1).Full  = {'Longitudinal Flux','Longitudinal Flux'};
            stMap.Translate.Flux(1).Short = {'Qz','Qz'};
            stMap.Translate.Flux(1).Tex   = {'q_{z}','q_{z}'};
            stMap.Translate.Flux(1).Unit  = {'W/m^2','W/m^2'};
            stMap.Translate.Flux(1).Dim   = 1;

            stMap.Translate.Flux(2).Name  = 'q2';
            stMap.Translate.Flux(2).Alt   = {'qr','q_r','qx','q_x'};
            stMap.Translate.Flux(2).Full  = {'Radial Flux','Horizontal Flux'};
            stMap.Translate.Flux(2).Short = {'Qr','Qx'};
            stMap.Translate.Flux(2).Tex   = {'q_{r}','q_{x}'};
            stMap.Translate.Flux(2).Unit  = {'W/m^2','W/m^2'};
            stMap.Translate.Flux(2).Dim   = 2;

            stMap.Translate.Flux(3).Name  = 'q3';
            stMap.Translate.Flux(3).Alt   = {'qth','q_th','qy','q_y'};
            stMap.Translate.Flux(3).Full  = {'Azimuthal Flux','Vertical Flux'};
            stMap.Translate.Flux(3).Short = {'Qth','Qy'};
            stMap.Translate.Flux(3).Tex   = {'q_{\theta}','q_{y}'};
            stMap.Translate.Flux(3).Unit  = {'W/m^2','W/m^2'};
            stMap.Translate.Flux(3).Dim   = 3;

            % Poynting Flux

            stMap.Translate.Poynting(1).Name  = 's1';
            stMap.Translate.Poynting(1).Alt   = {'sz','s_z'};
            stMap.Translate.Poynting(1).Full  = {'Longitudinal Poynting Flux','Longitudinal Poynting Flux'};
            stMap.Translate.Poynting(1).Short = {'Sz','Sz'};
            stMap.Translate.Poynting(1).Tex   = {'s_{z}','s_{z}'};
            stMap.Translate.Poynting(1).Unit  = {'W/m^2','W/m^2'};
            stMap.Translate.Poynting(1).Dim   = 1;

            stMap.Translate.Poynting(2).Name  = 's2';
            stMap.Translate.Poynting(2).Alt   = {'sr','s_r','sx','s_x'};
            stMap.Translate.Poynting(2).Full  = {'Radial Poynting Flux','Horizontal Poynting Flux'};
            stMap.Translate.Poynting(2).Short = {'Sr','Sx'};
            stMap.Translate.Poynting(2).Tex   = {'s_{r}','s_{x}'};
            stMap.Translate.Poynting(2).Unit  = {'W/m^2','W/m^2'};
            stMap.Translate.Poynting(2).Dim   = 2;

            stMap.Translate.Poynting(3).Name  = 's3';
            stMap.Translate.Poynting(3).Alt   = {'sth','s_th','sy','s_y'};
            stMap.Translate.Poynting(3).Full  = {'Azimuthal Poynting Flux','Vertical Poynting Flux'};
            stMap.Translate.Poynting(3).Short = {'Sth','Sy'};
            stMap.Translate.Poynting(3).Tex   = {'s_{\theta}','s_{y}'};
            stMap.Translate.Poynting(3).Unit  = {'W/m^2','W/m^2'};
            stMap.Translate.Poynting(3).Dim   = 3;

            % Fluid Momentum

            stMap.Translate.Ufl(1).Name  = 'ufl1';
            stMap.Translate.Ufl(1).Alt   = {'uflz'};
            stMap.Translate.Ufl(1).Full  = {'Longitudinal Fluid Momentum','Longitudinal Fluid Momentum'};
            stMap.Translate.Ufl(1).Short = {'Uz','Uz'};
            stMap.Translate.Ufl(1).Tex   = {'u_{z}','u_{z}'};
            stMap.Translate.Ufl(1).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Ufl(1).Dim   = 1;

            stMap.Translate.Ufl(2).Name  = 'ufl2';
            stMap.Translate.Ufl(2).Alt   = {'uflr','uflx'};
            stMap.Translate.Ufl(2).Full  = {'Radial Fluid Momentum','Horizontal Fluid Momentum'};
            stMap.Translate.Ufl(2).Short = {'Ur','Ux'};
            stMap.Translate.Ufl(2).Tex   = {'u_{r}','u_{x}'};
            stMap.Translate.Ufl(2).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Ufl(2).Dim   = 2;

            stMap.Translate.Ufl(3).Name  = 'ufl3';
            stMap.Translate.Ufl(3).Alt   = {'uflth','ufly'};
            stMap.Translate.Ufl(3).Full  = {'Azimuthal Fluid Momentum','Vertical Fluid Momentum'};
            stMap.Translate.Ufl(3).Short = {'Uth','Uy'};
            stMap.Translate.Ufl(3).Tex   = {'u_{\theta}','u_{y}'};
            stMap.Translate.Ufl(3).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Ufl(3).Dim   = 3;

            % Momentum Distribution

            stMap.Translate.Uth(1).Name  = 'uth1';
            stMap.Translate.Uth(1).Alt   = {'uthz'};
            stMap.Translate.Uth(1).Full  = {'Longitudinal Momentum Distribution','Longitudinal Momentum Distribution'};
            stMap.Translate.Uth(1).Short = {'Tz','Tz'};
            stMap.Translate.Uth(1).Tex   = {'T_{z}','T_{z}'};
            stMap.Translate.Uth(1).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Uth(1).Dim   = 1;

            stMap.Translate.Uth(2).Name  = 'uth2';
            stMap.Translate.Uth(2).Alt   = {'uthr','uthx'};
            stMap.Translate.Uth(2).Full  = {'Radial Momentum Distribution','Horizontal Momentum Distribution'};
            stMap.Translate.Uth(2).Short = {'Tr','Tx'};
            stMap.Translate.Uth(2).Tex   = {'T_{r}','T_{x}'};
            stMap.Translate.Uth(2).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Uth(2).Dim   = 2;

            stMap.Translate.Uth(3).Name  = 'uth3';
            stMap.Translate.Uth(3).Alt   = {'uthth','uthy'};
            stMap.Translate.Uth(3).Full  = {'Azimuthal Momentum Distribution','Vertical Momentum Distribution'};
            stMap.Translate.Uth(3).Short = {'Tth','Ty'};
            stMap.Translate.Uth(3).Tex   = {'T_{\theta}','T_{y}'};
            stMap.Translate.Uth(3).Unit  = {'eV/c','eV/c'};
            stMap.Translate.Uth(3).Dim   = 3;

            % Wakefield

            stMap.Translate.Wakefield(1).Name  = 'w1';
            stMap.Translate.Wakefield(1).Alt   = {'wz','w_z'};
            stMap.Translate.Wakefield(1).Full  = {'Longitudinal Wakefield','Longitudinal Wakefield'};
            stMap.Translate.Wakefield(1).Short = {'Wz','Wz'};
            stMap.Translate.Wakefield(1).Tex   = {'W_{z}','W_{z}'};
            stMap.Translate.Wakefield(1).Unit  = {'V/m','V/m'};
            stMap.Translate.Wakefield(1).Dim   = 1;

            stMap.Translate.Wakefield(2).Name  = 'w2';
            stMap.Translate.Wakefield(2).Alt   = {'wx','w_x','wr','w_r'};
            stMap.Translate.Wakefield(2).Full  = {'Radial Wakefield','Horizontal Wakefield'};
            stMap.Translate.Wakefield(2).Short = {'Wr','Wx'};
            stMap.Translate.Wakefield(2).Tex   = {'W_{r}','W_{x}'};
            stMap.Translate.Wakefield(2).Unit  = {'V/m','V/m'};
            stMap.Translate.Wakefield(2).Dim   = 2;

            stMap.Translate.Wakefield(3).Name  = 'w3';
            stMap.Translate.Wakefield(3).Alt   = {'wy','w_y','wth','w_th'};
            stMap.Translate.Wakefield(3).Full  = {'Azimuthal Wakefield','Vertical Wakefield'};
            stMap.Translate.Wakefield(3).Short = {'Wth','Wy'};
            stMap.Translate.Wakefield(3).Tex   = {'W_{\theta}','W_{y}'};
            stMap.Translate.Wakefield(3).Unit  = {'V/m','V/m'};
            stMap.Translate.Wakefield(3).Dim   = 3;
            
            % Save map
            obj.Map = stMap;

        end % function

    end % methods

    %
    % Public Methods
    %

    methods(Access='public')
        
        function stReturn = Lookup(obj, sVar, vType)
            
            %
            %  Variables :: Lookup
            % *********************
            %  Lookup a variable and extract its type, full name, units, etc.
            %
            %  Input
            % =======
            %  sVar  :: Variable name. Required.
            %  vType :: String or cell array of types to scan.
            %           Default: Scans all types.
            %
            
            sNum = '';
            if ~isempty(sVar)
                if isstrprop(sVar(end),'digit')
                    sTemp = lower(sVar(1:end-1));
                    for i=1:size(obj.Map.Translate.Species,2)
                        stItem = obj.Map.Translate.Species(i);
                        if strcmpi(stItem.Name,sTemp) || sum(ismember(stItem.Alt,sTemp)) ~= 0
                            sNum = sVar(end);
                            sVar = stItem.Name;
                            break;
                        end % if
                    end % for
                end % if
            end % if
            
            % Return
            stReturn.Original = sVar;
            stReturn.Name     = sVar;
            stReturn.Full     = '';
            stReturn.Short    = '';
            stReturn.Tex      = '';
            stReturn.Unit     = '';
            stReturn.Dim      = 0;
            stReturn.Type     = '';

            %
            % Input
            %
            
            % Variable
            sVar = lower(sVar);
            
            if obj.Running
                sVar = strrep(sVar,'x1','xi');
            end % if

            % Search
            if nargin < 3
                vType = '';
            end % if

            stSearch = {};
            if ~isempty(vType)
                if iscell(vType)
                    stSearch = vType;
                else
                    stSearch = {vType};
                end % if
            end % if
            
            stTemp = stSearch;
            for t=1:length(stSearch)
                sType = stSearch{t};
                sType = [upper(sType(1)) lower(sType(2:end))];
                if sum(ismember(obj.Types, sType)) == 0
                    stTemp{t} = [];
                    fprintf(2,'Error: Unknown variable type "%s".\n',stSearch{t});
                end % if
            end % for
            stSearch = stTemp;

            if isempty(stSearch)
                stSearch = obj.Types;
            end % if
            
            %
            % Lookup
            %

            bFound = 0;
            for s=1:length(stSearch)
                sType = stSearch{s};
                for i=1:size(obj.Map.Translate.(sType),2)
                    stItem = obj.Map.Translate.(sType)(i);
                    if strcmpi(stItem.Name,sVar) || sum(ismember(stItem.Alt,sVar)) ~= 0
                        stReturn.Name  = stItem.Name;
                        stReturn.Full  = stItem.Full{obj.Coords};
                        stReturn.Short = stItem.Short{obj.Coords};
                        stReturn.Tex   = stItem.Tex{obj.Coords};
                        stReturn.Unit  = stItem.Unit{obj.Coords};
                        stReturn.Dim   = stItem.Dim;
                        stReturn.Type  = sType;
                        bFound         = 1;
                        break;
                    end % if
                end % for
                if bFound
                    break;
                end % if
            end % for
            
            % Check
            
            % Osiris
            stReturn.isBeam                = (sum(ismember(obj.Map.Allowed.Beam,stReturn.Name)) == 1);
            stReturn.isPlasma              = (sum(ismember(obj.Map.Allowed.Plasma,stReturn.Name)) == 1);
            stReturn.isSpecies             = (sum(ismember(obj.Map.Allowed.Species,stReturn.Name)) == 1);
            stReturn.isAxis                = (sum(ismember(obj.Map.Allowed.Axis,stReturn.Name)) == 1);
            stReturn.isMomentum            = (sum(ismember(obj.Map.Allowed.Momentum,stReturn.Name)) == 1);
            stReturn.isAngular             = (sum(ismember(obj.Map.Allowed.Angular,stReturn.Name)) == 1);
            stReturn.isCurrent             = (sum(ismember(obj.Map.Allowed.Current,stReturn.Name)) == 1);
            stReturn.isEField              = (sum(ismember(obj.Map.Allowed.EField,stReturn.Name)) == 1);
            stReturn.isBField              = (sum(ismember(obj.Map.Allowed.BField,stReturn.Name)) == 1);
            stReturn.isEFieldExt           = (sum(ismember(obj.Map.Allowed.EFieldExt,stReturn.Name)) == 1);
            stReturn.isBFieldExt           = (sum(ismember(obj.Map.Allowed.BFieldExt,stReturn.Name)) == 1);
            stReturn.isEFieldPart          = (sum(ismember(obj.Map.Allowed.EFieldPart,stReturn.Name)) == 1);
            stReturn.isBFieldPart          = (sum(ismember(obj.Map.Allowed.BFieldPart,stReturn.Name)) == 1);
            stReturn.isEFieldEnergy        = (sum(ismember(obj.Map.Allowed.EFieldEnergy,stReturn.Name)) == 1);
            stReturn.isBFieldEnergy        = (sum(ismember(obj.Map.Allowed.BFieldEnergy,stReturn.Name)) == 1);
            stReturn.isField               = (sum(ismember(obj.Map.Allowed.Field,stReturn.Name)) == 1);
            stReturn.isFieldEnergy         = (sum(ismember(obj.Map.Allowed.FieldEnergy,stReturn.Name)) == 1);
            stReturn.isFieldDiv            = (sum(ismember(obj.Map.Allowed.FieldDiv,stReturn.Name)) == 1);
            stReturn.isQuantity            = (sum(ismember(obj.Map.Allowed.Quantity,stReturn.Name)) == 1);
            stReturn.isFlux                = (sum(ismember(obj.Map.Allowed.Flux,stReturn.Name)) == 1);
            stReturn.isPoynting            = (sum(ismember(obj.Map.Allowed.Poynting,stReturn.Name)) == 1);
            stReturn.isUDist               = (sum(ismember(obj.Map.Allowed.UDist,stReturn.Name)) == 1);
            
            % Calculated
            stReturn.isWakefield           = (sum(ismember(obj.Map.Allowed.Wakefield,stReturn.Name)) == 1);

            % Diagnostics
            stReturn.isValidEMFDiag        = (sum(ismember(obj.Map.Diag.EMF,stReturn.Name)) == 1);
            stReturn.isValidSpeciesDiag    = (sum(ismember(obj.Map.Diag.Species,stReturn.Name)) == 1);
            stReturn.isValidPhaseSpaceDiag = (sum(ismember(obj.Map.Diag.PhaseSpace,stReturn.Name)) == 1);
            stReturn.isValidDepositDiag    = (sum(ismember(obj.Map.Diag.Deposit,stReturn.Name)) == 1);
            stReturn.isValidUDistDiag      = (sum(ismember(obj.Map.Diag.UDist,stReturn.Name)) == 1);
            
            % Append Number if Present
            if ~isempty(sNum)
                stReturn.Original = [stReturn.Original sNum];
                stReturn.Name     = [stReturn.Name sNum];
                stReturn.Full     = [stReturn.Full ' ' sNum];
                stReturn.Short    = [stReturn.Short sNum];
                stReturn.Tex      = [stReturn.Tex '_{' sNum '}'];
            end % if
            
        end % function

        function sReturn = Reverse(obj, sVar, sFrom)
            
            %
            %  Variables :: Reverse
            % **********************
            %  Reverse lookup of an output variable type to find the variable name
            %
            %  Input
            % =======
            %  sVar  :: Variable to lookup. Required.
            %  sFrom :: Variable output type to do reverse lookup on.
            %           Default: 'Full'
            %
            
            sReturn = '';
            
            if nargin < 3
                sFrom = 'Full';
            end % if
            
            %
            % Lookup
            %

            bFound   = 0;
            stSearch = obj.Types;
            for s=1:length(stSearch)
                sType = stSearch{s};
                for i=1:size(obj.Map.Translate.(sType),2)
                    stItem = obj.Map.Translate.(sType)(i);
                    if strcmpi(stItem.(sFrom)(obj.Coords),sVar)
                        sReturn = stItem.Name;
                        bFound  = 1;
                        break;
                    end % if
                end % for
                if bFound
                    break;
                end % if
            end % for

        end % function
        
        function stReturn = EvalPhaseSpace(obj, vVar)
            
            %
            %  Variables :: EvalPhaseSpace
            % *****************************
            %  Analyses PhaseSpace diagnostics and extract the various variables
            %  used and sets up a break down of these in a table.
            %
            %  Input
            % =======
            %  vVar :: String or cell array of phasespace variables.
            %          Compatible with data from OsirisConfig class.
            %
            
            % Output
            stReturn.Details = {};
            stReturn.Dim1    = {};
            stReturn.Dim2    = {};
            stReturn.Dim3    = {};
            
            % Check input
            if ~isempty(vVar)
                if iscell(vVar)
                    cVar = vVar;
                else
                    cVar = {vVar};
                end % if
            else
                return;
            end % if
            
            stReturn.Details(length(cVar)).Input   = [];
            stReturn.Details(length(cVar)).Name    = [];
            stReturn.Details(length(cVar)).Dim     = [];
            stReturn.Details(length(cVar)).Var1    = [];
            stReturn.Details(length(cVar)).Var2    = [];
            stReturn.Details(length(cVar)).Var3    = [];
            stReturn.Details(length(cVar)).Deposit = [];
            
            for v=1:length(cVar)
                
                sVar = char(cVar{v});
                stReturn.Details(v).Input   = sVar;
                stReturn.Details(v).Name    = '';
                stReturn.Details(v).Dim     = 0;
                stReturn.Details(v).Var1    = '';
                stReturn.Details(v).Var2    = '';
                stReturn.Details(v).Var3    = '';
                stReturn.Details(v).Deposit = 'charge';
                
                cParts = strsplit(sVar,'_');
                if length(cParts) > 1
                    sVar = cParts{1};
                    if sum(ismember(obj.Map.Diag.Deposit,cParts{2})) == 1
                        stReturn.Details(v).Deposit = cParts{2};
                    end % if
                end % if
                
                for i=1:3
                    for p=1:length(obj.Map.Diag.PhaseSpace)

                        sCheck = obj.Map.Diag.PhaseSpace{p};
                        if length(sVar) < length(sCheck); continue; end % if

                        if strcmpi(sCheck, sVar(1:length(sCheck)))
                            if length(sVar) > length(sCheck) + 1
                                sVar = sVar(length(sCheck)+1:end);
                            else
                                sVar = '';
                            end % if

                            stReturn.Details(v).Dim = i;
                            switch(i)
                                case 1; stReturn.Details(v).Var1 = sCheck;
                                case 2; stReturn.Details(v).Var2 = sCheck;
                                case 3; stReturn.Details(v).Var3 = sCheck;
                            end % switch

                            break;
                        end % if
                    end % for
                end % for
                
                sDimVar = stReturn.Details(v).Var1;
                if stReturn.Details(v).Dim > 1
                    sDimVar = [sDimVar, stReturn.Details(v).Var2];
                end % if
                if stReturn.Details(v).Dim > 2
                    sDimVar = [sDimVar, stReturn.Details(v).Var3];
                end % if

                switch(stReturn.Details(v).Dim)
                    case 1
                        stReturn.Dim1{end+1} = [sDimVar, '_', stReturn.Details(v).Deposit];
                    case 2
                        stReturn.Dim2{end+1} = [sDimVar, '_', stReturn.Details(v).Deposit];
                    case 3
                        stReturn.Dim3{end+1} = [sDimVar, '_', stReturn.Details(v).Deposit];
                end % switch
                
                stReturn.Details(v).Name = [sDimVar, '_', stReturn.Details(v).Deposit];
                
            end % for
            
        end % function
        
    end % methods

end % classdef
