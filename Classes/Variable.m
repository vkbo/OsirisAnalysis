
%
%  Class Object :: Translate Variable Name
% *****************************************
%

classdef Variable
    
    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Original = '';
        Search   = {};
        Type     = {};
        Coords   = 1;
        Name     = '';
        Full     = '';
        Short    = '';
        Tex      = '';
        
        % Private
        Map      = {};
        Types    = {};
        Count    = 0;

    end % properties
    
    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')
        

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Variable(sVar, vCoords, vType)
            
            %
            % Check Inputs
            %
            
            % Default Args
            if nargin < 3
                vType = '';
            end % if
            if nargin < 2
                vCoords = 'cylindrical';
            end % if
            
            % Variable
            obj.Original = sVar;
            fprintf('Var: %s\n',sVar);
            
            % Coordinates
            if isInteger(vCoords)
                iCoords = vCoords;
            else
                switch vCoords
                    case 'cylindrical'
                        iCoords = 1;
                    case 'cartesian'
                        iCoords = 2;
                    otherwise
                        iCoords = 2;
                end % switch
            end % if
            if ~(iCoords == 1 || iCoords == 2)
                iCoords = 1;
            end % if
            obj.Coords = iCoords;
            fprintf('Coords: %d\n',iCoords);
            
            % Type
            stSearch = {};
            if ~isempty(vType)
                if iscell(vType)
                    stSearch = vType;
                else
                    stSearch = {vType};
                end % if
            end % if
            
            obj.Types = {'Beam','Plasma','Species','Axis','Momentum','Angular', ...
                         'Current','Electric','Magnetic','Field', ...
                         'Quantity','Flux','Poynting','Property'};

            for t=1:length(stSearch)
                sType = stSearch{t};
                sType = [upper(sType(1)) lower(sType(2:end))];
                if sum(ismember(obj.Types, sType)) == 1
                    obj.Search{end+1} = sType;
                else
                    fprintf(2,'Error: Unknown variable type "%s".\n',stSearch{t});
                end % if
            end % for

            
            %
            %  Create Translation Map
            % ************************
            %

            % Species names used in OsirisAnalysis
            stMap.Allowed.Beam     = {'ElectronBeam','PositronBeam','ProtonBeam','IonBeam'};
            stMap.Allowed.Plasma   = {'PlasmaElectrons','PlasmaProtons','PlasmaIons'};
            stMap.Allowed.Species  = [stMap.Allowed.Beam,stMap.Allowed.Plasma];

            % Osiris variables
            stMap.Allowed.Axis     = {'x1','x2','x3'};
            stMap.Allowed.Momentum = {'p1','p2','p3'};
            stMap.Allowed.Angular  = {'l1','l2','l3'};
            stMap.Allowed.Current  = {'j1','j2','j3'};
            stMap.Allowed.Electric = {'e1','e2','e3','e'};
            stMap.Allowed.Magnetic = {'b1','b2','b3','b'};
            stMap.Allowed.Field    = [stMap.Allowed.Electric,stMap.Allowed.Magnetic,{'emf'}];
            stMap.Allowed.Quantity = {'charge','|charge|','chargecons','m','ene','g','gl','psi','t'};
            stMap.Allowed.Flux     = {'q1','q2','q3'};
            stMap.Allowed.Poynting = {'s1','s2','s3'};
            stMap.Allowed.Property = {'ext','part','div'};
            
            % Osiris diagnostics options
            stMap.Diag.EMF        = {'e1','e2','e3','b1','b2','b3', ...
                                     'ext_e1','ext_e2','ext_e3','ext_b1','ext_b2','ext_b3', ...
                                     'part_e1','part_e2','part_e3','part_b1','part_b2','part_b3', ...
                                     'ene_e1','ene_e2','ene_e3','ene_b1','ene_b2','ene_b3', ...
                                     'ene_e','ene_b','ene_emf', ...
                                     'div_e','div_b','chargecons','psi', ...
                                     's1','s2','s3'};
            stMap.Diag.Species    = {'charge','m','ene','q1','q2','q3','j1','j2','j3'};
            stMap.Diag.PhaseSpace = {'x1','x2','x3','p1','p2','p3','l1','l2','l3','g','gl', ...
                                     'charge','m','ene','|charge|','q1','q2','q3','j1','j2','j3'};
            
            % Alternative names used in input deck
            stMap.Deck.Species.ElectronBeam    = {'ElectronBeam','electron_beam'};
            stMap.Deck.Species.PositronBeam    = {'PositronBeam','positron_beam'};
            stMap.Deck.Species.ProtonBeam      = {'ProtonBeam','proton_beam'};
            stMap.Deck.Species.IonBeam         = {'IonBeam','ion_beam'};
            stMap.Deck.Species.PlasmaElectrons = {'PlasmaElectrons','plasma_electrons'};
            stMap.Deck.Species.PlasmaProtons   = {'PlasmaProtons','plasma_protons'};
            stMap.Deck.Species.PlasmaIons      = {'PlasmaIons','plasma_ions'};
            
            %
            % Translations for readability
            %
            
            % Beam

            stMap.Translate.Beam(1).Name   = 'ElectronBeam';
            stMap.Translate.Beam(1).Alt    = horzcat({'eb','e-'},stMap.Deck.Species.ElectronBeam);
            stMap.Translate.Beam(1).Full   = {'Electron Beam','Electron Beam'};
            stMap.Translate.Beam(1).Short  = {'EB','EB'};
            stMap.Translate.Beam(1).Tex    = {'e-','e-'};

            stMap.Translate.Beam(2).Name   = 'PositronBeam';
            stMap.Translate.Beam(2).Alt    = horzcat({'e+b','e+'},stMap.Deck.Species.PositronBeam);
            stMap.Translate.Beam(2).Full   = {'Positron Beam','Positron Beam'};
            stMap.Translate.Beam(2).Short  = {'E+B','E+B'};
            stMap.Translate.Beam(2).Tex    = {'e+','e+'};

            stMap.Translate.Beam(3).Name   = 'ProtonBeam';
            stMap.Translate.Beam(3).Alt    = horzcat({'pb','p+'},stMap.Deck.Species.ProtonBeam);
            stMap.Translate.Beam(3).Full   = {'Proton Beam','Proton Beam'};
            stMap.Translate.Beam(3).Short  = {'PB','PB'};
            stMap.Translate.Beam(3).Tex    = {'p+','p+'};

            stMap.Translate.Beam(4).Name   = 'IonBeam';
            stMap.Translate.Beam(4).Alt    = horzcat({'ib','i+'},stMap.Deck.Species.IonBeam);
            stMap.Translate.Beam(4).Full   = {'Ion Beam','Ion Beam'};
            stMap.Translate.Beam(4).Short  = {'IB','IB'};
            stMap.Translate.Beam(4).Tex    = {'i+','i+'};

            % Plasma

            stMap.Translate.Plasma(1).Name   = 'PlasmaElectrons';
            stMap.Translate.Plasma(1).Alt    = horzcat({'pe','pe-'},stMap.Deck.Species.PlasmaElectrons);
            stMap.Translate.Plasma(1).Full   = {'Plasma Electron','Plasma Electron'};
            stMap.Translate.Plasma(1).Short  = {'PE','PE'};
            stMap.Translate.Plasma(1).Tex    = {'e-','e-'};

            stMap.Translate.Plasma(2).Name   = 'PlasmaProtons';
            stMap.Translate.Plasma(2).Alt    = horzcat({'pp','pp+'},stMap.Deck.Species.PlasmaProtons);
            stMap.Translate.Plasma(2).Full   = {'Plasma Proton','Plasma Proton'};
            stMap.Translate.Plasma(2).Short  = {'PP','PP'};
            stMap.Translate.Plasma(2).Tex    = {'p+','p+'};

            stMap.Translate.Plasma(3).Name   = 'PlasmaIons';
            stMap.Translate.Plasma(3).Alt    = horzcat({'pi','pi+','ion'},stMap.Deck.Species.PlasmaIons);
            stMap.Translate.Plasma(3).Full   = {'Plasma Ion','Plasma Ion'};
            stMap.Translate.Plasma(3).Short  = {'Ion','Ion'};
            stMap.Translate.Plasma(3).Tex    = {'i+','i+'};
            
            % Species
            stMap.Translate.Species = horzcat(stMap.Translate.Beam,stMap.Translate.Plasma);

            % Axis

            stMap.Translate.Axis(1).Name   = 'x1';
            stMap.Translate.Axis(1).Alt    = {'z'};
            stMap.Translate.Axis(1).Full   = {'Longitudinal Axis','Longitudinal Axis'};
            stMap.Translate.Axis(1).Short  = {'z','z'};
            stMap.Translate.Axis(1).Tex    = {'z','z'};

            stMap.Translate.Axis(2).Name   = 'x2';
            stMap.Translate.Axis(2).Alt    = {'r','x'};
            stMap.Translate.Axis(2).Full   = {'Radial Axis','Horizontal Axis'};
            stMap.Translate.Axis(2).Short  = {'r','x'};
            stMap.Translate.Axis(2).Tex    = {'r','x'};
            
            stMap.Translate.Axis(3).Name   = 'x3';
            stMap.Translate.Axis(3).Alt    = {'th','y'};
            stMap.Translate.Axis(3).Full   = {'Azimuthal Axis','Vertical Axis'};
            stMap.Translate.Axis(3).Short  = {'th','y'};
            stMap.Translate.Axis(3).Tex    = {'\theta','y'};

            % Momentum

            stMap.Translate.Momentum(1).Name   = 'p1';
            stMap.Translate.Momentum(1).Alt    = {'pz','p_z'};
            stMap.Translate.Momentum(1).Full   = {'Longitudinal Momentum','Longitudinal Momentum'};
            stMap.Translate.Momentum(1).Short  = {'Pz','Pz'};
            stMap.Translate.Momentum(1).Tex    = {'p_{z}','p_{z}'};

            stMap.Translate.Momentum(2).Name   = 'p2';
            stMap.Translate.Momentum(2).Alt    = {'px','p_x','pr','p_r'};
            stMap.Translate.Momentum(2).Full   = {'Radial Momentum','Horizontal Momentum'};
            stMap.Translate.Momentum(2).Short  = {'Pr','Px'};
            stMap.Translate.Momentum(2).Tex    = {'p_{r}','p_{x}'};
            
            stMap.Translate.Momentum(3).Name   = 'p3';
            stMap.Translate.Momentum(3).Alt    = {'py','p_y','pth','p_th'};
            stMap.Translate.Momentum(3).Full   = {'Azimuthal Momentum','Vertical Momentum'};
            stMap.Translate.Momentum(3).Short  = {'Pth','Py'};
            stMap.Translate.Momentum(3).Tex    = {'p_{\theta}','p_{y}'};

            % Angular Momentum

            stMap.Translate.Angular(1).Name   = 'l1';
            stMap.Translate.Angular(1).Alt    = {'lz','l_z'};
            stMap.Translate.Angular(1).Full   = {'Longitudinal Angular Momentum','Longitudinal Angular Momentum'};
            stMap.Translate.Angular(1).Short  = {'Lz','Lz'};
            stMap.Translate.Angular(1).Tex    = {'l_{z}','l_{z}'};

            stMap.Translate.Angular(2).Name   = 'l2';
            stMap.Translate.Angular(2).Alt    = {'lx','l_x','lr','l_r'};
            stMap.Translate.Angular(2).Full   = {'Radial Angular Momentum','Horizontal Angular Momentum'};
            stMap.Translate.Angular(2).Short  = {'Pr','Px'};
            stMap.Translate.Angular(2).Tex    = {'p_{r}','p_{x}'};
            
            stMap.Translate.Angular(3).Name   = 'l3';
            stMap.Translate.Angular(3).Alt    = {'ly','l_y','lth','l_th'};
            stMap.Translate.Angular(3).Full   = {'Azimuthal Angular Momentum','Vertical Angular Momentum'};
            stMap.Translate.Angular(3).Short  = {'Lth','Ly'};
            stMap.Translate.Angular(3).Tex    = {'l_{\theta}','l_{y}'};

            % Current

            stMap.Translate.Current(1).Name   = 'j1';
            stMap.Translate.Current(1).Alt    = {'jz','j_z'};
            stMap.Translate.Current(1).Full   = {'Longitudinal Current','Longitudinal Current'};
            stMap.Translate.Current(1).Short  = {'Jz','Jz'};
            stMap.Translate.Current(1).Tex    = {'j_{z}','j_{z}'};

            stMap.Translate.Current(2).Name   = 'j2';
            stMap.Translate.Current(2).Alt    = {'jx','j_x','jr','j_r'};
            stMap.Translate.Current(2).Full   = {'Radial Current','Horizontal Current'};
            stMap.Translate.Current(2).Short  = {'Jr','Jx'};
            stMap.Translate.Current(2).Tex    = {'j_{r}','j_{x}'};
            
            stMap.Translate.Current(3).Name   = 'j3';
            stMap.Translate.Current(3).Alt    = {'jy','j_y','jth','j_th'};
            stMap.Translate.Current(3).Full   = {'Azimuthal Current','Vertical Current'};
            stMap.Translate.Current(3).Short  = {'Jth','Jy'};
            stMap.Translate.Current(3).Tex    = {'j_{\theta}','j_{y}'};

            % Electric Field

            stMap.Translate.Electric(1).Name   = 'e1';
            stMap.Translate.Electric(1).Alt    = {'ez','e_z'};
            stMap.Translate.Electric(1).Full   = {'Longitudinal E-Field','Longitudinal E-Field'};
            stMap.Translate.Electric(1).Short  = {'Ez','Ez'};
            stMap.Translate.Electric(1).Tex    = {'E_{z}','E_{z}'};

            stMap.Translate.Electric(2).Name   = 'e2';
            stMap.Translate.Electric(2).Alt    = {'ex','e_x','er','e_r'};
            stMap.Translate.Electric(2).Full   = {'Radial E-Field','Horizontal E-Field'};
            stMap.Translate.Electric(2).Short  = {'Er','Ex'};
            stMap.Translate.Electric(2).Tex    = {'E_{r}','E_{x}'};
            
            stMap.Translate.Electric(3).Name   = 'e3';
            stMap.Translate.Electric(3).Alt    = {'ey','e_y','eth','e_th'};
            stMap.Translate.Electric(3).Full   = {'Azimuthal E-Field','Vertical E-Field'};
            stMap.Translate.Electric(3).Short  = {'Eth','Ey'};
            stMap.Translate.Electric(3).Tex    = {'E_{\theta}','E_{y}'};
            
            stMap.Translate.Electric(4).Name   = 'e';
            stMap.Translate.Electric(4).Alt    = {'et','e_t'};
            stMap.Translate.Electric(4).Full   = {'Electric Field','Electric Field'};
            stMap.Translate.Electric(4).Short  = {'|E|','|E|'};
            stMap.Translate.Electric(4).Tex    = {'|E|','|E|'};

            % Magnetic Field

            stMap.Translate.Magnetic(1).Name   = 'b1';
            stMap.Translate.Magnetic(1).Alt    = {'bz','b_z'};
            stMap.Translate.Magnetic(1).Full   = {'Longitudinal B-Field','Longitudinal B-Field'};
            stMap.Translate.Magnetic(1).Short  = {'Bz','Bz'};
            stMap.Translate.Magnetic(1).Tex    = {'B_{z}','B_{z}'};

            stMap.Translate.Magnetic(2).Name   = 'b2';
            stMap.Translate.Magnetic(2).Alt    = {'bx','b_x','br','b_r'};
            stMap.Translate.Magnetic(2).Full   = {'Radial B-Field','Horizontal B-Field'};
            stMap.Translate.Magnetic(2).Short  = {'Br','Bx'};
            stMap.Translate.Magnetic(2).Tex    = {'B_{r}','B_{x}'};
            
            stMap.Translate.Magnetic(3).Name   = 'b3';
            stMap.Translate.Magnetic(3).Alt    = {'by','b_y','bth','b_th'};
            stMap.Translate.Magnetic(3).Full   = {'Azimuthal B-Field','Vertical B-Field'};
            stMap.Translate.Magnetic(3).Short  = {'Bth','By'};
            stMap.Translate.Magnetic(3).Tex    = {'B_{\theta}','B_{y}'};
            
            stMap.Translate.Magnetic(4).Name   = 'b';
            stMap.Translate.Magnetic(4).Alt    = {'bt','b_t'};
            stMap.Translate.Magnetic(4).Full   = {'Magnetic Field','Magnetic Field'};
            stMap.Translate.Magnetic(4).Short  = {'|B|','|B|'};
            stMap.Translate.Magnetic(4).Tex    = {'|B|','|B|'};

            % EM Field

            stMap.Translate.Field           = horzcat(stMap.Translate.Electric,stMap.Translate.Magnetic);
            stMap.Translate.Field(9).Name   = 'emf';
            stMap.Translate.Field(9).Alt    = {'em'};
            stMap.Translate.Field(9).Full   = {'Electromagnetic Field','Electromagnetic Field'};
            stMap.Translate.Field(9).Short  = {'E²+B²','E²+B²'};
            stMap.Translate.Field(9).Tex    = {'E^{2}+B^{2}','E^{2}+B^{2}'};
            
            % Quantity
            
            stMap.Translate.Quantity(1).Name   = 'charge';
            stMap.Translate.Quantity(1).Alt    = {'q'};
            stMap.Translate.Quantity(1).Full   = {'Charge','Charge'};
            stMap.Translate.Quantity(1).Short  = {'Q','Q'};
            stMap.Translate.Quantity(1).Tex    = {'q','q'};

            stMap.Translate.Quantity(2).Name   = '|charge|';
            stMap.Translate.Quantity(2).Alt    = {'|q|'};
            stMap.Translate.Quantity(2).Full   = {'Absolute Charge','Absolute Charge'};
            stMap.Translate.Quantity(2).Short  = {'|Q|','|Q|'};
            stMap.Translate.Quantity(2).Tex    = {'|q|','|q|'};

            stMap.Translate.Quantity(3).Name   = 'chargecons';
            stMap.Translate.Quantity(3).Alt    = {'qcons'};
            stMap.Translate.Quantity(3).Full   = {'Charge Conservation','Charge Conservation'};
            stMap.Translate.Quantity(3).Short  = {'QCons','QCons'};
            stMap.Translate.Quantity(3).Tex    = {'q_{cons}','q_{cons}'};

            stMap.Translate.Quantity(4).Name   = 'm';
            stMap.Translate.Quantity(4).Alt    = {'mass'};
            stMap.Translate.Quantity(4).Full   = {'Mass','Mass'};
            stMap.Translate.Quantity(4).Short  = {'Mass','Mass'};
            stMap.Translate.Quantity(4).Tex    = {'m','m'};

            stMap.Translate.Quantity(5).Name   = 'ene';
            stMap.Translate.Quantity(5).Alt    = {'energy','e_k'};
            stMap.Translate.Quantity(5).Full   = {'Kinetic Energy','Kinetic Energy'};
            stMap.Translate.Quantity(5).Short  = {'Ek','Ek'};
            stMap.Translate.Quantity(5).Tex    = {'E_{k}','E_{k}'};

            stMap.Translate.Quantity(6).Name   = 'g';
            stMap.Translate.Quantity(6).Alt    = {'gamma'};
            stMap.Translate.Quantity(6).Full   = {'Lorentz Factor','Lorentz Factor'};
            stMap.Translate.Quantity(6).Short  = {'Gamma','Gamma'};
            stMap.Translate.Quantity(6).Tex    = {'\gamma','\gamma'};

            stMap.Translate.Quantity(7).Name   = 'gl';
            stMap.Translate.Quantity(7).Alt    = {'log_gamma'};
            stMap.Translate.Quantity(7).Full   = {'Lorentz Factor','Lorentz Factor'};
            stMap.Translate.Quantity(7).Short  = {'Log(Gamma)','Log(Gamma)'};
            stMap.Translate.Quantity(7).Tex    = {'\log(\gamma)','\log(\gamma)'};

            stMap.Translate.Quantity(8).Name   = 'psi';
            stMap.Translate.Quantity(8).Alt    = {};
            stMap.Translate.Quantity(8).Full   = {'Pseudopotential','Pseudopotential'};
            stMap.Translate.Quantity(8).Short  = {'Psi','Psi'};
            stMap.Translate.Quantity(8).Tex    = {'\Psi_{x}','\Psi_{x}'};

            stMap.Translate.Quantity(9).Name   = 't';
            stMap.Translate.Quantity(9).Alt    = {};
            stMap.Translate.Quantity(9).Full   = {'Time','Time'};
            stMap.Translate.Quantity(9).Short  = {'Time','Time'};
            stMap.Translate.Quantity(9).Tex    = {'t','t'};

            % Flux

            stMap.Translate.Flux(1).Name   = 'q1';
            stMap.Translate.Flux(1).Alt    = {'qz','q_z'};
            stMap.Translate.Flux(1).Full   = {'Longitudinal Flux','Longitudinal Flux'};
            stMap.Translate.Flux(1).Short  = {'Qz','Qz'};
            stMap.Translate.Flux(1).Tex    = {'q_{z}','q_{z}'};

            stMap.Translate.Flux(2).Name   = 'q2';
            stMap.Translate.Flux(2).Alt    = {'qr','q_r','qx','q_x'};
            stMap.Translate.Flux(2).Full   = {'Radial Flux','Horizontal Flux'};
            stMap.Translate.Flux(2).Short  = {'Qr','Qx'};
            stMap.Translate.Flux(2).Tex    = {'q_{r}','q_{x}'};
            
            stMap.Translate.Flux(3).Name   = 'q3';
            stMap.Translate.Flux(3).Alt    = {'qth','q_th','qy','q_y'};
            stMap.Translate.Flux(3).Full   = {'Azimuthal Flux','Vertical Flux'};
            stMap.Translate.Flux(3).Short  = {'Qth','Qy'};
            stMap.Translate.Flux(3).Tex    = {'q_{\theta}','q_{y}'};

            % Poynting Flux

            stMap.Translate.Poynting(1).Name   = 's1';
            stMap.Translate.Poynting(1).Alt    = {'sz','s_z'};
            stMap.Translate.Poynting(1).Full   = {'Longitudinal Poynting Flux','Longitudinal Poynting Flux'};
            stMap.Translate.Poynting(1).Short  = {'Sz','Sz'};
            stMap.Translate.Poynting(1).Tex    = {'s_{z}','s_{z}'};

            stMap.Translate.Poynting(2).Name   = 's2';
            stMap.Translate.Poynting(2).Alt    = {'sr','s_r','sx','s_x'};
            stMap.Translate.Poynting(2).Full   = {'Radial Poynting Flux','Horizontal Poynting Flux'};
            stMap.Translate.Poynting(2).Short  = {'Sr','Sx'};
            stMap.Translate.Poynting(2).Tex    = {'s_{r}','s_{x}'};
            
            stMap.Translate.Poynting(3).Name   = 's3';
            stMap.Translate.Poynting(3).Alt    = {'sth','s_th','sy','s_y'};
            stMap.Translate.Poynting(3).Full   = {'Azimuthal Poynting Flux','Vertical Poynting Flux'};
            stMap.Translate.Poynting(3).Short  = {'Sth','Sy'};
            stMap.Translate.Poynting(3).Tex    = {'s_{\theta}','s_{y}'};
            
            % Property
            
            stMap.Translate.Property(1).Name   = 'ext';
            stMap.Translate.Property(1).Alt    = {};
            stMap.Translate.Property(1).Full   = {'External %s','External %s'};
            stMap.Translate.Property(1).Short  = {'%s Ext','%s Ext'};
            stMap.Translate.Property(1).Tex    = {'%s_{ext}','%s_{ext}'};
            
            stMap.Translate.Property(2).Name   = 'part';
            stMap.Translate.Property(2).Alt    = {};
            stMap.Translate.Property(2).Full   = {'%s of Particle','%s of Particle'};
            stMap.Translate.Property(2).Short  = {'%s Part','%s Part'};
            stMap.Translate.Property(2).Tex    = {'%s_{part}','%s_{part}'};
            
            stMap.Translate.Property(3).Name   = 'div';
            stMap.Translate.Property(3).Alt    = {};
            stMap.Translate.Property(3).Full   = {'%s Divergence','%s Divergence'};
            stMap.Translate.Property(3).Short  = {'Div %s','Div %s'};
            stMap.Translate.Property(3).Tex    = {'\Nabla \cdot %s','\Nabla \cdot %s'};
            
            % Save map
            obj.Map = stMap;
            
            stLookup = obj.fLookup;
            
            if ~isempty(stLookup)
                obj.Name  = stLookup.Name;
                obj.Full  = stLookup.Full{obj.Coords};
                obj.Short = stLookup.Short{obj.Coords};
                obj.Tex   = stLookup.Tex{obj.Coords};
            end % if
            
        end % function

    end % methods

    %
    % Setters and Getters
    %

    methods

    end % methods

    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function stReturn = fLookup(obj)
            
            stReturn = {};

            % If types are specified, search those.
            % Otherwise search all valid types.
            if ~isempty(obj.Search)
                stSearch = obj.Search;
            else
                stSearch = obj.Types;
            end % if

            sVar = lower(obj.Original);
            
            for s=1:length(stSearch)
                
                sType = stSearch{s};

                for i=1:size(obj.Map.Translate.(sType),2)
                    stItem = obj.Map.Translate.(sType)(i);
                    if strcmpi(stItem.Name,sVar)
                        stReturn = stItem;
                        return;
                    end % if
                    %if numel(stItem.Alt) == 0
                    %    continue;
                    %end % if
                    if sum(ismember(stItem.Alt,sVar)) == 1
                        stReturn = stItem;
                        return;
                    end % if
                end % for
                
            end % for
        
        end % function
        
    end % methods

end % classdef
