%
%  Class Object to hold the Osiris Config file
% *********************************************
%

classdef OsirisConfig
    
    %
    % Public Properties
    %
    
    properties (GetAccess = 'public', SetAccess = 'public')

        Path      = '';  % Path to data directory
        File      = '';  % Config file within data directory
        Name      = '';  % Name of the loaded dataset
        Raw       = {};  % Matrix of config file data
        Variables = {};  % Struct for all variables
        N0        = 0.0; % N0
        HasData   = 0;   % 1 if folder 'MS' exists, otherwise 0
        HasTracks = 0;   % 1 if folder 'MS/TRACKS' exists, otherwise 0
        Completed = 0;   % 1 if folder 'TIMINGS' exists, otherwise 0
        Silent    = 0;   % Set to 1 to disable command window output

    end % properties

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')

        Files = struct; % Holds possible config files
        
    end % properties

    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisConfig()
            
            % Setting default N0
            
            obj.N0 = 1.0e20;
            
            % Initialising variable structs
            
            obj.Variables.Constants   = struct;
            obj.Variables.Simulation  = struct;
            obj.Variables.Species     = struct;
            obj.Variables.Plasma      = struct;
            obj.Variables.Beam        = struct;
            obj.Variables.Convert.SI  = struct;
            obj.Variables.Convert.CGS = struct;
            
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
                        aFiles(end+1) = {aDir(i).name};
                    end % if

                end % if
            end % for
            obj.Files = aFiles;

            switch (length(aFiles))

                case 0
                    fprintf(2, 'Config file not found.\n');
                
                case 1
                    obj.File = 1;
                
                otherwise
                    fprintf('Multiple possible config files found\n');
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
                
                obj = obj.fReadFile();

                obj = obj.fGetSimulationVariables();
                obj = obj.fGetSpecies();
                obj = obj.fGetPlasmaVariables();
                obj = obj.fGetBeamVariables();
                
            end % if

        end % function
        
    end % methods
    
    %
    %  Config File Methods
    %
    
    methods (Access = 'private')
        
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
                iComma  = 1;         % Default first comma (actually start of string)
                iPar    = 0;         % 0 for outside of paranteses, 1 inside 

                for c=1:length(sLine)
                    
                    % Inside paranteses 
                    if sLine(c) == '(' 
                        iPar = 1;
                    end % if

                    % Outside paranteses
                    if sLine(c) == ')'
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
                        if sLine(c) == ',' && iPar == 0
                            iComma = c;
                        end % if
                        if sLine(c) == '='
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
                    aString = strsplit(sString,'=');
                    
                    aConfig(end+1,1) = {sName};
                    
                    if ~isempty(aString)
                        sLabel = aString{1};
                        aLabel = strsplit(sLabel,'(');

                        aConfig(end,2) = aLabel(1);
                        aConfig{end,3} = 0;
                        aConfig{end,4} = 0;
                        aConfig{end,5} = 0;
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
                            
                        if length(aString) > 1
                            sValue = aString{2};
                            if sValue(end) == ','
                                sValue = sValue(1:end-1);
                            end % if
                            aConfig{end,6} = sValue;
                        end % if
                    end % if
                end % for
    
                
                % Find species
                [iRows,~] = size(aConfig);
                sSpecies = '';

                for k=1:iRows

                    if strcmpi(aConfig{k,1},'species') && strcmpi(aConfig{k,2},'name')
                        sSpecies = strrep(aConfig{k,6},'"','');
                        sSpecies = fTranslateSpecies(sSpecies);
                    end % if
                
                    aConfig{k,7} = sSpecies;

                end % for

            end % for
            
            obj.Raw = aConfig;
            
        end % function

        function sReturn = fExtractRaw(obj, sSpecies, sName, sLabel, iIndex)
            
            if nargin < 5
                iIndex = 0;
            end % if
            
            [iRows,~] = size(obj.Raw);
            
            sReturn = '';
            
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

    %
    %  Variable Methods
    %

    methods (Access = 'private')

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
            
            stSpecies.Beam   = {};
            stSpecies.Plasma = {};

            [iRows,~] = size(obj.Raw);
            sPrev     = '';
            
            % Look for species in raw data
            for i=1:iRows
                sBeam = obj.Raw{i,7};
                if ~strcmp(sBeam,sPrev)
                    if strcmpi(sBeam(1:6), 'Plasma')
                        stSpecies.Plasma{end+1,1} = sBeam;
                    else
                        stSpecies.Beam{end+1,1} = sBeam;
                    end % if
                    sPrev = obj.Raw{i,7};
                end % if
            end % for

            iBeams = length(stSpecies.Beam);
            
            % Assume first beam in input deck is the drive beam
            if iBeams > 0
                stSpecies.DriveBeam = stSpecies.Beam(1);
            end % if

            % Assume the rest of the beams are witness beams
            if iBeams > 1
                stSpecies.WitnessBeam = stSpecies.Beam(2:end);
            end % if
            
            stSpecies.BeamCount        = iBeams;
            stSpecies.PlasmaCount      = length(stSpecies.Plasma);
            stSpecies.DriveBeamCount   = length(stSpecies.DriveBeam);
            stSpecies.WitnessBeamCount = length(stSpecies.WitnessBeam);
            
            obj.Variables.Species = stSpecies;

        end % function

        function obj = fGetPlasmaVariables(obj)
            
            % Retrieving constants

            dC          = obj.Variables.Constants.SpeedOfLight;
            dECharge    = obj.Variables.Constants.ElementaryCharge;
            dEChargeCGS = obj.Variables.Constants.ElementaryChargeCGS;
            dEMass      = obj.Variables.Constants.ElectronMass;
            dEpsilon0   = obj.Variables.Constants.VacuumPermitivity;
            dMu0        = obj.Variables.Constants.VacuumPermeability;
            

            % Calculating plasma variables

            dN0       = obj.N0;
            dOmegaP   = sqrt((dN0 * dECharge^2) / (dEMass * dEpsilon0));
            dLambdaP  = 2*pi * dC / dOmegaP;

            % Setting plasma variables
            
            obj.Variables.Plasma.N0          = dN0;
            obj.Variables.Plasma.NormOmegaP  = dOmegaP;
            obj.Variables.Plasma.NormLambdaP = dLambdaP;
            
            
            % Calculating conversion variables
            
            dSIE0    = 1e-7 * dEMass * dC^3 * dOmegaP * 4*pi*dEpsilon0 / dECharge;
            dLFactor = dC / dOmegaP;

            % Setting conversion variables
            
            obj.Variables.Convert.SI.E0        = dSIE0;
            obj.Variables.Convert.SI.LengthFac = dLFactor;


            % Charge conversion factor
            
            sCoords    = obj.Variables.Simulation.Coordinates;
            iDim       = obj.Variables.Simulation.Dimensions;
            
            dBoxNX1    = double(obj.Variables.Simulation.BoxNX1);
            dBoxNX2    = double(obj.Variables.Simulation.BoxNX2);
            dBoxNX3    = double(obj.Variables.Simulation.BoxNX3);
            
            dBoxX1Size = obj.Variables.Simulation.BoxX1Max - obj.Variables.Simulation.BoxX1Min;
            dBoxX2Size = obj.Variables.Simulation.BoxX2Max - obj.Variables.Simulation.BoxX2Min;
            dBoxX3Size = obj.Variables.Simulation.BoxX3Max - obj.Variables.Simulation.BoxX3Min;

            dQFac = 1.0;    % Factor for charge in normalised units
            dPFac = obj.N0; % Density is relative to N0
            
            % 2D cylindrical
            if iDim == 2 && strcmpi(sCoords, 'cylindrical')
                dQFac = dQFac*2*pi;               % Cylindrical factor
                dPFac = dPFac*dBoxX1Size/dBoxNX1; % Longitudinal cell size
                dPFac = dPFac*dBoxX2Size/dBoxNX2; % Radial cell size
            end % if

            dPFac = dPFac*dLFactor^3; % Convert from normalised units to unitless
            dPFac = dPFac*dQFac;      % Combine particle factor and charge factor
            
            obj.Variables.Convert.Norm.ChargeFac   = dQFac;
            obj.Variables.Convert.Norm.ParticleFac = dPFac;
            obj.Variables.Convert.SI.ChargeFac     = dPFac*dECharge;
            obj.Variables.Convert.SI.ParticleFac   = dPFac;
            obj.Variables.Convert.CGS.ChargeFac    = dPFac*dEChargeCGS;
            obj.Variables.Convert.CGS.ParticleFac  = dPFac;
            
            
            % Setting plasma profile
            
            aFX1 = obj.fExtractVarNum('PlasmaElectrons','profile','fx',1);
            aX1  = obj.fExtractVarNum('PlasmaElectrons','profile','x' ,1);
            aFX2 = obj.fExtractVarNum('PlasmaElectrons','profile','fx',2);
            aX2  = obj.fExtractVarNum('PlasmaElectrons','profile','x' ,2);
            aFX3 = obj.fExtractVarNum('PlasmaElectrons','profile','fx',3);
            aX3  = obj.fExtractVarNum('PlasmaElectrons','profile','x' ,3);
            
            dMaxFX1 = max(aFX1);
            dMaxFX2 = max(aFX2);
            dMaxFX3 = max(aFX3);

            if isempty(aFX3)
                dMaxFX3 = 0;
                aFX3    = 0;
                aX3     = 0;
            end % if

            dPStart = -1.0;
            dPEnd   = -1.0;
           
            for i=1:length(aFX1)
                if dPStart < 0.0
                    if aFX1(i) > 0.9*dMaxFX1
                        dPStart = aX1(i);
                    end % if
                else
                    if dPEnd < 0.0
                        if aFX1(i) < 0.1
                            dPEnd = aX1(i);
                        end % if
                    end % if
                end % if
            end % for
            
            if dPEnd < 0.0
                dPEnd = obj.Variables.Simulation.TMax;
            end % if
            
            if dPEnd > aX1(end)
                dPEnd = aX1(end);
            end % if
            
            obj.Variables.Plasma.ProfileFX1   = aFX1;
            obj.Variables.Plasma.ProfileX1    = aX1;
            obj.Variables.Plasma.ProfileFX2   = aFX2;
            obj.Variables.Plasma.ProfileX2    = aX2;
            obj.Variables.Plasma.ProfileFX3   = aFX3;
            obj.Variables.Plasma.ProfileX3    = aX3;

            obj.Variables.Plasma.PlasmaMaxFX1 = dMaxFX1;
            obj.Variables.Plasma.PlasmaMaxFX2 = dMaxFX2;
            obj.Variables.Plasma.PlasmaMaxFX3 = dMaxFX3;
            
            obj.Variables.Plasma.PlasmaStart  = dPStart;
            obj.Variables.Plasma.PlasmaEnd    = dPEnd;

            dPlasmaMax = dMaxFX1 * dMaxFX2;
            if dMaxFX3 > 0
                dPlasmaMax = dPlasmaMax * dMaxFX3;
            end % if
            
            obj.Variables.Plasma.MaxPlasmaFac = dPlasmaMax;
            obj.Variables.Plasma.MaxOmegaP    = dOmegaP  * sqrt(dPlasmaMax);
            obj.Variables.Plasma.MaxLambdaP   = dLambdaP / sqrt(dPlasmaMax);
            
        end % function
        
        function obj = fGetBeamVariables(obj)
            
            % Extract variables
            iDim   = obj.Variables.Simulation.Dimensions;
            dX1Min = obj.Variables.Simulation.BoxX1Min;
            dX1Max = obj.Variables.Simulation.BoxX1Max;
            dX2Min = obj.Variables.Simulation.BoxX2Min;
            dX2Max = obj.Variables.Simulation.BoxX2Max;
            dX3Min = obj.Variables.Simulation.BoxX3Min;
            dX3Max = obj.Variables.Simulation.BoxX3Max;

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
                
                % RAW output
                
                aValue = obj.fExtractFixedNum(sBeam,'diag_species','raw_fraction',[0]);
                obj.Variables.Beam.(sBeam).RAWFraction = double(aValue(1));

                % Beam profile
                
                sValue = obj.fExtractRaw(sBeam, 'profile', 'profile_type');
                obj.Variables.Beam.(sBeam).ProfileType     = strrep(sValue, '"', '');
                
                sValue = obj.fExtractRaw(sBeam, 'profile', 'math_func_expr');
                obj.Variables.Beam.(sBeam).ProfileFunction = strrep(sValue, '"', '');
                sMathFunc = strrep(sValue, '"', '');
                
                aValue = obj.fExtractFixedNum(sBeam,'profile','density',[0]);
                obj.Variables.Beam.(sBeam).Density         = double(aValue(1));
                
                % Analyse beam profile
                
                stFunc    = fExtractEq(sMathFunc, iDim, [dX1Min,dX1Max,dX2Min,dX2Max,dX3Min,dX3Max]);
                sFunction = stFunc.ForEval;
                fProfile  = @(x1,x2) eval(sFunction);

                aSpan   = linspace(stFunc.Lims(1), stFunc.Lims(2), 20000);
                aReturn = fProfile(aSpan,0);
                aReturn = aReturn.*(aReturn > 0);
                if sum(aReturn) > 0 && max(aReturn) >= 0
                    dMeanX1  = dround(wmean(aSpan, aReturn),3);
                    dSigmaX1 = dround(sqrt(var(aSpan,aReturn)),5);
                else
                    dMeanX1  = 0.0;
                    dSigmaX1 = 0.0;
                end % if

                aSpan   = linspace(-stFunc.Lims(4), stFunc.Lims(4), 10000); % Assumes cylindrical
                aReturn = fProfile(dMeanX1,aSpan);
                aReturn = aReturn.*(aReturn > 0);
                if sum(aReturn) > 0 && max(aReturn) >= 0
                    dMeanX2  = dround(wmean(aSpan, aReturn),3);
                    dSigmaX2 = dround(sqrt(var(aSpan,aReturn)),5);
                else
                    dMeanX2  = 0.0;
                    dSigmaX2 = 0.0;
                end % if

                obj.Variables.Beam.(sBeam).MeanX1  = dMeanX1;
                obj.Variables.Beam.(sBeam).MeanX2  = dMeanX2;
                obj.Variables.Beam.(sBeam).SigmaX1 = dSigmaX1;
                obj.Variables.Beam.(sBeam).SigmaX2 = dSigmaX2;
                
            end % for
            
        end % function
        
    end % methods
    
end % classdef
