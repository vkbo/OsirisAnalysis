%
%  Class Object to hold the Osiris Config file
% *********************************************
%

classdef OsirisConfig
    
    %
    % Public Properties
    %
    
    properties (GetAccess = 'public', SetAccess = 'public')

        Path = ''; % Path to data directory
        File = ''; % Config file within data directory
        Raw  = {};

        % Variables
        Variables = struct;

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
            
            obj.Variables.Constants   = struct;
            obj.Variables.Simulation  = struct;
            obj.Variables.Plasma      = struct;
            obj.Variables.Convert.SI  = struct;
            obj.Variables.Convert.CGS = struct;
            
            % Set constants
            obj.Variables.Constants.SpeedOfLight       = 2.99792458e8;    %m/s
            obj.Variables.Constants.ElectronMass       = 9.10938291e-31;  %kg
            obj.Variables.Constants.ElementaryCharge   = 1.602176565e-19; %C
            obj.Variables.Constants.VacuumPermitivity  = 8.854187817e-12; %F/m 
            obj.Variables.Constants.VacuumPermeability = 1.2566370614e-6; %N/A^2
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
    %  Private Methods
    %
    
    methods (Access = 'private')
        
        function obj = fReadFile(obj)
            
            oFile   = fopen(strcat(obj.Path, '/', obj.File), 'r');
            sConfig = fread(oFile,'*char');
            fclose(oFile);
            
            % Remove comments and line breaks
            sConfig = regexprep(sprintf(sConfig),'\!.*?\n','\n');
            sConfig = regexprep(sprintf(sConfig),'[\n|\r]','');
            
            % Add linebreaks after curly brackets and split into struct
            sConfig = regexprep(sprintf(sConfig),'\}','\n');
            sConfig = strrep(sConfig,' ','');
            aLines  = strsplit(sConfig,'\n');
            
            aConfig = {};
            
            for i=1:length(aLines)-1
                
                sLine = aLines{i};
                
                iName   = 0;
                sName   = '';
                iComma  = 1;
                iPar    = 0;

                for c=1:length(sLine)
                    
                    if sLine(c) == '('
                        iPar = 1;
                    end % if
                    
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
                
                aBreaks(end+1) = c;
                for k=2:length(aBreaks)
                    aValue = strsplit(sLine(aBreaks(k-1)+1:aBreaks(k)),'=');
                    aConfig(end+1,1) = {sName};
                    if ~isempty(aValue)
                        aConfig(end,2) = aValue(1);
                        if length(aValue) > 1
                           aConfig(end,3) = aValue(2);
                        end % if
                    end % if
                end % for

            end % for
            
            obj.Raw = aConfig;
            
        end % function

        function sValues = fExtractVariables(obj, sType, sName, sLabel)
            
            
            
        end % function
        
        function obj = fGetSimulationVariables(obj)
            
            % From config file

            dBoxX1Min =     0.0;
            dBoxX1Max =   680.0;
            dBoxX2Min =     0.0;
            dBoxX2Max =     8.0;
            dBoxX3Min =     0.0;
            dBoxX3Max =     0.0;

            iBoxNX1   = 13600;
            iBoxNX2   =   320;
            iBoxNX3   =     0;
            
            dTMin     =     0.0;
            dTMax     = 20000.0;
                        
            dTimeStep =     0.0158;
            iNDump    =  7500;
            
            % Store variables
            
            obj.Variables.Simulation.BoxX1Min  = dBoxX1Min;
            obj.Variables.Simulation.BoxX1Max  = dBoxX1Max;
            obj.Variables.Simulation.BoxX2Min  = dBoxX2Min;
            obj.Variables.Simulation.BoxX2Max  = dBoxX2Max;
            obj.Variables.Simulation.BoxX3Min  = dBoxX3Min;
            obj.Variables.Simulation.BoxX3Max  = dBoxX3Max;

            obj.Variables.Simulation.BoxNX1    = iBoxNX1;
            obj.Variables.Simulation.BoxNX2    = iBoxNX2;
            obj.Variables.Simulation.BoxNX3    = iBoxNX3;

            obj.Variables.Simulation.TMin      = dTMin;
            obj.Variables.Simulation.TMax      = dTMax;

            obj.Variables.Simulation.TimeStep  = dTimeStep;
            obj.Variables.Simulation.NDumo     = iNDump;
            
            obj.Variables.Simulation.TimeStep  = 0.0158;
            obj.Variables.Simulation.NDump     = 7500;
            
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
            dE0       = 1e-7 * dEMass * dC^3 * dOmegaP * 4*dPi*dEpsilon0 / dECharge;

            % Setting plasma variables
            
            obj.Variables.Plasma.N0      = dN0;
            obj.Variables.Plasma.OmegaP  = dOmegaP;
            obj.Variables.Plasma.LambdaP = dLambdaP;
            obj.Variables.Plasma.E0      = dE0;
            
            % Setting plasma profile
            
            aFZ = [0.0,    0.0,    1.0,     1.0];
            aZ  = [0.0, 2720.0, 2720.1, 60000.0];
            aFR = [1.0,    1.0,    1.0,     0.0];
            aR  = [0.0,    5.0,    6.9,     7.0];
            
            dPStart = -1.0;
            dPEnd   = -1.0;
           
            for i=1:length(aFZ)
                if dPStart < 0.0
                    if aFZ(i) > 0.90
                        dPStart = aZ(i);
                    end % if
                else
                    if dPEnd < 0.0
                        if aFZ(i) < 0.1
                            dPEnd = aZ(i);
                        end % if
                    end % if
                end % if
            end % for
            
            if dPEnd < 0.0
                dPEnd = obj.Variables.Simulation.TMax;
            end % if
            
            obj.Variables.Plasma.ProfileFZ   = aFZ;
            obj.Variables.Plasma.ProfileZ    = aZ;
            obj.Variables.Plasma.ProfileFR   = aFR;
            obj.Variables.Plasma.ProfileR    = aR;
            obj.Variables.Plasma.PlasmaStart = dPStart;
            obj.Variables.Plasma.PlasmaEnd   = dPEnd;
            
            
        end % function
        
    end % methods
    
end % classdef
