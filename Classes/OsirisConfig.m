
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
    
        Name       = '';    % Name of the loaded dataset
        Raw        = {};    % Matrix of config file data
        RawTemp    = {};
        InputDeck  = {};    
        NameLists  = {};    % Container for Fortran namelists
        Variables  = {};    % Struct for all other variables
        Temp       = {};

    end % properties

    properties(GetAccess='private', SetAccess='private')

        Files     = {}; % Holds possible config files
        Translate = {}; % Container for Variables class
        
    end % properties

    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisConfig()
            
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
                    aSizes   = [1024, 10240];                % Minimum, maximum size in bytes
                    
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

                %obj = obj.fGetSimulationVariables();
                %obj = obj.fGetSpecies();
                %obj = obj.fGetFieldVariables();
                %obj = obj.fGetPlasmaVariables();
                %obj = obj.fGetBeamVariables();
                %obj = obj.fGetFields();
                %obj = obj.fGetDensity();
                
                obj = obj.fReadNameLists();
                obj.Temp = obj.fParseNameList(obj.NameLists(17).NameList);
                
            end % if

        end % function
        
    end % methods
    
    %
    %  Config File Methods
    %
    
    methods(Access='private')
        
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

        % === OLD === %

        function obj = fScanInputDeck(obj)
            
            mRaw = obj.Raw;
            [nR,~] = size(mRaw);
            
            cGroupA = {'simulation','node_conf','grid','time_step','restart','space','time', ...
                       'el_mag_fld','emf_bound','pgc','smooth','diag_emf','particles','collisions', ...
                       'species','udist','profile','spe_bound','diag_species','cathode', ...
                       'neutral','diag_neutral','neutral_mov_ions','zpulse','current', ...
                       'diag_current','antenna_array','antenna'};
            cGroupB = {'Simulation','NodeConf','Grid','TimeStep','Restart','Space','Time', ...
                       'EmField','EmfBound','PGC','Smooth','DiagEmf','Particles','Collisions', ...
                       'Species','UDist','Profile','SpeBound','DiagSpecies','Cathode', ...
                       'Neutral','DiagNeutral','NeutralMovIons','ZPulse','Current', ...
                       'DiagCurrent','AntennaArray','Antenna'};
            mapGroup = containers.Map(cGroupA,cGroupB);
            
            cParam = {'SimParam','EMFields','Particles','ZPulses','Current','Antennas'};
            iParam = 1;
            stTree = {};
            
            for r=1:nR
                if strcmpi(mRaw{r,1},'simulation') || strcmpi(mRaw{r,1},'node_conf')
                    iParam = 1;
                end % if
                if strcmpi(mRaw{r,1},'el_mag_fld') || strcmpi(mRaw{r,1},'emf_bound')
                    iParam = 2;
                end % if
                if strcmpi(mRaw{r,1},'particles')
                    iParam = 3;
                end % if
                if strcmpi(mRaw{r,1},'zpulse')
                    iParam = 4;
                end % if
                if strcmpi(mRaw{r,1},'current')
                    iParam = 5;
                end % if
                if strcmpi(mRaw{r,1},'antenna_array') || strcmpi(mRaw{r,1},'antenna')
                    iParam = 6;
                end % if
                mRaw{r,7} = cParam{iParam};
                mRaw{r,8} = mapGroup(mRaw{r,1});
            end % for
            
            obj.RawTemp   = mRaw;
            obj.InputDeck = stTree;
            
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
            iComma  = 0;
            iEqual  = 0;
            
            sOutA = '';
            sOutB = '';
            sOutC = '';
            
            iND = 1;
            stData(iND).Var = [];
            stData(iND).Val = [];

            for c=1:length(sData)
                
                sOutA = [sOutA sData(c)];
                
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
                
                % Record last comma outside of bracket and quote
                if sData(c) == ',' && ~bQuote && ~bBrack
                    iComma = c;
                    %fprintf('Comma at %d\n', iComma);
                    %sOutB = [sOutB '^'];
                else
                    %sOutB = [sOutB ' '];
                end % if
                
                % At equal, buffer before last comma is data, after is variable
                if sData(c) == '=' && ~bQuote && ~bBrack

                    if iND > 1 && iComma > 0 && iEqual > 0 && iComma > iEqual + 1
                        stData(iND-1).Val = sData(iEqual+1:iComma);
                    else
                        sVal = '';
                    end % if
                    
                    iEqual = c;
                    
                    stData(iND).Var = sData(iComma+1:iEqual-1);
                    
                    %fprintf('Equal at %d, Comma at %d, Var = %s, Val = %s\n', iEqual, iComma, sVar, sVal);
                    %sOutC = [sOutC '^'];
                    
                    iND = iND + 1;
                    
                else
                    sOutC = [sOutC ' '];
                end % if
                

            end % for

            if iND > 1 && iEqual > 0
                stData(iND-1).Val = sData(iEqual+1:end);
            end % if
            
            for i=1:iND-1
                sVar = stData(i).Var;
                sVal = stData(i).Val;
                
                if isempty(sVar) || isempty(sVal)
                    continue;
                end % if
                
                if sVal(end) == ','
                    sVal = sVal(1:end-1);
                end % if
                
                if ~isempty(strfind(sVar, '('))
                    aBrack = strfind(sVar, '(');
                    sName  = sVar(1:aBrack(1)-1);
                else
                    sName  = sVar;
                end % if
                
                if ~isempty(strfind(sVal, ''''))
                    if ~isempty(strfind(sVal, ''','''))
                        evalc(['stReturn.',sVar,'={',sVal,'}']);
                    else
                        evalc(['stReturn.',sVar,'={',sVal,'}']);
                    end % if
                else
                    evalc(['stReturn.',sVar,'=[',sVal,']']);
                end % if
                
            end % for
            
            %stReturn = stData;
            
            
            %fprintf('Buffer: %s\n', sOutA);
            %fprintf('Comma:  %s\n', sOutB);
            %fprintf('Equal:  %s\n', sOutC);
            
        end % function

    end % methods

    %
    %  Variable Methods
    %

    methods(Access = 'private')

        function obj = fGetSimulationVariables(obj)
            
            % Store variables
            
            aValue = obj.fExtractFixedNum('','grid','nx_p',[0,0,0]);
            obj.Variables.Simulation.BoxNX1      = int64(aValue(1));
            obj.Variables.Simulation.BoxNX2      = int64(aValue(2));
            obj.Variables.Simulation.BoxNX3      = int64(aValue(3));

            aValue = obj.fExtractFixedNum('','space','xmin',[0.0,0.0,0.0]);
            obj.Variables.Simulation.BoxX1Min    = double(aValue(1));
            obj.Variables.Simulation.BoxX2Min    = double(aValue(2));
            obj.Variables.Simulation.BoxX3Min    = double(aValue(3));

            aValue = obj.fExtractFixedNum('','space','xmax',[0.0,0.0,0.0]);
            obj.Variables.Simulation.BoxX1Max    = double(aValue(1));
            obj.Variables.Simulation.BoxX2Max    = double(aValue(2));
            obj.Variables.Simulation.BoxX3Max    = double(aValue(3));

            aValue = obj.fExtractFixedNum('','time','tmin',[0.0]);
            obj.Variables.Simulation.TMin        = double(aValue(1));

            aValue = obj.fExtractFixedNum('','time','tmax',[0.0]);
            obj.Variables.Simulation.TMax        = double(aValue(1));

            aValue = obj.fExtractFixedNum('','time_step','dt',[0.0]);
            obj.Variables.Simulation.TimeStep    = double(aValue(1));

            aValue = obj.fExtractFixedNum('','time_step','ndump',[0]);
            obj.Variables.Simulation.NDump       = double(aValue(1));

            aValue = obj.fExtractFixedNum('','grid','nx_p',[0]);
            obj.Variables.Simulation.Dimensions  = length(aValue);

            sValue = obj.fExtractRaw('','grid','coordinates');
            obj.Variables.Simulation.Coordinates = strrep(sValue,'"','');

            % Extract variables

            dTimeStep = obj.Variables.Simulation.TimeStep;
            iNDump    = obj.Variables.Simulation.NDump;
            
            % Calculate scaling variables
            
            obj.Variables.Convert.SI.TimeFac = dTimeStep*iNDump;
            
        end % function
        
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

        function obj = fGetFieldVariables(obj)
            
            % Retrieving constants

            dC          = obj.Variables.Constants.SpeedOfLight;
            dECharge    = obj.Variables.Constants.ElementaryCharge;
            dEChargeCGS = obj.Variables.Constants.ElementaryChargeCGS;
            dEMass      = obj.Variables.Constants.ElectronMass;
            dEpsilon0   = obj.Variables.Constants.VacuumPermitivity;
            dMu0        = obj.Variables.Constants.VacuumPermeability;
            

            % Calculating normalised plasma variables derived from N0

            dN0       = obj.N0;
            dOmegaP   = sqrt((dN0 * dECharge^2) / (dEMass * dEpsilon0));
            dLambdaP  = 2*pi * dC / dOmegaP;
            
            obj.Variables.Plasma.N0          = dN0;
            obj.Variables.Plasma.NormOmegaP  = dOmegaP;
            obj.Variables.Plasma.NormLambdaP = dLambdaP;
            
            
            % Calculating conversion variables
            
            dSIE0    = dEMass * dC^3 * dOmegaP * dMu0*dEpsilon0 / dECharge;
            dSIB0    = dEMass * dC^2 * dOmegaP * dMu0*dEpsilon0 / dECharge;
            dLFactor = dC / dOmegaP;

            % Setting conversion variables
            
            obj.Variables.Convert.SI.E0        = dSIE0;
            obj.Variables.Convert.SI.B0        = dSIB0;
            obj.Variables.Convert.SI.LengthFac = dLFactor;


            % Charge conversion factor
            
            sCoords    = obj.Variables.Simulation.Coordinates;
            iDim       = obj.Variables.Simulation.Dimensions;
            dTMin      = obj.Variables.Simulation.TMin;
            dTMax      = obj.Variables.Simulation.TMax;

            dBoxNX1    = double(obj.Variables.Simulation.BoxNX1);
            dBoxNX2    = double(obj.Variables.Simulation.BoxNX2);
            dBoxNX3    = double(obj.Variables.Simulation.BoxNX3);
            
            dBoxX1Size = obj.Variables.Simulation.BoxX1Max - obj.Variables.Simulation.BoxX1Min;
            dBoxX2Size = obj.Variables.Simulation.BoxX2Max - obj.Variables.Simulation.BoxX2Min;
            dBoxX3Size = obj.Variables.Simulation.BoxX3Max - obj.Variables.Simulation.BoxX3Min;

            dDX1 = dBoxX1Size/dBoxNX1;
            dDX2 = dBoxX2Size/dBoxNX2;
            if iDim == 2
                dDX3 = 1.0;
            else
                dDX3 = dBoxX3Size/dBoxNX3;
            end % if

            dQFac = 1.0;    % Factor for charge in normalised units
            dPFac = obj.N0; % Density is relative to N0

            % 2D cylindrical
            if strcmpi(sCoords, 'cylindrical')
                dQFac = dQFac*2*pi; % Cylindrical factor
            end % if
            dPFac = dPFac*dDX1; % Longitudinal cell size
            dPFac = dPFac*dDX2; % Radial/X cell size
            dPFac = dPFac*dDX3; % Azimuthal/Y cell size

            dPFac = dPFac*dLFactor^3; % Convert from normalised units to unitless
            dPFac = dPFac*dQFac;      % Combine particle factor and charge factor

            obj.Variables.Convert.Norm.ChargeFac   = dQFac;
            obj.Variables.Convert.Norm.ParticleFac = dPFac;
            obj.Variables.Convert.SI.ChargeFac     = dPFac*dECharge;
            obj.Variables.Convert.SI.ParticleFac   = dPFac;
            obj.Variables.Convert.CGS.ChargeFac    = dPFac*dEChargeCGS;
            obj.Variables.Convert.CGS.ParticleFac  = dPFac;

            % Current

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

            obj.Variables.Convert.Norm.J1Fac = aJFac(1);
            obj.Variables.Convert.Norm.J2Fac = aJFac(2);
            obj.Variables.Convert.Norm.J3Fac = aJFac(3);
            obj.Variables.Convert.SI.J1Fac   = aJFacSI(1);
            obj.Variables.Convert.SI.J2Fac   = aJFacSI(2);
            obj.Variables.Convert.SI.J3Fac   = aJFacSI(3);
            obj.Variables.Convert.CGS.J1Fac  = aJFacCGS(1);
            obj.Variables.Convert.CGS.J2Fac  = aJFacCGS(2);
            obj.Variables.Convert.CGS.J3Fac  = aJFacCGS(3);

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
        
        function obj = fGetFields(obj)
            
            sFields = fExtractRaw(obj, '', 'diag_emf', 'reports', 0);

            if isempty(sFields)
                return;
            end % if
            
            sFields = strrep(sFields, '"', '');
            aFields = strsplit(sFields, ',');
            obj.Variables.Fields.Field  = aFields;
            obj.Variables.Fields.EField = {};
            obj.Variables.Fields.BField = {};
            
            iE = 1;
            iB = 1;
            for i=1:length(aFields)
                if strcmpi(aFields{i}(1), 'e')
                    obj.Variables.Fields.EField{iE} = aFields{i};
                    iE = iE + 1;
                end % if
                if strcmpi(aFields{i}(1), 'b')
                    obj.Variables.Fields.BField{iB} = aFields{i};
                    iB = iB + 1;
                end % if
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
