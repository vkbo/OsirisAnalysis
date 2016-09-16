
%
%  Class Object :: Holds the Osiris Config file
% **********************************************
%

classdef OsirisConfig
    
    %
    % Properties
    %
    
    properties(GetAccess='public', SetAccess='public')

        Path       = '';     % Path to data directory
        File       = '';     % Config file within data directory
        SimN0      = 1.0e20; % Plasma density for simulation
        PhysN0     = 0.0;    % Plasma density for physics
        Silent     = false;  % Set to true to disable command window output

    end % properties

    properties(GetAccess='public', SetAccess='private')
    
        Name       = '';     % Name of the loaded dataset
        Details    = {};     % Description of simulation. First lines of comments.
        Input      = {};     % Parsed input file
        Constants  = {};     % Constants
        Convert    = {};     % Unit conversion factors
        Simulation = {};     % Simulation variables
        EMFields   = {};     % Electro-magnetic field variables
        Particles  = {};     % Particle variables

    end % properties

    properties(GetAccess='private', SetAccess='private')

        Files      = {};     % Holds possible config files
        Translate  = {};     % Container for Variables class
        NameLists  = {};     % Container for Fortran namelists
        
    end % properties

    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisConfig()
            
            % SI Constants
            obj.Constants.SI.SpeedOfLight       =  2.99792458e8;    % m/s (exact)
            obj.Constants.SI.ElectronMass       =  9.10938291e-31;  % kg
            obj.Constants.SI.ElementaryCharge   =  1.602176565e-19; % C
            obj.Constants.SI.VacuumPermitivity  =  8.854187817e-12; % F/m 
            obj.Constants.SI.VacuumPermeability =  1.2566370614e-6; % N/A^2
            obj.Constants.SI.Boltzmann          =  1.38064852e-23;  % J/K
            
            % Electron Volts
            obj.Constants.EV.ElectronMass       =  5.109989282e5;   % eV/c^2
            obj.Constants.EV.Boltzmann          =  8.6173324e-5;    % eV/K

            % CGS Constants
            obj.Constants.CGS.ElementaryCharge  =  4.80320425e-10;  % statC
            obj.Constants.CGS.Boltzmann         =  1.38064852e-16;  % erg/K

            % Translae Class for Variables
            obj.Translate = Variables();
            
        end % function
        
    end % methods

    %
    % Setters an Getters
    %
    
    methods
        
        function obj = set.Path(obj, sPath)

            if ~isdir(sPath)
                return;
            end % if

            obj.Path = sPath;
            aPath    = strsplit(obj.Path, '/');
            obj.Name = aPath{end};

            aFiles = {};

            aDir = dir(sPath);
            for i=1:length(aDir)
                if ~isdir(strcat(obj.Path, '/', aDir(i).name))
 
                    [~, ~, sFileExt] = fileparts(aDir(i).name);
                    
                    cExclude = {'.out','.sh','.e', '.tags'}; % Files to exclude as definitely not the config file
                    aSizes   = [1024, 20480];                % Minimum, maximum size in bytes
                    
                    if sum(ismember(sFileExt, cExclude)) == 0 ...
                            && sFileExt(end) ~= '~'           ...
                            && aDir(i).bytes >= aSizes(1)     ...
                            && aDir(i).bytes <= aSizes(2)
                        aFiles{end+1} = aDir(i).name;
                    end % if

                end % if
            end % for
            obj.Files = aFiles;

            switch (length(aFiles))

                case 0
                    fprintf(2, 'OsirisConfig Error: Input deck not found.\n');
                
                case 1
                    obj.File = 1;
                
                otherwise
                    fprintf('Multiple possible config files found.\n');
                    for i=1:length(aFiles)
                        fprintf('(%d) %s\n', i, aFiles{i});
                    end % for
                    fprintf('Use "object.Config.File = n" to set manually.\n');
            
            end % switch

        end % function
        
        function obj = set.File(obj, iFile)

            if iFile > 0 && iFile <= length(obj.Files)

                obj.File = obj.Files{iFile};
                if ~obj.Silent
                    fprintf('Config file set: %s\n', obj.File);
                end % if
                
                obj = obj.fReadNameLists();
                obj = obj.fParseInputFile();

                obj = obj.fGetSimulationVariables();
                obj = obj.fGetEMFVariables();
                obj = obj.fGetParticleVariables();
                
                % Set N0Sim and N0Phys
                obj.SimN0  = obj.Simulation.N0;
                obj.PhysN0 = obj.Simulation.PhysN0;
                
            end % if

        end % function
        
        function obj = set.SimN0(obj, dValue)
            
            % If N0 is defined in the input file, this value cannot be overridden!
            
            obj.SimN0         = abs(double(dValue));
            obj.Simulation.N0 = obj.SimN0;

            obj = obj.fGetSimulationVariables();
            
            dPlasmaFac                 = obj.Simulation.MaxPlasmaFac;
            obj.Simulation.PhysN0      = obj.SimN0 * dPlasmaFac;
            obj.Simulation.PhysOmegaP  = obj.Simulation.OmegaP * sqrt(dPlasmaFac);
            obj.Simulation.PhysLambdaP = obj.Simulation.LambdaP / sqrt(dPlasmaFac);
            
        end % function

        function obj = set.PhysN0(obj, dValue)
            
            % This Value does not affect any calculations in OsirisConfig,
            % but the chosen value is set to maximum plasma density.
            
            obj.PhysN0 = abs(double(dValue));

            dPlasmaFac                 = obj.PhysN0 / obj.SimN0;
            obj.Simulation.PhysN0      = obj.PhysN0;
            obj.Simulation.PhysOmegaP  = obj.Simulation.OmegaP * sqrt(dPlasmaFac);
            obj.Simulation.PhysLambdaP = obj.Simulation.LambdaP / sqrt(dPlasmaFac);

        end % function
        
    end % methods
    
    %
    %  Config File Methods
    %
    
    methods(Access='private')
        
        function obj = fReadNameLists(obj)
            
            % Read file
            sFile  = fileread([obj.Path '/' obj.File]);
            
            % Get Simulation Description
            cLines = strsplit(sFile,'\n');
            iLines = numel(cLines);
            bStop  = false;
            cDesc  = {};
            
            for i=1:iLines
                sLine = strtrim(cLines{i});
                if ~isempty(sLine)
                    if sLine(1) == '!'
                        cDesc{end+1} = strtrim(sLine(2:end));
                    else
                        bStop = true;
                    end % if
                end % if
                if bStop
                    break;
                end % if
            end % for

            obj.Details = cDesc;
            
            % Clean-up
            sFile = regexprep(sFile,'\!.*?\n','\n');   % Removes all comments
            sFile = regexprep(sFile,'[\n|\r|\t]',' '); % Removes tabs and line breaks
            sFile = strrep(sFile,'.true.','1');        % Replace .true. with matlab logical true
            sFile = strrep(sFile,'.false.','0');       % Replace .false. with matlab logical false
            sFile = strrep(sFile,'"','''');            % Replace quote marks

            % Parse file and extract name lists

            sBuffer = ' ';
            bQuote  = 0;

            iNL = 1;
            stNameLists(iNL).Section  = [];
            stNameLists(iNL).NameList = [];

            for c=1:length(sFile)
                
                % Check if inside quote
                if sFile(c) == ''''
                    bQuote = ~bQuote;
                end % if

                % Add character to buffer, except spaces outside of quotes
                if ~(sFile(c) == ' ' && ~bQuote)
                    sBuffer = [sBuffer sFile(c)];
                end % if
                
                % If the character is a '{', the buffer so far contains a section name
                if sFile(c) == '{' && ~bQuote
                    if length(sBuffer) > 1
                        stNameLists(iNL).Section = strtrim(sBuffer(1:end-1));
                        sBuffer = ' '; % Reset buffer
                    end % if
                end % if
                
                % If the character is a '}', the buffer so far contains a name list
                if sFile(c) == '}' && ~bQuote
                    if length(sBuffer) > 1
                        sBuffer = strtrim(sBuffer(1:end-1));
                        if ~isempty(sBuffer)
                            if sBuffer(end) ~= ','
                                sBuffer = [sBuffer,','];
                            end % if
                        end % if
                        stNameLists(iNL).NameList = sBuffer;
                        sBuffer = ' '; % Reset buffer
                        iNL = iNL + 1; % Move to next section
                    end % if
                end % if
                
            end % for
            
            % Save the name list
            obj.NameLists = stNameLists;
            
        end % function
        
        function obj = fParseInputFile(obj)
            
            stInput = {};
            cGrp = {'simulation','el_mag_fld','particles','zpulse','current','antenna_array'};
            iGrp = 1;
            
            aSim = [];
            aEMF = [];
            aPar = [];
            aZPl = [];
            aCur = [];
            aAnt = [];

            [~,iLMax] = size(obj.NameLists);
            for l=1:iLMax
                sSection = obj.NameLists(l).Section;
                if strcmpi(sSection,'simulation') || strcmpi(sSection,'node_conf')
                    iGrp = 1;
                end % if
                if strcmpi(sSection,'el_mag_fld') || strcmpi(sSection,'emf_bound')
                    iGrp = 2;
                end % if
                if strcmpi(sSection,'particles')
                    iGrp = 3;
                end % if
                if strcmpi(sSection,'zpulse')
                    iGrp = 4;
                end % if
                if iGrp > 2 && (strcmpi(sSection,'current') || strcmpi(sSection,'smooth') || strcmpi(sSection,'diag_current'))
                    iGrp = 5;
                end % if
                if strcmpi(sSection,'antenna_array') || strcmpi(sSection,'antenna')
                    iGrp = 6;
                end % if
                switch(iGrp)
                    case 1; aSim = [aSim l];
                    case 2; aEMF = [aEMF l];
                    case 3; aPar = [aPar l];
                    case 4; aZPl = [aZPl l];
                    case 5; aCur = [aCur l];
                    case 6; aAnt = [aAnt l];
                end % switch
            end % for

            % General Simulation Parameters
            for s=1:length(aSim)
                iSec = aSim(s);
                sSec = obj.NameLists(iSec).Section;
                sVal = obj.NameLists(iSec).NameList;
                stInput.(cGrp{1}).(sSec) = obj.fParseNameList(sVal);
            end % for
            
            % Electro-Magnetic Fields
            for s=1:length(aEMF)
                iSec = aEMF(s);
                sSec = obj.NameLists(iSec).Section;
                sVal = obj.NameLists(iSec).NameList;
                stInput.(cGrp{2}).(sSec) = obj.fParseNameList(sVal);
            end % for

            % Particles
            iCntS = 0;
            iCntC = 0;
            iCntN = 0;
            iCntI = 0;
            iType = 1;
            sType = '';
            for s=1:length(aPar)
                iSec = aPar(s);
                sSec = obj.NameLists(iSec).Section;
                sVal = obj.NameLists(iSec).NameList;
                stNL = obj.fParseNameList(sVal);
                if strcmpi(sSec,'particles') || strcmpi(sSec,'collisions')
                    stInput.(cGrp{3}).(sSec) = stNL;
                else
                    if strcmpi(sSec,'species') && iType == 1
                        iType = 1;
                        iCntS = iCntS + 1;
                        sType = sprintf('species_%d',iCntS);
                    end % if
                    if strcmpi(sSec,'cathode')
                        iType = 2;
                        iCntC = iCntC + 1;
                        sType = sprintf('cathode_%d',iCntC);
                    end % if
                    if strcmpi(sSec,'neutral')
                        iType = 3;
                        iCntN = iCntN + 1;
                        sType = sprintf('neutral_%d',iCntN);
                    end % if
                    if strcmpi(sSec,'neutral_mov_ions')
                        iType = 4;
                        iMovT = 0;
                        iCntI = iCntI + 1;
                        sType = sprintf('neutral_mov_ions_%d',iCntI);
                    end % if
                    if iType < 4
                        stInput.(cGrp{3}).(sType).(sSec) = stNL;
                    else
                        if strcmpi(sSec,'species') && iType == 4
                            iMovT = iMovT + 1;
                            sMovT = sprintf('species_%d',iMovT);
                        end % if
                        if iMovT == 0
                            stInput.(cGrp{3}).(sType).(sSec) = stNL;
                        else
                            stInput.(cGrp{3}).(sType).(sMovT).(sSec) = stNL;
                        end % if
                    end % if
                end % if
            end % for
            
            % Laser Pulses
            iCntZ = 0;
            sName = '';
            for s=1:length(aZPl)
                iSec = aZPl(s);
                sSec = obj.NameLists(iSec).Section;
                sVal = obj.NameLists(iSec).NameList;
                stNL = obj.fParseNameList(sVal);
                if strcmpi(sSec,'zpulse')
                    iCntZ = iCntZ + 1;
                    sName = sprintf('zpulse_%d',iCntZ);
                end % if
                stInput.(cGrp{4}).(sName).(sSec) = stNL;
            end % for

            % Electrical Current
            % This input is skipped

            % Antennas
            iCntA = 0;
            sName = '';
            for s=1:length(aAnt)
                iSec = aAnt(s);
                sSec = obj.NameLists(iSec).Section;
                sVal = obj.NameLists(iSec).NameList;
                stNL = obj.fParseNameList(sVal);
                if strcmpi(sSec,'antenna')
                    iCntA = iCntA + 1;
                    sName = sprintf('antenna_%d',iCntA);
                end % if
                stInput.(cGrp{6}).(sName).(sSec) = stNL;
            end % for

            % Save Struct
            obj.Input = stInput;
        
        end % function

    end % methods

    methods(Static, Access='private')
    
        function stReturn = fParseNameList(sData)
            
            stReturn = {};
            
            sBuffer = '';
            bQuote  = 0;
            bBrack  = 0;
            
            sVar = '';
            cVar = {};

            for c=1:length(sData)
                
                sBuffer = [sBuffer sData(c)];
                
                % Check if inside quote
                if sData(c) == ''''
                    bQuote = ~bQuote;
                end % if
                
                % Check if inside brackets
                if sData(c) == '('
                    bBrack = 1;
                end % if
                if sData(c) == ')'
                    bBrack = 0;
                end % if
                
                % After each variable follows an equal
                if sData(c) == '=' && ~bQuote && ~bBrack
                    if ~isempty(sVar)
                        try
                            evalc(['stReturn.',sVar,'={',strjoin(cVar,','),'}']);
                        catch
                            fprintf(2,'Error: Cannot parse variable ''%s'' in input file.\n',sVar);
                        end % try
                    end % if
                    sVar = sBuffer(1:end-1);
                    cVar = {};
                    sBuffer = '';
                end % if

                % After each value follows a comma
                if sData(c) == ',' && ~bQuote && ~bBrack
                    cVar{end+1} = sBuffer(1:end-1);
                    sBuffer = '';
                end % if

            end % for

            if ~isempty(sVar)
                try
                    evalc(['stReturn.',sVar,'={',strjoin(cVar,','),'}']);
                catch
                    fprintf(2,'Error: Cannot parse variable ''%s'' in input file.\n',sVar);
                end % try
            end % if
            
        end % function
        
        function aReturn = fArrayPad(aData, aTemplate)
            
            aTemplate(1:length(aData)) = aData;
            aReturn = aTemplate;
            
        end % function

    end % methods

    %
    %  Variable Methods
    %

    methods(Access = 'private')

        function obj = fGetSimulationVariables(obj)
            
            % Constants
            dC          = obj.Constants.SI.SpeedOfLight;
            dECharge    = obj.Constants.SI.ElementaryCharge;
            dEChargeCGS = obj.Constants.CGS.ElementaryCharge;
            dEMass      = obj.Constants.SI.ElectronMass;
            dEpsilon0   = obj.Constants.SI.VacuumPermitivity;
            dMu0        = obj.Constants.SI.VacuumPermeability;

            %
            % Main Simulation Variables
            %
            
            % Plasma Density
            % If this is defined, setting obj.SimN0 will not change anything!
            try
                dN0 = double(obj.Input.simulation.simulation.n0{1})*1.0e6;
            catch
                dN0 = obj.SimN0;
            end % try
            
            % Plasma Frequency
            try
                dOmegaP = double(obj.Input.simulation.simulation.omega_p0{1});
            catch
                dOmegaP = sqrt((dN0 * dECharge^2) / (dEMass * dEpsilon0));
            end % try

            % Plasma Wavelength
            dLambdaP = 2*pi * dC / dOmegaP;
            
            % Coordinates
            try
                aGrid = cell2mat(obj.Input.simulation.grid.nx_p);
            catch
                aGrid = 1;
            end % try
            iDim  = length(aGrid);
            aGrid = obj.fArrayPad(aGrid, [0 0 0]);

            % Grid
            try
                sCoords = obj.Input.simulation.grid.coordinates{1};
            catch
                sCoords = 'cartesian';
            end % try
            bCylindrical = strcmpi(sCoords,'cylindrical');

            % Time Step
            try
                dTimeStep = double(obj.Input.simulation.time_step.dt{1});
            catch
                dTimeStep = 0.0;
            end % try

            % NDump
            try
                iNDump = obj.Input.simulation.time_step.ndump{1};
            catch
                iNDump = 0;
            end % try

            % Start Time
            try
                dTMin = double(obj.Input.simulation.time.tmin{1});
            catch
                dTMin = 0.0;
            end % try

            % End Time
            try
                dTMax = double(obj.Input.simulation.time.tmax{1});
            catch
                dTMax = 0.0;
            end % try

            % Start Box
            try
                aXMin = double(cell2mat(obj.Input.simulation.space.xmin));
            catch
                aXMin = 0.0;
            end % try
            aXMin = obj.fArrayPad(aXMin, [0.0 0.0 0.0]);

            % End Box
            try
                aXMax = double(cell2mat(obj.Input.simulation.space.xmax));
            catch
                aXMax = 0.0;
            end % try
            aXMax = obj.fArrayPad(aXMax, [0.0 0.0 0.0]);

            % Moving
            try
                aMove = double(cell2mat(obj.Input.simulation.space.if_move));
            catch
                aMove = 0.0;
            end % try
            aMove = obj.fArrayPad(aMove, [0.0 0.0 0.0]);

            % Save Plasma Variables for Simulation
            obj.Simulation.N0          = dN0;
            obj.Simulation.OmegaP      = dOmegaP;
            obj.Simulation.LambdaP     = dLambdaP;

            % Save Plasma Variables for Physics
            % By default simulation values are used
            % These are later recalculated if a plasma species is found
            obj.Simulation.PhysN0      = dN0;
            obj.Simulation.PhysOmegaP  = dOmegaP;
            obj.Simulation.PhysLambdaP = dLambdaP;
            
            % Save Other Variables
            obj.Simulation.Coordinates = sCoords;
            obj.Simulation.Cylindrical = bCylindrical;
            obj.Simulation.Dimensions  = iDim;
            obj.Simulation.Grid        = aGrid;
            
            % Save Time Variables
            obj.Simulation.TimeStep    = dTimeStep;
            obj.Simulation.NDump       = iNDump;
            obj.Simulation.TMin        = dTMin;
            obj.Simulation.TMax        = dTMax;

            % Save Space Variables
            obj.Simulation.XMin        = aXMin;
            obj.Simulation.XMax        = aXMax;
            obj.Simulation.Moving      = aMove;

            
            %
            % Conversion Factors
            %
            
            % Geometry
            dLFactor = dC / dOmegaP;

            % Electric and Magnetic Field
            dSIE0 = dEMass * dC^3 * dOmegaP * dMu0*dEpsilon0 / dECharge;
            dSIB0 = dEMass * dC^2 * dOmegaP * dMu0*dEpsilon0 / dECharge;

            % Save Conversion Variables
            obj.Convert.SI.E0        = dSIE0;
            obj.Convert.SI.B0        = dSIB0;
            obj.Convert.SI.LengthFac = dLFactor;
            obj.Convert.SI.TimeFac   = dTimeStep*iNDump;
            
            
            %
            % Particle and Charge Conversion
            %
            
            dDX1 = (aXMax(1) - aXMin(1))/aGrid(1);
            dDX2 = (aXMax(2) - aXMin(2))/aGrid(2);
            if iDim == 2
                dDX3 = 1.0;
            else
                dDX3 = (aXMax(3) - aXMin(3))/aGrid(3);
            end % if

            dQFac = 1.0;                 % Factor for charge in normalised units
            dPFac = dN0;                 % Density is relative to N0

            if bCylindrical
                dQFac = dQFac*2*pi;      % Cylindrical factor
            end % if
            dPFac = dPFac*dDX1;          % Longitudinal cell size
            dPFac = dPFac*dDX2;          % Radial/X cell size
            dPFac = dPFac*dDX3;          % Azimuthal/Y cell size

            dPFac = dPFac*dLFactor^3;    % Convert from normalised units to unitless
            dPFac = dPFac*dQFac;         % Combine particle factor and charge factor

            obj.Convert.Norm.ChargeFac   = dQFac;
            obj.Convert.Norm.ParticleFac = dPFac;
            obj.Convert.SI.ChargeFac     = dPFac*dECharge;
            obj.Convert.SI.ParticleFac   = dPFac;
            obj.Convert.CGS.ChargeFac    = dPFac*dEChargeCGS;
            obj.Convert.CGS.ParticleFac  = dPFac;

            
            %
            % Current Conversion
            %

            aJFac = [1.0 1.0 1.0]; % In normalised units
            if strcmpi(sCoords, 'cylindrical')
                aJFacSI  = aJFac     * dPFac*dECharge*dC;
                aJFacSI  = aJFacSI  ./ (2*pi*[dDX1 dDX2 dDX3]*dLFactor);
                aJFacCGS = aJFac     * dPFac*dEChargeCGS*dC;
                aJFacCGS = aJFacCGS ./ (2*pi*[dDX1 dDX2 dDX3]*dLFactor);
            else
                aJFacSI  = aJFac     * dPFac*dECharge*dC;
                aJFacSI  = aJFacSI  ./ ([dDX1 dDX2 dDX3]*dLFactor);
                aJFacCGS = aJFac     * dPFac*dEChargeCGS*dC;
                aJFacCGS = aJFacCGS ./ ([dDX1 dDX2 dDX3]*dLFactor);
            end % if

            obj.Convert.Norm.JFac = aJFac;
            obj.Convert.SI.JFac   = aJFacSI;
            obj.Convert.CGS.JFac  = aJFacCGS;

        end % function

        function obj = fGetEMFVariables(obj)
            
            % Get Field Reports
            try
                cReports = obj.Input.el_mag_fld.diag_emf.reports;
            catch
                cReports = {};
            end % try
            
            % Save EMF Diagnostics
            obj.EMFields.Reports = cReports;

            % Check which potentials can be calculated from the fields
            cPot  = {};
            aMove = obj.Simulation.Moving;
            
            % w1 requires e1 to be present
            %   and either u2 to be 0 or b3 to be present
            %   and either u3 to be 0 or b2 to be present
            % w1 = f1/q = e1 + u2*b3 - u3*b2
            if (sum(ismember(cReports,'e1')) > 0) ...
                    && (aMove(2) == 0.0 || sum(ismember(cReports,'b3')) > 0) ...
                    && (aMove(3) == 0.0 || sum(ismember(cReports,'b2')) > 0)
                cPot{end+1} = 'w1';
            end % if

            % w2 requires e2 to be present
            %   and either u3 to be 0 or b1 to be present
            %   and either u1 to be 0 or b3 to be present
            % w2 = f2/q = e2 + u3*b1 - u1*b3
            if (sum(ismember(cReports,'e2')) > 0) ...
                    && (aMove(3) == 0.0 || sum(ismember(cReports,'b1')) > 0) ...
                    && (aMove(1) == 0.0 || sum(ismember(cReports,'b3')) > 0)
                cPot{end+1} = 'w2';
            end % if

            % w3 requires e3 to be present
            %   and either u1 to be 0 or b2 to be present
            %   and either u2 to be 0 or b1 to be present
            % w3 = f3/q = e3 + u1*b2 - u2*b1
            if (sum(ismember(cReports,'e3')) > 0) ...
                    && (aMove(1) == 0.0 || sum(ismember(cReports,'b2')) > 0) ...
                    && (aMove(2) == 0.0 || sum(ismember(cReports,'b1')) > 0)
                cPot{end+1} = 'w3';
            end % if
            
            % Save Potential Options
            obj.EMFields.Potentials = cPot;
            
        end % function
        
        function obj = fGetParticleVariables(obj)
            
            % Get Number of Species
            try
                iSpecies = int64(obj.Input.particles.particles.num_species{1});
            catch
                iSpecies = 0;
            end % try

            % Get Number of Cathodes
            try
                iCathode = int64(obj.Input.particles.particles.num_cathode{1});
            catch
                iCathode = 0;
            end % try
            
            % Get Number of Neutrals
            try
                iNeutral = int64(obj.Input.particles.particles.num_neutral{1});
            catch
                iNeutral = 0;
            end % try

            % Get Number of Neutrals
            try
                iNMovIons = int64(obj.Input.particles.particles.num_neutral_mov_ions{1});
            catch
                iNMovIons = 0;
            end % try
            
            % Save Particle Values
            obj.Particles.NSpecies        = iSpecies;
            obj.Particles.NCathode        = iCathode;
            obj.Particles.NNeutral        = iNeutral;
            obj.Particles.NNeutralMovIons = iNMovIons;
            
            %
            % Loop All Particles
            %
            
            % Build Particle List
            cPart = {};
            aType = [];
            for p=1:iSpecies
                cPart = [cPart {sprintf('species_%d',p)}];
                aType = [aType 1];
            end % for
            for p=1:iCathode
                cPart = [cPart {sprintf('cathode_%d',p)}];
                aType = [aType 2];
            end % for
            for p=1:iNeutral
                cPart = [cPart {sprintf('neutral_%d',p)}];
                aType = [aType 3];
            end % for
            for p=1:iNMovIons
                cPart = [cPart {sprintf('neutral_mov_ions_%d',p)}];
                aType = [aType 4];
            end % for

            % Get Proper Names
            cType   = {'Species','Cathode','Neutral','NeutralMovIons'};
            cBeams  = {};
            cPlasma = {};
            for p=1:length(cPart)

                if aType(p) < 4
                
                    stData = obj.fGetParticleSpecies(cPart{p}, obj.Input.particles.(cPart{p}), aType(p));
                    obj.Particles.Species.(stData.Name) = stData.Data;
                    if strcmpi(stData.Data.Type,'Beam')
                        cBeams = [cBeams {stData.Name}];
                    end % if
                    if strcmpi(stData.Data.Type,'Plasma')
                        cPlasma = [cPlasma {stData.Name}];
                    end % if

                else
                    
                    stData = obj.fGetParticleSpecies(cPart{p}, obj.Input.particles.(cPart{p}).species_1, aType(p));
                    obj.Particles.Species.(stData.Name) = stData.Data;
                    if strcmpi(stData.Data.Type,'Beam')
                        cBeams = [cBeams {stData.Name}];
                    end % if
                    if strcmpi(stData.Data.Type,'Plasma')
                        cPlasma = [cPlasma {stData.Name}];
                    end % if

                    stData = obj.fGetParticleSpecies(cPart{p}, obj.Input.particles.(cPart{p}).species_2, aType(p));
                    obj.Particles.Species.(stData.Name) = stData.Data;
                    if strcmpi(stData.Data.Type,'Beam')
                        cBeams = [cBeams {stData.Name}];
                    end % if
                    if strcmpi(stData.Data.Type,'Plasma')
                        cPlasma = [cPlasma {stData.Name}];
                    end % if

                end % if

            end % for

            
            %
            % Guess Species Roles
            %
            
            obj.Particles.Beams  = cBeams;
            obj.Particles.Plasma = cPlasma;
            
            if ~isempty(cBeams)
                obj.Particles.DriveBeam = cBeams(1);
                if length(cBeams) > 1
                    obj.Particles.WitnessBeam = cBeams(2:end);
                else
                    obj.Particles.WitnessBeam = {};
                end % if
            else
                obj.Particles.DriveBeam = {};
            end % if
            if ~isempty(cPlasma)
                obj.Particles.PrimaryPlasma = cPlasma(1);
            else
                obj.Particles.PrimaryPlasma = {};
            end % if
            
            
            %
            % Extract Simulation Info From Plasma
            %
            
            if ~isempty(cPlasma)

                sPlasma    = cPlasma{1};
                stProfile  = obj.Particles.Species.(sPlasma).Profile.ProfileX1;
                dPlasmaMax = obj.Particles.Species.(sPlasma).Profile.PeakDensity;
                
                dStart = 0.0;
                dStop  = 0.0;
                for x=1:stProfile.Length
                    if stProfile.Value(x) > 0.5*dPlasmaMax
                        dStart = stProfile.Axis(x);
                        break;
                    end % if
                end % for
                for x=stProfile.Length:-1:1
                    if stProfile.Value(x) > 0.5*dPlasmaMax
                        dStop = stProfile.Axis(x);
                        break;
                    end % if
                end % for
                
            else
                
                dStart     = obj.Simulation.TMin;
                dStop      = obj.Simulation.TMax;
                dPlasmaMax = 1.0;

            end % if
            
            % Save Plasma Details
            obj.Simulation.PlasmaStart  = dStart;
            obj.Simulation.PlasmaEnd    = dStop;
            obj.Simulation.MaxPlasmaFac = dPlasmaMax;
            
            % Update Simulation Units
            obj.Simulation.PhysN0       = obj.Simulation.N0 * dPlasmaMax;
            obj.Simulation.PhysOmegaP   = obj.Simulation.OmegaP * sqrt(dPlasmaMax);
            obj.Simulation.PhysLambdaP  = obj.Simulation.LambdaP / sqrt(dPlasmaMax);

        end % function
        
        function stReturn = fGetParticleSpecies(obj, sRawName, stData, iType)
            
            stReturn = {};
            iMoving  = 0; % 1 for moving particles in x1 direction
            cType    = {'Species','Cathode','Neutral','NeutralMovIons'};

            % Species Name
            try
                sName = stData.species.name{1};
            catch
                sName = sRawName;
            end % try

            vSpecies = obj.Translate.Lookup(sName);
            sPName   = vSpecies.Name;
            sPName   = strrep(sPName,' ','_');
            sPName   = strrep(sPName,'-','_');

            % Species Type
            sSpeciesType = 'Unknown';
            if vSpecies.isBeam
                sSpeciesType = 'Beam';
            end % if
            if vSpecies.isPlasma
                sSpeciesType = 'Plasma';
            end % if

            % Species Mass/Charge
            try
                dRQM = double(stData.species.rqm{1});
            catch
                dRQM = 0.0;
            end % try

            % Return Variables
            stReturn.Name       = sPName;
            stReturn.Data.Name  = sName;
            stReturn.Data.Type  = sSpeciesType;
            stReturn.Data.Class = cType{iType};
            stReturn.Data.RQM   = dRQM;
            

            %
            % Species UDist
            %
            
            % Only for Species and Catode
            if iType == 1 || iType == 2
                
                % Thermal Spread
                try
                    aUth = double(cell2mat(stData.udist.uth));
                catch
                    aUth = [0.0];
                end % try
                aUth = obj.fArrayPad(aUth, [0.0 0.0 0.0]);

                % Flow
                try
                    aUfl = double(cell2mat(stData.udist.ufl));
                catch
                    aUfl = [0.0];
                end % try
                aUfl = obj.fArrayPad(aUfl, [0.0 0.0 0.0]);
                if aUfl(1) > 0.0
                    iMoving = 1;
                end % if

                % Return Variables
                stReturn.Data.Thermal  = aUth;
                stReturn.Data.Momentum = aUfl;
                
            end % if

            
            %
            % Species Diagnostic
            %

            % Raw Fraction
            try
                dRawFrac = double(stData.diag_species.raw_fraction{1});
            catch
                dRawFrac = 0.0;
            end % try

            % PhaseSpace XMin
            try
                aDiagXMin = double(cell2mat(stData.diag_species.ps_xmin));
            catch
                aDiagXMin = [0.0];
            end % try
            aDiagXMin = obj.fArrayPad(aDiagXMin, [0.0 0.0 0.0]);

            % PhaseSpace XMax
            try
                aDiagXMax = double(cell2mat(stData.diag_species.ps_xmax));
            catch
                aDiagXMax = [0.0];
            end % try
            aDiagXMax = obj.fArrayPad(aDiagXMax, [0.0 0.0 0.0]);

            % PhaseSpace NX
            try
                aDiagNX = int64(cell2mat(stData.diag_species.ps_nx));
            catch
                aDiagNX = [0];
            end % try
            aDiagNX = obj.fArrayPad(aDiagNX, [0 0 0]);

            % PhaseSpace PMin
            try
                aDiagPMin = double(cell2mat(stData.diag_species.ps_pmin));
            catch
                aDiagPMin = [0.0];
            end % try
            aDiagPMin = obj.fArrayPad(aDiagPMin, [0.0 0.0 0.0]);

            % PhaseSpace PMax
            try
                aDiagPMax = double(cell2mat(stData.diag_species.ps_pmax));
            catch
                aDiagPMax = [0.0];
            end % try
            aDiagPMax = obj.fArrayPad(aDiagPMax, [0.0 0.0 0.0]);

            % PhaseSpace NP
            try
                aDiagNP = int64(cell2mat(stData.diag_species.ps_np));
            catch
                aDiagNP = [0];
            end % try
            aDiagNP = obj.fArrayPad(aDiagNP, [0 0 0]);
            
            % PhaseSpace LMin
            try
                aDiagLMin = double(cell2mat(stData.diag_species.ps_lmin));
            catch
                aDiagLMin = [0.0];
            end % try
            aDiagLMin = obj.fArrayPad(aDiagLMin, [0.0 0.0 0.0]);

            % PhaseSpace LMax
            try
                aDiagLMax = double(cell2mat(stData.diag_species.ps_lmax));
            catch
                aDiagLMax = [0.0];
            end % try
            aDiagLMax = obj.fArrayPad(aDiagLMax, [0.0 0.0 0.0]);

            % PhaseSpace NL
            try
                aDiagNL = int64(cell2mat(stData.diag_species.ps_nl));
            catch
                aDiagNL = [0];
            end % try
            aDiagNL = obj.fArrayPad(aDiagNL, [0 0 0]);
            
            % PhaseSpace Gamma Min
            try
                dDiagGMin = double(stData.diag_species.ps_gammamin{1});
            catch
                dDiagGMin = 0.0;
            end % try

            % PhaseSpace Gamma Max
            try
                dDiagGMax = double(stData.diag_species.ps_gammamax{1});
            catch
                dDiagGMax = 0.0;
            end % try

            % PhaseSpace NGamma
            try
                iDiagNG = int64(stData.diag_species.ps_ngamma{1});
            catch
                iDiagNG = 0;
            end % try

            % PhaseSpaces
            try
                cPhaseSpaces = obj.Translate.EvalPhaseSpace(stData.diag_species.phasespaces);
            catch
                cPhaseSpaces = {};
            end % try
            
            % Reports
            try
                cReports = stData.diag_species.reports;
            catch
                cReports = {};
            end % try
            
            % Reports, UDist
            try
                cRepUDist = stData.diag_species.rep_udist;
            catch
                cRepUDist = {};
            end % try
            
            % Return Variables
            stReturn.Data.RawFraction  = dRawFrac;
            stReturn.Data.DiagXMin     = aDiagXMin;
            stReturn.Data.DiagXMax     = aDiagXMax;
            stReturn.Data.DiagNX       = aDiagNX;
            stReturn.Data.DiagPMin     = aDiagPMin;
            stReturn.Data.DiagPMax     = aDiagPMax;
            stReturn.Data.DiagNP       = aDiagNP;
            stReturn.Data.DiagLMin     = aDiagLMin;
            stReturn.Data.DiagLMax     = aDiagLMax;
            stReturn.Data.DiagNL       = aDiagNL;
            stReturn.Data.DiagGammaMin = dDiagGMin;
            stReturn.Data.DiagGammaMax = dDiagGMax;
            stReturn.Data.DiagNGamma   = iDiagNG;
            stReturn.Data.DiagReports  = cReports;
            stReturn.Data.DiagUDist    = cRepUDist;
            stReturn.Data.PhaseSpaces  = cPhaseSpaces;


            %
            % Species Profile
            %
            
            % Only for Species, Neutral and NeutralMovIons
            if iType == 1 || iType == 3 || iType == 4
                
                stProfile = obj.fGetSpeciesProfile(stData,iMoving);
                stReturn.Data.Profile = stProfile;
                
            end % if
            
            % Set Species Type if Still Unknown
            if strcmpi(sSpeciesType,'Unknown')
                if iMoving
                    stReturn.Data.Type = 'Beam';
                else
                    stReturn.Data.Type = 'Plasma';
                end % if
            end % if
            
        end % function
        
        function stReturn = fGetSpeciesProfile(obj, stData, iMov)
            
            stReturn = {};
            
            % Variables
            iDim  = obj.Simulation.Dimensions;
            dTMin = obj.Simulation.TMin;
            dTMax = obj.Simulation.TMax;
            aXMin = obj.Simulation.XMin;
            aXMax = obj.Simulation.XMax;
            aGrid = obj.Simulation.Grid;

            % Profile Size
            try
                iNumX = int64(stData.profile.num_x{1});
            catch
                iNumX = -1;
            end % try

            % Density
            try
                dDensity = double(stData.profile.density{1});
            catch
                dDensity = 1.0;
            end % try

            % Profile Type
            try
                cType = stData.profile.profile_type;
            catch
                cType = {};
            end % try
            
            sTypeAll = '';
            sTypeX1  = '';
            sTypeX2  = '';
            sTypeX3  = '';
            if isempty(cType)
                if iNumX > 0
                    sTypeX1 = 'piecewise-linear';
                    sTypeX2 = 'piecewise-linear';
                    if iDim > 2
                        sTypeX3 = 'piecewise-linear';
                    end % if
                else
                    sTypeAll = 'uniform';
                end % if
            else
                switch(length(cType))
                    case 1
                        sTypeAll = cType{1};
                    case 2
                        sTypeX1 = cType{1};
                        sTypeX2 = cType{2};
                    case 3
                        sTypeX1 = cType{1};
                        sTypeX2 = cType{2};
                        sTypeX3 = cType{3};
                end % switch
            end % if
            
            % Return Variables
            stReturn.TypeAll = sTypeAll;
            stReturn.TypeX1  = sTypeX1;
            stReturn.TypeX2  = sTypeX2;
            stReturn.TypeX3  = sTypeX3;
            stReturn.NumX    = iNumX;
            stReturn.Density = dDensity;
            

            %
            % Calculate Profile Slice for Each Dimension
            %
            
            stProfile(3).Axis   = [];
            stProfile(3).Value  = [];
            stProfile(3).Delta  = [];
            stProfile(3).Length = [];
            dDeltaCorr          = 1.0;
            
            for d=1:iDim
            
                % Determine Limits
                if iMov || d > 1
                    dMin = aXMin(d);
                    dMax = aXMax(d);
                    iN   = aGrid(d);
                else
                    dMin = dTMin;
                    dMax = dTMax;
                    iN   = floor(dMax-dMin);
                end % if

                % Set Minimum Resolution
                %if iN < 1000
                %    dDeltaCorr = dDeltaCorr * iN/1000;
                %    iN = 1000;
                %end % if

                % Make Profile Array
                stProfile(d).Axis   = linspace(dMin,dMax,iN+1);
                stProfile(d).Value  = zeros(1,iN+1);
                stProfile(d).Delta  = (dMax-dMin)/iN;
                stProfile(d).Length = iN+1;

            end % for

            dPeak   = dDensity;
            dCharge = 0.0;
            
            % With Type Set for Each Dimension

            if isempty(sTypeAll)

                for d=1:iDim

                    % Determine Type
                    switch(d)
                        case 1; sType = sTypeX1;
                        case 2; sType = sTypeX2;
                        case 3; sType = sTypeX3;
                    end % switch

                    % Make Profiles
                    switch(sType)

                        case 'gaussian'
                            fprintf(2,'Gaussian particle profile calculations not implemented.\n');

                        case 'piecewise-linear'
                            
                            % Get Profile Vectors
                            try
                                aX = double(cell2mat(stData.profile.x(:,d)));
                            catch
                                aX = zeros(iNumX,1);
                            end % try
                            try
                                aFX = double(cell2mat(stData.profile.fx(:,d)));
                            catch
                                aFX = zeros(iNumX,1);
                            end % try
                            
                            bErr = 0;
                            if length(aX)  ~= length(aFX); bErr = 1; end % if
                            if length(aX)  ~= iNumX;       bErr = 1; end % if
                            if length(aFX) ~= iNumX;       bErr = 1; end % if
                            
                            if bErr
                                fprintf(2,'Error: x, fx, num_x and dimensions do not match in input file.\n');
                                continue;
                            end % if
                            
                            aX = floor(aX/stProfile(d).Delta);
                            for n=1:iNumX-1
                                iA = aX(n)+1; iB = aX(n+1)+1; iC = iB-iA+1;
                                stProfile(d).Value(iA:iB) = linspace(aFX(n),aFX(n+1),iC);
                            end % for
                            
                            dPeak = dPeak * max(stProfile(d).Value);

                    end % switch

                end % if

            end % for
                    
            % Common Profile Types

            switch(sTypeAll)

                case 'uniform'
                    stProfile(1).Value = ones(1,stProfile(1).Length);
                    stProfile(2).Value = ones(1,stProfile(2).Length);
                    stProfile(3).Value = ones(1,stProfile(3).Length);

                case 'channel'
                    fprintf(2,'Channel particle profile calculations not implemented.\n');

                case 'sphere'
                    fprintf(2,'Spherical particle profile calculations not implemented.\n');

                case 'math func'

                    % Get Math Function
                    try
                        sFunction = stData.profile.math_func_expr{1};
                    catch
                        sFunction = '';
                    end % try

                    if ~isempty(sFunction)

                        oMathFunc = MathFunc(sFunction);

                        if iDim > 2
                            mTemp = oMathFunc.Eval(stProfile(1).Axis,stProfile(2).Axis,[0]);
                            mTemp = mTemp.*(mTemp > 0);
                            stProfile(1).Value = sum(mTemp,1);
                            stProfile(2).Value = sum(mTemp,2)';
                            aTemp = mTemp;

                            mTemp = oMathFunc.Eval(stProfile(1).Axis,[0],stProfile(3).Axis);
                            mTemp = mTemp.*(mTemp > 0);
                            stProfile(3).Value = squeeze(sum(mTemp,2))';
                            aTemp   = squeeze(sum(mTemp,3)).*squeeze(sum(aTemp,1));
                            dCharge = sum(aTemp(:))*dDeltaCorr;
                        else
                            mTemp = oMathFunc.Eval(stProfile(1).Axis,stProfile(2).Axis,[0]);
                            mTemp = mTemp.*(mTemp > 0);
                            stProfile(1).Value = sum(mTemp,1);
                            stProfile(2).Value = sum(mTemp,2)';
                            if obj.Simulation.Cylindrical
                                aRVec   = stProfile(2).Axis; % + 0.5*stProfile(2).Delta;
                                aTemp   = bsxfun(@times,mTemp,aRVec');
                                dCharge = sum(aTemp(:))*dDeltaCorr;
                            else
                                % This calculation has not been checked, but it sums all elements
                                % down on x1 axis and squares them before doing another sum.
                                aTemp   = sum(mTemp,1).^2;
                                dCharge = sum(aTemp(:))*dDeltaCorr;
                            end % if
                        end % if

                        dPeak = dPeak * max(mTemp(:));

                    end % if

            end % switch

            % Save Profile Lineouts
            stReturn.ProfileX1   = stProfile(1);
            stReturn.ProfileX2   = stProfile(2);
            stReturn.ProfileX3   = stProfile(3);
            stReturn.PeakDensity = dPeak;
            stReturn.Charge      = dCharge*dDensity;
            
        end % function

    end % methods
    
end % classdef
