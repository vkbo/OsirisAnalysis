
%
%  Class Object :: Holds the Osiris Config file
% **********************************************
%

classdef OsirisConfig
    
    %
    % Properties
    %
    
    properties(GetAccess='public', SetAccess='public')

        Path       = '';    % Path to data directory
        File       = '';    % Config file within data directory
        N0         = 0.0;   % N_0
        NMax       = 0.0;   % N_max
        Silent     = false; % Set to true to disable command window output
        HasData    = false; % True if folder 'MS' exists
        HasTracks  = false; % True if folder 'MS/TRACKS' exists
        Completed  = false; % True if folder 'TIMINGS' exists
        Consistent = false; % True if all data folders have the same number of files

    end % properties

    properties(GetAccess='public', SetAccess='private')
    
        Name       = ''; % Name of the loaded dataset
        Input      = {}; % Parsed input file
        Constants  = {}; % Constants
        Convert    = {}; % Unit conversion factors
        Simulation = {}; % Simulation variables
        EMFields   = {}; % Electro-magnetic field variables
        Particles  = {}; % Particle variables

    end % properties

    properties(GetAccess='private', SetAccess='private')

        Files      = {}; % Holds possible config files
        Translate  = {}; % Container for Variables class
        NameLists  = {}; % Container for Fortran namelists
        
    end % properties

    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisConfig()
            
            % Constants
            
            % SI
            obj.Constants.SpeedOfLight        =  2.99792458e8;      % m/s (exact)
            obj.Constants.ElectronMass        =  9.10938291e-31;    % kg
            obj.Constants.ElectronMassMeV     =  5.109989282e-1;    % MeV/c^2
           %obj.Constants.ElectronVolt        =  1.602176565e-19;   % J      [eV]
            obj.Constants.ElementaryCharge    =  1.602176565e-19;   % C
            obj.Constants.VacuumPermitivity   =  8.854187817e-12;   % F/m 
            obj.Constants.VacuumPermeability  =  1.2566370614e-6;   % N/A^2

            % CGS
            obj.Constants.ElementaryChargeCGS =  4.80320425e-10;    % statC

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
                    
                    aExclude = {'.out','.sh','.e', '.tags'}; % Files to exclude as definitely not the config file
                    aSizes   = [1024, 20480];                % Minimum, maximum size in bytes
                    
                    if sum(ismember(sFileExt, aExclude)) == 0 ...
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
                
            end % if

        end % function
        
    end % methods
    
    %
    %  Config File Methods
    %
    
    methods(Access='private')
        
        function obj = fReadNameLists(obj)
            
            % Read file
            oFile = fopen(strcat(obj.Path, '/', obj.File), 'r');
            sFile = sprintf(fread(oFile,'*char'));
            fclose(oFile);
            
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
            dC          = obj.Constants.SpeedOfLight;
            dECharge    = obj.Constants.ElementaryCharge;
            dEChargeCGS = obj.Constants.ElementaryChargeCGS;
            dEMass      = obj.Constants.ElectronMass;
            dEpsilon0   = obj.Constants.VacuumPermitivity;
            dMu0        = obj.Constants.VacuumPermeability;

            %
            % Main Simulation Variables
            %
            
            % Plasma Density
            try
                dN0 = double(obj.Input.simulation.simulation.n0{1})*1.0e6;
            catch
                dN0 = 1.0e20;
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
                aGrid = int64(cell2mat(obj.Input.simulation.grid.nx_p));
            catch
                aGrid = [1];
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
                iNDump = int64(obj.Input.simulation.time_step.ndump{1});
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
                aXMin = [0.0];
            end % try
            aXMin = obj.fArrayPad(aXMin, [0.0 0.0 0.0]);

            % End Box
            try
                aXMax = double(cell2mat(obj.Input.simulation.space.xmax));
            catch
                aXMax = [0.0];
            end % try
            aXMax = obj.fArrayPad(aXMax, [0.0 0.0 0.0]);

            % Save Plasma Variables for Simulation
            obj.Simulation.N0          = dN0;
            obj.Simulation.OmegaP      = dOmegaP;
            obj.Simulation.LambdaP     = dLambdaP;

            % Save Plasma Variables for Physics
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

                sType = cType{aType(p)};

                if aType(p) < 4
                
                    stData = obj.fGetParticleSpecies(cPart{p}, obj.Input.particles.(cPart{p}), aType(p));
                    obj.Particles.(sType).(stData.Name) = stData.Data;
                    if strcmpi(stData.Data.Type,'Beam')
                        cBeams = [cBeams {stData.Name}];
                    end % if
                    if strcmpi(stData.Data.Type,'Plasma')
                        cPlasma = [cPlasma {stData.Name}];
                    end % if

                else
                    
                    stData = obj.fGetParticleSpecies(cPart{p}, obj.Input.particles.(cPart{p}).species_1, aType(p));
                    obj.Particles.(sType).(stData.Name) = stData.Data;
                    if strcmpi(stData.Data.Type,'Beam')
                        cBeams = [cBeams {stData.Name}];
                    end % if
                    if strcmpi(stData.Data.Type,'Plasma')
                        cPlasma = [cPlasma {stData.Name}];
                    end % if

                    stData = obj.fGetParticleSpecies(cPart{p}, obj.Input.particles.(cPart{p}).species_2, aType(p));
                    obj.Particles.(sType).(stData.Name) = stData.Data;
                    if strcmpi(stData.Data.Type,'Beam')
                        cBeams = [cBeams {stData.Name}];
                    end % if
                    if strcmpi(stData.Data.Type,'Plasma')
                        cPlasma = [cPlasma {stData.Name}];
                    end % if

                end % if

            end % for

            obj.Particles.Beams  = cBeams;
            obj.Particles.Plasma = cPlasma;
            
            if ~isempty(cBeams)
                obj.Particles.DriveBeam = cBeams{1};
                if length(cBeams) > 1
                    obj.Particles.WitnessBeam = cBeams{2:end};
                else
                    obj.Particles.WitnessBeam = {};
                end % if
            else
                obj.Particles.DriveBeam = {};
            end % if
            
        end % function
        
        function stReturn = fGetParticleSpecies(obj, sRawName, stData, iType)
            
            stReturn = {};

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
            stReturn.Name      = sPName;
            stReturn.Data.Name = sName;
            stReturn.Data.Type = sSpeciesType;
            stReturn.Data.RQM  = dRQM;
            

            %
            % UDist
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
            stReturn.Data.PhaseSpaces  = cPhaseSpaces;

        end % function

        % === OLD === %
        
        function obj = fGetPlasmaVariables(obj)
            
            % Get variables
            
            dTMin      = obj.Variables.Simulation.TMin;
            dTMax      = obj.Variables.Simulation.TMax;
            dOmegaP    = obj.Variables.Plasma.NormOmegaP;
            dLambdaP   = obj.Variables.Plasma.NormLambdaP;

            % Extract plasma species variables
            [iRows,~] = size(obj.Variables.Species.Plasma);
            
            for i=1:iRows
                
                sPlasma    = obj.Variables.Species.Plasma{i,1};
                
                dPStart    = -1.0;
                dPEnd      = -1.0;
                dPlasmaMax =  1.0;

                obj.Variables.Plasma.(sPlasma) = {};
                
                % Extracting plasma profile
                
                sValue   = obj.fExtractRaw(sPlasma,'profile','profile_type',0,'uniform');
                sProfile = strrep(sValue, '"', '');
                iNumX    = obj.fExtractSingle(sPlasma,'profile','num_x',-1);
                
                if iNumX > 0 && strcmpi(sProfile,'uniform')
                    sProfile = 'piecewise-linear';
                end % if
                
                obj.Variables.Plasma.(sPlasma).ProfileType = sProfile;
                
                switch(sProfile)
                    
                    case 'piecewise-linear'
                        
                        % Piecewise Linear Plasma Function

                        aFX1 = obj.fExtractVarNum(sPlasma,'profile','fx',1);
                        aX1  = obj.fExtractVarNum(sPlasma,'profile','x' ,1);
                        aFX2 = obj.fExtractVarNum(sPlasma,'profile','fx',2);
                        aX2  = obj.fExtractVarNum(sPlasma,'profile','x' ,2);
                        aFX3 = obj.fExtractVarNum(sPlasma,'profile','fx',3);
                        aX3  = obj.fExtractVarNum(sPlasma,'profile','x' ,3);

                        dMaxFX1 = max(aFX1);
                        dMaxFX2 = max(aFX2);
                        dMaxFX3 = max(aFX3);

                        if isempty(aFX3)
                            dMaxFX3 = 0;
                            aFX3    = 0;
                            aX3     = 0;
                        end % if

                        iTMin = floor(dTMin);
                        iTMax = floor(dTMax);
                        iNT   = iTMax-iTMin+1;
                        aPD   = zeros(1,iNT);
                        aZ    = linspace(iTMin,iTMax,iNT);
                        iPR   = 0;
                        aReg  = zeros(1,2);
                        for j=1:length(aFX1)-1
                            iSMin = floor(aX1(j))+iTMin;
                            iSMax = floor(aX1(j+1))+iTMin;
                            iNS   = iSMax-iSMin+1;
                            aSPD  = linspace(aFX1(j),aFX1(j+1),iNS);
                            aPD(iSMin+1:iSMax+1) = aSPD;
                            if aFX1(j+1) > 0 && aFX1(j) == 0
                                iPR = iPR + 1;
                                aReg(iPR,1) = aX1(j);
                            end % if
                            if aFX1(j+1) == 0 && aFX1(j) > 0
                                aReg(iPR,2) = aX1(j);
                            end % if
                        end % for

                        if aReg(iPR,2) == 0
                            aReg(iPR,2) = aX1(end);
                        end % if

                        obj.Variables.Plasma.(sPlasma).DensityProfile = aPD;
                        obj.Variables.Plasma.(sPlasma).DensityAxis    = aZ;
                        obj.Variables.Plasma.(sPlasma).PlasmaRegions  = aReg;

                        for j=1:length(aFX1)
                            if dPStart < 0.0
                                if aFX1(j) > 0.9*dMaxFX1
                                    dPStart = aX1(j);
                                end % if
                            end % if
                        end % for

                        for j=length(aFX1):-1:1
                            if dPEnd < 0.0
                                if aFX1(j) > 0.1*dMaxFX1
                                    dPEnd = aX1(j);
                                end % if
                            end % if
                        end % for

                        if dPEnd < 0.0
                            dPEnd = obj.Variables.Simulation.TMax;
                        end % if

                        if dPEnd > aX1(end)
                            dPEnd = aX1(end);
                        end % if

                        dPlasmaMax = dMaxFX1 * dMaxFX2;
                        if dMaxFX3 > 0
                            dPlasmaMax = dPlasmaMax * dMaxFX3;
                        end % if

                        % Save Variables

                        obj.Variables.Plasma.(sPlasma).ProfileFX1   = aFX1;
                        obj.Variables.Plasma.(sPlasma).ProfileX1    = aX1;
                        obj.Variables.Plasma.(sPlasma).ProfileFX2   = aFX2;
                        obj.Variables.Plasma.(sPlasma).ProfileX2    = aX2;
                        obj.Variables.Plasma.(sPlasma).ProfileFX3   = aFX3;
                        obj.Variables.Plasma.(sPlasma).ProfileX3    = aX3;

                        obj.Variables.Plasma.(sPlasma).PlasmaMaxFX1 = dMaxFX1;
                        obj.Variables.Plasma.(sPlasma).PlasmaMaxFX2 = dMaxFX2;
                        obj.Variables.Plasma.(sPlasma).PlasmaMaxFX3 = dMaxFX3;

                    case 'mathfunc'
                        
                        % Math Plasma Function

                        sValue = obj.fExtractRaw(sPlasma,'profile','math_func_expr');
                        sFunc  = strrep(sValue, '"', '');
                        obj.Variables.Plasma.(sPlasma).ProfileFunction = sFunc;
                        
                        iTMin = floor(dTMin);
                        iTMax = floor(dTMax);
                        iNT   = iTMax-iTMin+1;
                        aZ    = linspace(iTMin,iTMax,iNT);

                        oMF = MathFunc(sFunc);
                        aPD = oMF.Eval(aZ,0,0);

                        if isempty(aPD)
                        
                            fprintf(2,'OsirisConfig Error: Cannot parse math function from input deck.\n');

                        else
                        
                            obj.Variables.Plasma.(sPlasma).DensityProfile = aPD;
                            obj.Variables.Plasma.(sPlasma).DensityAxis    = aZ;

                            dPlasmaMax = max(aPD);

                            for j=1:length(aPD)
                                if dPStart < 0.0
                                    if aPD(j) > 0.95*dPlasmaMax
                                        dPStart = aZ(j);
                                    end % if
                                end % if
                            end % for

                            for j=length(aPD):-1:1
                                if dPEnd < 0.0
                                    if aPD(j) > 0.05*dPlasmaMax
                                        dPEnd = aZ(j);
                                    end % if
                                end % if
                            end % for

                            if dPEnd < 0.0
                                dPEnd = obj.Variables.Simulation.TMax;
                            end % if

                            if dPEnd > aZ(end)
                                dPEnd = aZ(end);
                            end % if
                        end % if
                        
                    otherwise
                        
                        fprintf('OsirisConfig Warning: Unsupported species profile encountered.\n');

                end % if

                if strcmpi(obj.Variables.Species.PrimaryPlasma,sPlasma)
                    obj.Variables.Plasma.PlasmaStart  = dPStart;
                    obj.Variables.Plasma.PlasmaEnd    = dPEnd;

                    obj.Variables.Plasma.MaxPlasmaFac = dPlasmaMax;
                    obj.Variables.Plasma.MaxOmegaP    = dOmegaP  * sqrt(dPlasmaMax);
                    obj.Variables.Plasma.MaxLambdaP   = dLambdaP / sqrt(dPlasmaMax);
                end % if

            end % for
            
        end % function
        
        function obj = fGetBeamVariables(obj)
            
            % Loop through beam species
            [iRows,~] = size(obj.Variables.Species.Beam);
            
            for i=1:iRows
                
                % Beam profile
                
                sValue = obj.fExtractRaw(sBeam, 'profile', 'profile_type');
                obj.Variables.Beam.(sBeam).ProfileType     = strrep(sValue, '"', '');
                
                sValue = obj.fExtractRaw(sBeam, 'profile', 'math_func_expr');
                obj.Variables.Beam.(sBeam).ProfileFunction = strrep(sValue, '"', '');
                
                aValue = obj.fExtractFixedNum(sBeam,'profile','density',[0]);
                obj.Variables.Beam.(sBeam).Density         = double(aValue(1));
                
            end % for
            
        end % function

    end % methods
    
end % classdef
