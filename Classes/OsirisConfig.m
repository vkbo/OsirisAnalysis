
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
        Raw        = {};    % Matrix of config file data
        Input      = {}; % Parsed input file
        Variables  = {};    % Struct for all other variables
        Constants  = {}; % Constants
        Convert    = {}; % Unit conversion factors
        Simulation = {}; % Simulation variables
        EMFields   = {}; % Electro-magnetic field variables
        Particles  = {}; % Particle variables

    end % properties

    properties(GetAccess='private', SetAccess='private')

        Files     = {}; % Holds possible config files
        Translate = {}; % Container for Variables class
        NameLists = {}; % Container for Fortran namelists
        
    end % properties

    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisConfig()
            
% === OLD === %
            % Setting default N_0 and N_max
            
            obj.N0   = 1.0e20;
            obj.NMax = 1.0;
            
            % Initialising variable structs
            
            obj.Variables.Constants   = {};
            obj.Variables.Simulation  = {};
            obj.Variables.Fields      = {};
            obj.Variables.Species     = {};
            obj.Variables.Plasma      = {};
            obj.Variables.Beam        = {};
            obj.Variables.Convert.SI  = {};
            obj.Variables.Convert.CGS = {};
            
            % Setting constants
            Constants;
            
            % SI
            obj.Variables.Constants.SpeedOfLight        = stConstants.Nature.SpeedOfLight;
            obj.Variables.Constants.ElectronMass        = stConstants.Particles.Electron.Mass;
            obj.Variables.Constants.ElectronMassMeV     = stConstants.Particles.Electron.MassMeV;
            obj.Variables.Constants.ElectronVolt        = stConstants.Units.ElectronVolt.Mass;
            obj.Variables.Constants.ElementaryCharge    = stConstants.Nature.ElementaryCharge;
            obj.Variables.Constants.VacuumPermitivity   = stConstants.Nature.VacuumPermitivity;
            obj.Variables.Constants.VacuumPermeability  = stConstants.Nature.VacuumPermeability;

            % CGS
            obj.Variables.Constants.ElementaryChargeCGS = stConstants.Nature.ElementaryChargeCGS;
% === END === %

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

            
% === OLD === %
            % Translae Class for Variables
            obj.Translate = Variables();
