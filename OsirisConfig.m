%
%  Class Object to hold the Osiris Config file
% *********************************************
%

classdef OsirisConfig
    
    %
    % Public Properties
    %
    
    properties (GetAccess = 'public', SetAccess = 'public')

        Path      = ''; % Path to data directory
        File      = ''; % Config file within data directory
        Raw       = {}; % Matrix of config file data
        Variables = {}; % Struct for all variables

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
            
            % Initialising variable structs
            
            obj.Variables.Constants   = struct;
            obj.Variables.Simulation  = struct;
            obj.Variables.Plasma      = struct;
            obj.Variables.Convert.SI  = struct;
            obj.Variables.Convert.CGS = struct;
            
            % Setting constants

            obj.Variables.Constants.SpeedOfLight       = 2.99792458e8;      %m/s
            obj.Variables.Constants.ElectronMass       = 9.10938291e-31;    %kg
            obj.Variables.Constants.ElementaryCharge   = 1.602176565e-19;   %C
            obj.Variables.Constants.VacuumPermitivity  = 8.854187817e-12;   %F/m 
            obj.Variables.Constants.VacuumPermeability = 1.2566370614e-6;   %N/A^2
            obj.Variables.Constants.PI                 = 3.141592653589793;
            obj.Variables.Constants.TwoPI              = 6.283185307179586;

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
            aFiles = {};

            aDir = dir(sPath);
            for i=1:length(aDir)
                if ~isdir(strcat(obj.Path, '/', aDir(i).name))
 
                    [~, ~, sFileExt] = fileparts(aDir(i).name);
                    
                    aExclude = {'.out','.sh','.e'};       % Files to exclude as definitely not the config file
                    aSizes   = [1024, 10240];             % Minimum, maximum size in bytes
                    
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
                    fprintf('Config file not found.\n');
                
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
                fprintf('Config file set: %s\n', obj.File);
                
                obj = obj.fReadFile();

                obj = obj.fGetSimulationVariables();
                obj = obj.fGetPlasmaVariables();
                
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
                        switch (lower(sSpecies))
                            case 'electrons'
                                sSpecies = 'PlasmaElectrons';
                            case 'proton_beam'
                                sSpecies = 'ProtonBeam';
                            case 'electron_beam'
                                sSpecies = 'ElectronBeam';
                        end % switch
                    end % if
                
                    aConfig{k,7} = sSpecies;

                end % for

            end % for
            
            obj.Raw = aConfig;
            
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
            
            aValue = obj.fExtractFixedNum('', 'grid','nx_p', [0,0,0]);
            obj.Variables.Simulation.BoxNX1    = int64(aValue(1));
            obj.Variables.Simulation.BoxNX2    = int64(aValue(2));
            obj.Variables.Simulation.BoxNX3    = int64(aValue(3));

            aValue = obj.fExtractFixedNum('', 'space','xmin', [0.0,0.0,0.0]);
            obj.Variables.Simulation.BoxX1Min  = double(aValue(1));
            obj.Variables.Simulation.BoxX2Min  = double(aValue(2));
            obj.Variables.Simulation.BoxX3Min  = double(aValue(3));

            aValue = obj.fExtractFixedNum('', 'space','xmax', [0.0,0.0,0.0]);
            obj.Variables.Simulation.BoxX1Max  = double(aValue(1));
            obj.Variables.Simulation.BoxX2Max  = double(aValue(2));
            obj.Variables.Simulation.BoxX3Max  = double(aValue(3));

            aValue = obj.fExtractFixedNum('', 'time','tmin', [0.0]);
            obj.Variables.Simulation.TMin      = double(aValue(1));

            aValue = obj.fExtractFixedNum('', 'time','tmax', [0.0]);
            obj.Variables.Simulation.TMax      = double(aValue(1));

            aValue = obj.fExtractFixedNum('', 'time_step','dt', [0.0]);
            obj.Variables.Simulation.TimeStep  = double(aValue(1));

            aValue = obj.fExtractFixedNum('', 'time_step','ndump', [0]);
            obj.Variables.Simulation.NDump     = double(aValue(1));
            
            % Extract variables

            dTimeStep = obj.Variables.Simulation.TimeStep;
            iNDump    = obj.Variables.Simulation.NDump;
            
            % Calculate scaling variables
            
            obj.Variables.Convert.SI.TimeFac   = dTimeStep*iNDump;
            
        end % function

        function obj = fGetPlasmaVariables(obj)
            
            % Retrieving constants

            dC        = obj.Variables.Constants.SpeedOfLight;
            dECharge  = obj.Variables.Constants.ElementaryCharge;
            dEMass    = obj.Variables.Constants.ElectronMass;
            dEpsilon0 = obj.Variables.Constants.VacuumPermitivity;
            dMu0      = obj.Variables.Constants.VacuumPermeability;
            dPi       = obj.Variables.Constants.PI;
            d2Pi      = obj.Variables.Constants.TwoPI;
            

            % Calculating plasma variables

            dN0       = 7e20;
            dOmegaP   = sqrt((dN0 * dECharge^2) / (dEMass * dEpsilon0));
            dLambdaP  = d2Pi * dC / dOmegaP;

            % Setting plasma variables
            
            obj.Variables.Plasma.N0      = dN0;
            obj.Variables.Plasma.OmegaP  = dOmegaP;
            obj.Variables.Plasma.LambdaP = dLambdaP;
            
            
            % Calculating conversion variables
            
            dSIE0 = 1e-7 * dEMass * dC^3 * dOmegaP * 4*dPi*dEpsilon0 / dECharge;

            % Setting conversion variables
            
            obj.Variables.Convert.SI.E0        = dSIE0;
            obj.Variables.Convert.SI.LengthFac = dC / dOmegaP;
            
            
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
            
        end % function
        
    end % methods
    
end % classdef
