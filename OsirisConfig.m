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
            
            obj.Variables.Constants  = struct;
            obj.Variables.Simulation = struct;
            obj.Variables.Plasma     = struct;
            
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
                obj = obj.fGetSimulationVariables();
                obj = obj.fGetPlasmaVariables();
                
            end % if

        end % function
        
    end % methods
    
    %
    %  Private Methods
    %
    
    methods (Access = 'private')
        
        function obj = fGetSimulationVariables(obj)
            
            obj.Variables.Simulation.BoxLength = 680;
            obj.Variables.Simulation.BoxNZ     = 13600;
            obj.Variables.Simulation.BoxRadius = 8;
            obj.Variables.Simulation.BoxNR     = 320;
            obj.Variables.Simulation.Length    = 20000;
            
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
                dPEnd = obj.Variables.Simulation.Length;
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
