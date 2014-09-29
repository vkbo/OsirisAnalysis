%
%  Class Object to hold Osiris data
% **********************************
%

classdef OsirisData
    
    %
    % Public Properties
    %
    
    properties (GetAccess = 'public', SetAccess = 'public')

        Path      = ''; % Path to dataset
        PathID    = ''; % Path as ID instead of free text input
        Elements  = {}; % Struct of all datafiles in dataset ('MS/' subfolder)
        RawFields = {}; % Column labels for RAW data matrix
        Config    = []; % Content of the config files and extraction of all runtime variables

    end % properties

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')

        DefaultPath = {}; % Default data folder
        DefaultData = {}; % Data in default folder

    end % properties
    
    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisData()
            
            LocalConfig;
    
            obj.RawFields = {'x1','x2','x3','p1','p2','p3','ene','q','tag1','tag2'};
            obj.Config    = OsirisConfig();
            
            obj.DefaultPath = stFolders;
            fprintf('Scanning default data folder(s)\n');

            for f=1:length(obj.DefaultPath)
                if isdir(obj.DefaultPath{f})
                    fprintf('Scanning %s\n',obj.DefaultPath{f});
                    stDir = dir(obj.DefaultPath{f});
                    for i = 1:length(stDir)
                        if stDir(i).isdir && ~strcmp(stDir(i).name, '.') && ~strcmp(stDir(i).name, '..')
                            obj.DefaultData{end+1} = sprintf('%s/%s', obj.DefaultPath{f}, stDir(i).name);
                            fprintf('(%d) %s\n', length(obj.DefaultData), stDir(i).name);
                        end % if
                    end % for
                end % if
            end % for

        end % function

    end % methods
    
    %
    % Setters and Getters
    %

    methods
    
        function obj = set.Path(obj, sPath)
            
            %
            %  Sets obj.Path and scan data tree
            % **********************************
            %

            if ~isdir(sPath)
                return;
            end % if

            obj.Path = sPath;
            fprintf('Path is %s\n', obj.Path);
            
            % Scanning MS folder
            obj.Elements = obj.fScanFolder([obj.Path,'/MS'],'');

            % Set path in OsirisConfig object
            obj.Config.Path = obj.Path;

        end % function
        
        function obj = set.PathID(obj, iID)
            
            if iID > 0 && iID <= length(obj.DefaultData)
                obj.PathID = iID;
                obj.Path   = obj.DefaultData{iID};
            else
                fprintf(2, 'Error: Folder with ID %d is not in the list.\n', iID);
            end % if
            
        end % function

        function obj = set.Elements(obj, stElements)
            obj.Elements = stElements;
        end % function
        
    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function Info(obj)
            
            fprintf('\n');
            fprintf(' Dataset Info\n');
            fprintf('**************\n');
            fprintf('\n');
            fprintf('Name: %s\n', obj.Config.Name);
            fprintf('Path: %s\n', obj.Config.Path);
            fprintf('\n');

        end % function
        
        function Reload(obj)
            
            obj.PathID = obj.PathID;
            
        end % function
        
        function PlasmaInfo(obj)
            
            %
            %  Prints basic plasma info extracted from Config object
            % *******************************************************
            %
            
            dPStart   = obj.Config.Variables.Plasma.PlasmaStart;
            dPEnd     = obj.Config.Variables.Plasma.PlasmaEnd;
            dTFac     = obj.Config.Variables.Convert.SI.TimeFac;
            dLFac     = obj.Config.Variables.Convert.SI.LengthFac;

            dN0       = obj.Config.Variables.Plasma.N0;
            dNOmegaP  = obj.Config.Variables.Plasma.NormOmegaP;
            dMOmegaP  = obj.Config.Variables.Plasma.MaxOmegaP;
            dNLambdaP = obj.Config.Variables.Plasma.NormLambdaP;
            dMLambdaP = obj.Config.Variables.Plasma.MaxLambdaP;
            dPMax     = obj.Config.Variables.Plasma.MaxPlasmaFac;
            
            fprintf('\n');
            fprintf(' Plasma Info\n');
            fprintf('*************\n');
            fprintf('\n');
            fprintf(' Plasma Start:  %8.2f between dump %03d and %03d\n', dPStart, floor(dPStart/dTFac), ceil(dPStart/dTFac));
            fprintf(' Plasma End:    %8.2f between dump %03d and %03d\n', dPEnd,   floor(dPEnd/dTFac),   ceil(dPEnd/dTFac));
            fprintf('\n');
            fprintf(' Plasma Start:  %8.2f m\n', dPStart*dLFac);
            fprintf(' Plasma End:    %8.2f m\n', dPEnd*dLFac);
            fprintf(' Plasma Length: %8.2f m\n', (dPEnd-dPStart)*dLFac);
            fprintf('\n');
            fprintf(' Nomralised Plasma Density:    %8.2e m^-3\n', dN0);
            fprintf(' Normalised Plasma Frequency:  %8.2e s^-1\n', dNOmegaP);
            fprintf(' Normalised Plasma Skin Depth: %8.2e mm\n',   dNLambdaP*1e3);
            fprintf('\n');
            fprintf(' Peak Plasma Density:          %8.2e m^-3\n', dN0*dPMax);
            fprintf(' Peak Plasma Frequency:        %8.2e s^-1\n', dMOmegaP);
            fprintf(' Peak Plasma Skin Depth:       %8.2e mm\n',   dMLambdaP*1e3);
            fprintf('\n');
            
        end % function
        
        function BeamInfo(obj, sSpecies)
            
            %
            %  Attempts to calculate beam data
            % *********************************
            %
            
            sSpecies  = fTranslateSpecies(sSpecies);
            
            dC        = obj.Config.Variables.Constants.SpeedOfLight;
            dE        = obj.Config.Variables.Constants.ElementaryCharge;
            
            dN0       = obj.Config.Variables.Plasma.N0;
            dNOmegaP  = obj.Config.Variables.Plasma.NormOmegaP;
            dMOmegaP  = obj.Config.Variables.Plasma.MaxOmegaP;
            dPMax     = obj.Config.Variables.Plasma.MaxPlasmaFac;
            dDensity  = obj.Config.Variables.Beam.(sSpecies).Density;
            
            sMathFunc = obj.Config.Variables.Beam.(sSpecies).ProfileFunction;
            iDim      = obj.Config.Variables.Simulation.Dimensions;
            sCoords   = obj.Config.Variables.Simulation.Coordinates;
            dX1Min    = obj.Config.Variables.Simulation.BoxX1Min;
            dX1Max    = obj.Config.Variables.Simulation.BoxX1Max;
            dX2Min    = obj.Config.Variables.Simulation.BoxX2Min;
            dX2Max    = obj.Config.Variables.Simulation.BoxX2Max;
            dX3Min    = obj.Config.Variables.Simulation.BoxX3Min;
            dX3Max    = obj.Config.Variables.Simulation.BoxX3Max;
            
            fprintf('\n');
            fprintf(' Beam Info for %s\n',sSpecies);
            fprintf('************************************\n');

            stInt = fExtractEq(sMathFunc, iDim, [dX1Min,dX1Max,dX2Min,dX2Max,dX3Min,dX3Max]);
            
            if strcmpi(sCoords, 'cylindrical')

                %sFunction = sprintf('%s.*%s.*x2', stInt.Equations{1}, stInt.Equations{2});
                sFunction = sprintf('%s.*x2', stInt.Equations{4});
                %sFunction = strrep(sFunction, 'sin', 'fPosSin');
                %sFunction = strrep(sFunction, 'cos', 'fPosCos');
                fprintf(' EQ: %s\n', sFunction);
                fprintf(' X1: %d–%d\n', stInt.Lims{1}, stInt.Lims{2});
                fprintf(' X2: %d–%d\n', stInt.Lims{3}, stInt.Lims{4});
                fprintf('\n');
                
                fInt = @(x1,x2) eval(sFunction);
                dBeamInt = 2*pi*integral2(fInt,stInt.Lims{1},stInt.Lims{2},0,stInt.Lims{4});
                
                dBeamVol     = dBeamInt * dC^3/dNOmegaP^3;
                dBeamNum     = dBeamVol * dDensity * dN0;
                dBeamCharge  = dBeamNum * dE*1e9;
                dBeamDensity = dBeamNum/dBeamVol;
                dBeamPlasma  = dBeamDensity/(dN0*dPMax);
                
                fprintf(' Max Plasma Density:     %0.3e m^-3\n', dN0*dPMax);
                fprintf(' Max Plasma Frequency:   %0.3e s^-1\n', dMOmegaP);
                fprintf('\n');
                fprintf(' Beam Integral:          %0.3e \n',     dBeamInt);
                fprintf(' Beam Volume:            %0.3e m^3\n',  dBeamVol);
                fprintf(' Beam Charge:            %0.3e nC\n',   dBeamCharge);
                fprintf(' Beam Particle Count:    %0.3e \n',     dBeamNum);
                fprintf(' Beam Density:           %0.3e M^-3\n', dBeamDensity);
                fprintf('\n');
                fprintf(' Beam/Plasma Ratio:      %0.3e \n',     dBeamPlasma);

            end % if
            
            fprintf('\n');
            
        end % function

        function h5Data = Data(obj, iTime, sVal1, sVal2, sVal3)
            
            %
            %  Data-extraction function
            % **************************
            %  
            
            if nargin == 1
                
                fprintf('\n');
                fprintf(' object.Data(iTime, *)\n');
                fprintf('***********************\n');
                fprintf('\n');
                fprintf(' Input Option 1:\n');
                fprintf(' iTime    :: Time dump to extract\n');
                fprintf(' sType    :: Data type [DENSITY, FLD, PHA, RAW]\n');
                fprintf(' sSet     :: Data set i.e. charge, x1p1, etc\n');
                fprintf(' sSpecies :: Particle species\n');
                fprintf('\n');
                fprintf(' Input Option 2:\n');
                fprintf(' iTime    :: Time dump to extract\n');
                fprintf(' oEPath   :: object.Elements path\n');
                fprintf('\n');
                return;

            end % if
            
            if strcmp(obj.Path, '')
                fprintf(2, 'Error: No dataset has been loaded.\n');
                h5Data = 0;
                return;
            end % if
            
            if nargin > 3

                sType     = upper(sVal1); % Type is always upper case
                sSet      = lower(sVal2); % Set is always lower case
                sSpecies  = sVal3;

                sTimeNExt = strcat(sprintf('%06d', iTime), '.h5');
                sDataRoot = strcat(obj.Path, '/MS/', sType, '/');

                switch (sType)
                    case 'DENSITY'
                        sFolder = strcat(sSpecies, '/', sSet, '/');
                        sFile   = strcat(sSet, '-', sSpecies, '-', sTimeNExt);
                        iFiles  = obj.Elements.(sType).(sSpecies).(sSet).Info.Files;
                    case 'FLD'
                        sFolder = strcat(sSet, '/');
                        sFile   = strcat(sSet, '-', sTimeNExt);
                        iFiles  = obj.Elements.(sType).(sSet).Info.Files;
                    case 'PHA'
                        sFolder = strcat(sSet, '/', sSpecies, '/');
                        sFile   = strcat(sSet, '-', sSpecies, '-', sTimeNExt);
                        iFiles  = obj.Elements.(sType).(sSet).(sSpecies).Info.Files;
                    case 'RAW'
                        sFolder = strcat(sSpecies, '/');
                        sFile   = strcat(sType, '-', sSpecies, '-', sTimeNExt);
                        iFiles  = obj.Elements.(sType).(sSpecies).Info.Files;
                end % switch

            else
                
                aPath  = strsplit(char(sVal1.Info.Path), '/');
                iFiles = sVal1.Info.Files;
                sType  = aPath{2};
                sSet   = '';

                sTimeNExt = strcat(sprintf('%06d', iTime), '.h5');
                sDataRoot = strcat(obj.Path, '/MS/', sType, '/');

                switch (sType)
                    case 'DENSITY'
                        sFolder = strcat(aPath(3), '/', aPath(4), '/');
                        sFile   = strcat(aPath(4), '-', aPath(3), '-', sTimeNExt);
                        sSet    = aPath{4};
                    case 'FLD'
                        sFolder = strcat(aPath(3), '/');
                        sFile   = strcat(aPath(3), '-', sTimeNExt);
                        sSet    = aPath{3};
                    case 'PHA'
                        sFolder = strcat(aPath(3), '/', aPath(4), '/');
                        sFile   = strcat(aPath(3), '-', aPath(4), '-', sTimeNExt);
                        sSet    = aPath{3};
                    case 'RAW'
                        sFolder = strcat(aPath(3), '/');
                        sFile   = strcat(aPath(2), '-', aPath(3), '-', sTimeNExt);
                end % switch

            end % if
            
            h5Data = [];
            
            if iTime >= iFiles
                fprintf(2, 'Error: Dump %d does not exist. Last dump is %d.\n', iTime, iFiles-1);
                h5Data = 0;
                return;
            end % if
            
            sLoad  = char(strcat(sDataRoot, sFolder, sFile));
            %fprintf('File: %s\n', sLoad);
            
            if strcmp(sType, 'RAW')
        
                h5Info = h5info(sLoad);

                % Check if 3rd dimension exists
                bX3 = false;
                for i=1:length(h5Info.Datasets)
                    if strcmp(h5Info.Datasets(i).Name, '/x3')
                        bX3 = true;
                    end % if
                end % for
                
                aX1    = h5read(sLoad, '/x1');
                aX2    = h5read(sLoad, '/x2');
                if bX3
                    aX3 = h5read(sLoad, '/x3');
                else
                    aX3 = zeros(length(aX1),1);
                end % if
                aP1    = h5read(sLoad, '/p1');
                aP2    = h5read(sLoad, '/p2');
                aP3    = h5read(sLoad, '/p3');
                aE     = h5read(sLoad, '/ene');
                aQ     = h5read(sLoad, '/q');
                aTag   = h5read(sLoad, '/tag');
                h5Data = ([aX1, aX2, aX3, aP1, aP2, aP3, aE, aQ, double(transpose(aTag))]);

            else
                
                h5Data = h5read(sLoad, strcat('/', sSet));
            
            end % if
            
        end % function
        
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function stReturn = fScanFolder(obj, sScanRoot, sScanPath)
            
            %
            %  Recursive function that scans a folder tree
            % *********************************************
            %  sScanRoot :: Root of folder tree
            %  sScanPath :: First folder to scan from
            %               Use '' to start from sScanRoot
            %
            
            stReturn.Info = struct('Path', sScanPath, 'Dirs', 0, 'Files', 0);

            aDir     = dir(strcat(sScanRoot, sScanPath));
            iDirs    = 0;
            iFiles   = 0;

            for i=1:length(aDir)
                    
                if aDir(i).isdir && ~strcmp(aDir(i).name, '.') && ~strcmp(aDir(i).name, '..')

                    iDirs            = iDirs + 1;
                    sName            = strrep(aDir(i).name, '-', '_');
                    sNextPath        = strcat(sScanPath, '/', aDir(i).name);
                    stReturn.(sName) = obj.fScanFolder(sScanRoot, sNextPath);

                elseif ~aDir(i).isdir
                            
                    iFiles = iFiles + 1;
                            
                end % if

            end % for
            
            stReturn.Info.Dirs  = iDirs;
            stReturn.Info.Files = iFiles;
        
        end % function
        
    end % methods
    
end % classdef