% === END === %
            
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
                
                %obj = obj.fReadFile();
                %obj = obj.fScanInputDeck();

                %obj = obj.fGetSpecies();
                %obj = obj.fGetFieldVariables();
                %obj = obj.fGetPlasmaVariables();
                %obj = obj.fGetBeamVariables();
                %obj = obj.fGetFields();
                %obj = obj.fGetDensity();
                
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
            stNameLists(iNL).Parsed   = 0;

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
                        stNameLists(iNL).NameList = strtrim(sBuffer(1:end-1));
                        stNameLists(iNL).Parsed   = 0;
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

        % === OLD === %

        function obj = fReadFile(obj)
            
            % Read file
            oFile   = fopen(strcat(obj.Path, '/', obj.File), 'r');
            sConfig = fread(oFile,'*char');
            fclose(oFile);
            
            % Clean-up
            sConfig = regexprep(sprintf(sConfig),'\!.*?\n','\n'); % Removes all comments
            sConfig = regexprep(sprintf(sConfig),'\s','');        % Removes space, tab & line breaks
            aLines  = strsplit(sConfig,'}');                      % Split string for each group
            
            aConfig = {};
            
            for i=1:length(aLines)-1
                
                sLine   = aLines{i};
                iName   = 0;         % 0 for dataset name, 1 between { and }
                sName   = '';        % The dataset name
                aBreaks = [];        % Array for variable breaks
                iComma  = 1;         % Default first comma (actually start of string)
                iPar    = 0;         % 0 for outside of paranteses, 1 inside
                iString = 0;         % 0 for outside of string, 1 inside

                for c=1:length(sLine)
                    
                    % Inside/outside string
                    if sLine(c) == '"'
                        if iString
                            iString = 0;
                        else
                            iString = 1;
                        end % if
                    end % if

                    % Inside paranteses 
                    if sLine(c) == '(' && iString == 0
                        iPar = 1;
                    end % if

                    % Outside paranteses
                    if sLine(c) == ')' && iString == 0
                        iPar = 0;
                    end % if

                    % Get name of set
                    if iName == 0
                        if sLine(c) ~= '{'
                            sName = [sName,sLine(c)];
                        else
                            aBreaks = [c];
                            iName   = 1;
                            continue;
                        end % if
                    end % if
                    
                    % Figure out which commas separate variables.
                    % That is, the last one before an '='
                    if iName == 1
                        if sLine(c) == ',' && iPar == 0 && iString == 0
                            iComma = c;
                        end % if
                        if sLine(c) == '=' && iString == 0
                            if iComma > 1
                                aBreaks(end+1) = iComma;
                            end % if
                        end % if
                    end % if

                end % for
                
                % Separate labels for data, and store everything
                aBreaks(end+1) = c;
                for k=2:length(aBreaks)
  
                    sString = sLine(aBreaks(k-1)+1:aBreaks(k));
                    aSplit  = strfind(sString,'=');
                    sLabel  = 'None';
                    sValue  = '';
                    
                    if ~isempty(aSplit)
                        if aSplit(1) > 1
                            sLabel = sString(1:aSplit(1)-1);
                            sValue = sString(aSplit(1)+1:end);
                        end % if
                    end % if
                    
                    aLabel = strsplit(sLabel,'(');

                    aConfig{end+1,1} = sName;
                    aConfig(end,  2) = aLabel(1);
                    aConfig{end,  3} = 0;
                    aConfig{end,  4} = 0;
                    aConfig{end,  5} = 0;
                    
                    if length(aLabel) > 1
                        sNum1 = strrep(aLabel{2},')','');
                        aNum1 = strsplit(sNum1,':');

                        aConfig{end,3} = str2num(aNum1{1});
                        if length(aNum1) > 1
                            sNum2 = aNum1{2};
                            aNum2 = strsplit(sNum2,',');

                            aConfig{end,4} = str2num(aNum2{1});
                            if length(aNum2) > 1
                                aConfig{end,5} = str2num(aNum2{2});
                            end % if
                        end % if
                    end % if

                    if ~isempty(sValue)
                        if sValue(end) == ','
                            sValue = sValue(1:end-1);
                        end % if
                    end % if
                    aConfig{end,6} = sValue;

                end % for
    
                % Find species
                [iRows,~] = size(aConfig);
                sSpecies = '';

                for k=1:iRows

                    if strcmpi(aConfig{k,1},'species') && strcmpi(aConfig{k,2},'name')
                        sInName  = strrep(aConfig{k,6},'"','');
                        sSpecies = obj.Translate.Lookup(sInName).Name;
                        obj.Variables.Simulation.FileNames.(sSpecies) = strrep(sInName,' ','_');
                    end % if
                
                    aConfig{k,7} = sSpecies;

                end % for
                
            end % for
            
            obj.Raw = aConfig;
            
        end % function

        function sReturn = fExtractRaw(obj, sSpecies, sName, sLabel, iIndex, sDefault)
            
            if nargin < 5
                iIndex = 0;
            end % if

            if nargin < 6
                sDefault = 0;
            end % if
            
            [iRows,~] = size(obj.Raw);
            
            sReturn = sDefault;
            
            for i=1:iRows
                if   strcmpi(obj.Raw{i,1},sName)    ...
                  && strcmpi(obj.Raw{i,2},sLabel)   ...
                  && strcmpi(obj.Raw{i,7},sSpecies) ...
                  && obj.Raw{i,5} == iIndex
                    sReturn = obj.Raw{i,6};
                end % if
            end % for
            
        end % function

        function aValue = fExtractVariables(obj, sSpecies, sName, sLabel, iIndex)
            
            if nargin < 5
                iIndex = 0;
            end % if
            
            [iRows,~] = size(obj.Raw);
            
            aValue = {};
            
            for i=1:iRows
                if   strcmpi(obj.Raw{i,1},sName)    ...
                  && strcmpi(obj.Raw{i,2},sLabel)   ...
                  && strcmpi(obj.Raw{i,7},sSpecies) ...
                  && obj.Raw{i,5} == iIndex
                    aValue = strsplit(obj.Raw{i,6},',');
                end % if
            end % for
            
        end % function

        function aReturn = fExtractFixedNum(obj, sSpecies, sName, sLabel, aReturn, iIndex)
            
            if nargin < 6
                iIndex = 0;
            end % if
            
            aValue = obj.fExtractVariables(sSpecies, sName, sLabel, iIndex);
            
            if ~isempty(aValue)
                for i=1:length(aValue)
                    aReturn(i) = str2num(aValue{i});
                end % for
            end % if
            
        end % function

        function dReturn = fExtractSingle(obj, sSpecies, sName, sLabel, dReturn, iIndex)
            
            if nargin < 6
                iIndex = 0;
            end % if
            
            aValue = obj.fExtractVariables(sSpecies, sName, sLabel, iIndex);
            
            if ~isempty(aValue)
                dReturn = str2num(aValue{1});
            end % if
            
        end % function

        function aReturn = fExtractVarNum(obj, sSpecies, sName, sLabel, iIndex)
            
            if nargin < 5
                iIndex = 0;
            end % if
            
            aValue = obj.fExtractVariables(sSpecies, sName, sLabel, iIndex);
            
            aReturn = [];
            for i=1:length(aValue)
                aReturn(i) = str2num(aValue{i});
            end % for
            
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
        end % function

        % === OLD === %
        
        function obj = fGetSpecies(obj)
            
            stSpecies.Beam    = {};
            stSpecies.Plasma  = {};
            stSpecies.Species = {};

            [iRows,~] = size(obj.Raw);
            sPrev     = '';
            
            % Look for species in raw data
            for i=1:iRows
                sSpecies = obj.Raw{i,7};
                if ~strcmp(sSpecies,sPrev)
                    if obj.Translate.Lookup(sSpecies).isPlasma
                        stSpecies.Plasma{end+1,1} = sSpecies;
                    else
                        stSpecies.Beam{end+1,1} = sSpecies;
                    end % if
                    stSpecies.Species{end+1,1} = sSpecies;
                    sPrev = obj.Raw{i,7};
                end % if
            end % for

            iBeams   = length(stSpecies.Beam);
            iPlasmas = length(stSpecies.Plasma);
            
            % Assume first beam in input deck is the drive beam
            if iBeams > 0
                stSpecies.DriveBeam = stSpecies.Beam(1);
            else
                stSpecies.DriveBeam = {};
            end % if

            % Assume the rest of the beams are witness beams
            if iBeams > 1
                stSpecies.WitnessBeam = stSpecies.Beam(2:end);
            else
                stSpecies.WitnessBeam = {};
            end % if
            
            % Assume first plasma in input deck is the primary plasma
            if iPlasmas > 0
                stSpecies.PrimaryPlasma = stSpecies.Plasma(1);
            else
                stSpecies.PrimaryPlasma = {};
            end % if

            stSpecies.BeamCount        = iBeams;
            stSpecies.PlasmaCount      = iPlasmas;
            stSpecies.DriveBeamCount   = length(stSpecies.DriveBeam);
            stSpecies.WitnessBeamCount = length(stSpecies.WitnessBeam);
            
            % Write variables
            obj.Variables.Species = stSpecies;

        end % function

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

                % Species

                aValue = obj.fExtractFixedNum(sPlasma,'species','rqm',[0]);
                obj.Variables.Plasma.(sPlasma).RQM       = double(aValue(1));

                % Space output
                
                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_xmin',[0.0,0.0,0.0]);
                obj.Variables.Plasma.(sPlasma).DiagX1Min = double(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagX2Min = double(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagX3Min = double(aValue(3));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_xmax',[0.0,0.0,0.0]);
                obj.Variables.Plasma.(sPlasma).DiagX1Max = double(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagX2Max = double(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagX3Max = double(aValue(3));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_nx',[0,0,0]);
                obj.Variables.Plasma.(sPlasma).DiagNX1   = int64(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagNX2   = int64(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagNX3   = int64(aValue(3));

                % Momentum output
                
                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_pmin',[0.0,0.0,0.0]);
                obj.Variables.Plasma.(sPlasma).DiagP1Min = double(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagP2Min = double(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagP3Min = double(aValue(3));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_pmax',[0.0,0.0,0.0]);
                obj.Variables.Plasma.(sPlasma).DiagP1Max = double(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagP2Max = double(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagP3Max = double(aValue(3));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_np',[0,0,0]);
                obj.Variables.Plasma.(sPlasma).DiagNP1   = int64(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagNP2   = int64(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagNP3   = int64(aValue(3));
                
                % Angular momentum output
                
                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_lmin',[0.0,0.0,0.0]);
                obj.Variables.Plasma.(sPlasma).DiagL1Min = double(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagL2Min = double(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagL3Min = double(aValue(3));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_lmax',[0.0,0.0,0.0]);
                obj.Variables.Plasma.(sPlasma).DiagL1Max = double(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagL2Max = double(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagL3Max = double(aValue(3));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_nl',[0,0,0]);
                obj.Variables.Plasma.(sPlasma).DiagNL1   = int64(aValue(1));
                obj.Variables.Plasma.(sPlasma).DiagNL2   = int64(aValue(2));
                obj.Variables.Plasma.(sPlasma).DiagNL3   = int64(aValue(3));
                
                % Gamma output
                
                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_gammamin',[0.0]);
                obj.Variables.Plasma.(sPlasma).DiagGammaMin = double(aValue(1));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_gammamax',[0.0]);
                obj.Variables.Plasma.(sPlasma).DiagGammaMax = double(aValue(1));

                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','ps_ngamma',[0]);
                obj.Variables.Plasma.(sPlasma).DiagNGamma   = int64(aValue(1));
                
                % RAW output
                
                aValue = obj.fExtractFixedNum(sPlasma,'diag_species','raw_fraction',[0]);
                obj.Variables.Plasma.(sPlasma).RAWFraction = double(aValue(1));
                                
                % Diagnostics
                sValue = obj.fExtractRaw(sPlasma,'diag_species','phasespaces');
                sValue = strrep(sValue,'"','');
                sValue = strrep(sValue,'''','');
                cValue = strsplit(sValue,',');
                obj.Variables.Plasma.(sPlasma).PhaseSpaces = obj.Translate.EvalPhaseSpace(cValue);

            end % for
            
        end % function
        
        function obj = fGetBeamVariables(obj)
            
            % Loop through beam species
            [iRows,~] = size(obj.Variables.Species.Beam);
            
            for i=1:iRows
                
                sBeam = obj.Variables.Species.Beam{i,1};
                
                obj.Variables.Beam.(sBeam) = {};
                
                % Species

                aValue = obj.fExtractFixedNum(sBeam,'species','rqm',[0]);
                obj.Variables.Beam.(sBeam).RQM       = double(aValue(1));

                aValue = obj.fExtractFixedNum(sBeam,'udist','uth',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).Spread1   = double(aValue(1));
                obj.Variables.Beam.(sBeam).Spread2   = double(aValue(2));
                obj.Variables.Beam.(sBeam).Spread3   = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'udist','ufl',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).Momentum1 = double(aValue(1));
                obj.Variables.Beam.(sBeam).Momentum2 = double(aValue(2));
                obj.Variables.Beam.(sBeam).Momentum3 = double(aValue(3));

                % Space output
                
                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_xmin',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).DiagX1Min = double(aValue(1));
                obj.Variables.Beam.(sBeam).DiagX2Min = double(aValue(2));
                obj.Variables.Beam.(sBeam).DiagX3Min = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_xmax',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).DiagX1Max = double(aValue(1));
                obj.Variables.Beam.(sBeam).DiagX2Max = double(aValue(2));
                obj.Variables.Beam.(sBeam).DiagX3Max = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_nx',[0,0,0]);
                obj.Variables.Beam.(sBeam).DiagNX1   = int64(aValue(1));
                obj.Variables.Beam.(sBeam).DiagNX2   = int64(aValue(2));
                obj.Variables.Beam.(sBeam).DiagNX3   = int64(aValue(3));

                % Momentum output
                
                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_pmin',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).DiagP1Min = double(aValue(1));
                obj.Variables.Beam.(sBeam).DiagP2Min = double(aValue(2));
                obj.Variables.Beam.(sBeam).DiagP3Min = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_pmax',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).DiagP1Max = double(aValue(1));
                obj.Variables.Beam.(sBeam).DiagP2Max = double(aValue(2));
                obj.Variables.Beam.(sBeam).DiagP3Max = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_np',[0,0,0]);
                obj.Variables.Beam.(sBeam).DiagNP1   = int64(aValue(1));
                obj.Variables.Beam.(sBeam).DiagNP2   = int64(aValue(2));
                obj.Variables.Beam.(sBeam).DiagNP3   = int64(aValue(3));
                
                % Angular momentum output
                
                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_lmin',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).DiagL1Min = double(aValue(1));
                obj.Variables.Beam.(sBeam).DiagL2Min = double(aValue(2));
                obj.Variables.Beam.(sBeam).DiagL3Min = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_lmax',[0.0,0.0,0.0]);
                obj.Variables.Beam.(sBeam).DiagL1Max = double(aValue(1));
                obj.Variables.Beam.(sBeam).DiagL2Max = double(aValue(2));
                obj.Variables.Beam.(sBeam).DiagL3Max = double(aValue(3));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_nl',[0,0,0]);
                obj.Variables.Beam.(sBeam).DiagNL1   = int64(aValue(1));
                obj.Variables.Beam.(sBeam).DiagNL2   = int64(aValue(2));
                obj.Variables.Beam.(sBeam).DiagNL3   = int64(aValue(3));
                
                % Gamma output
                
                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_gammamin',[0.0]);
                obj.Variables.Beam.(sBeam).DiagGammaMin = double(aValue(1));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_gammamax',[0.0]);
                obj.Variables.Beam.(sBeam).DiagGammaMax = double(aValue(1));

                aValue = obj.fExtractFixedNum(sBeam,'diag_species','ps_ngamma',[0]);
                obj.Variables.Beam.(sBeam).DiagNGamma   = int64(aValue(1));

                % RAW output
                
                aValue = obj.fExtractFixedNum(sBeam,'diag_species','raw_fraction',[0]);
                obj.Variables.Beam.(sBeam).RAWFraction = double(aValue(1));
                
                % Beam profile
                
                sValue = obj.fExtractRaw(sBeam, 'profile', 'profile_type');
                obj.Variables.Beam.(sBeam).ProfileType     = strrep(sValue, '"', '');
                
                sValue = obj.fExtractRaw(sBeam, 'profile', 'math_func_expr');
                obj.Variables.Beam.(sBeam).ProfileFunction = strrep(sValue, '"', '');
                
                aValue = obj.fExtractFixedNum(sBeam,'profile','density',[0]);
                obj.Variables.Beam.(sBeam).Density         = double(aValue(1));

                % Diagnostics
                sValue = obj.fExtractRaw(sBeam,'diag_species','phasespaces');
                sValue = strrep(sValue,'"','');
                sValue = strrep(sValue,'''','');
                cValue = strsplit(sValue,',');
                obj.Variables.Beam.(sBeam).PhaseSpaces = obj.Translate.EvalPhaseSpace(cValue);
                
            end % for
            
        end % function
        
        function obj = fGetDensity(obj)
            
            stSpecies = obj.Variables.Species.Species;
            
            for s=1:length(stSpecies)

                sDensity = fExtractRaw(obj, stSpecies{s}, 'diag_species', 'reports', 0, '');

                if isempty(sDensity)
                    return;
                end % if

                sDensity = strrep(sDensity, '"', '');
                aDensity = strsplit(sDensity, ',');
                obj.Variables.Density.(stSpecies{s}).Density = aDensity;
                obj.Variables.Density.(stSpecies{s}).Charge  = {};
                obj.Variables.Density.(stSpecies{s}).Current = {};

                iQ = 1;
                iC = 1;
                for i=1:length(aDensity)
                    if strcmpi(aDensity{i}(1), 'c')
                        obj.Variables.Density.(stSpecies{s}).Charge{iQ} = aDensity{i};
                        iQ = iQ + 1;
                    end % if
                    if strcmpi(aDensity{i}(1), 'j')
                        obj.Variables.Density.(stSpecies{s}).Current{iC} = aDensity{i};
                        iC = iC + 1;
                    end % if
                end % for

            end % for
            
        end % function
        
    end % methods
    
end % classdef
