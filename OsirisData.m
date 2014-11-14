%
%  Class Object to hold Osiris data
% **********************************
%  Version 0.6
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
                            fprintf('%02.d => %s\n', length(obj.DefaultData), stDir(i).name);
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

        function List(obj)

            sPrev  = '';

            for d = 1:length(obj.DefaultData)

                aPath = strsplit(obj.DefaultData{d}, '/');
                sPath = strjoin(aPath(1:end-1), '/');
                
                if ~strcmp(sPrev, sPath)
                    fprintf('Listing %s\n',sPath);
                    sPrev = sPath;
                end % if
                
                fprintf('%02.d => %s\n', d, aPath{end});

            end % for

        end % function
        
        function Reload(obj)
            
            obj.PathID = obj.PathID;
            
        end % function
        
        function Info(obj)
            
            %
            %  Prints basic simulation info extracted from Config object
            % ***********************************************************
            %

            dTMax     = obj.Config.Variables.Simulation.TMax;
            dTimeStep = obj.Config.Variables.Simulation.TimeStep;
            dNDump    = obj.Config.Variables.Simulation.NDump;

            fprintf('\n');
            fprintf(' Dataset Info\n');
            fprintf('**************\n');
            fprintf('\n');
            fprintf('Name:      %s\n', obj.Config.Name);
            fprintf('Path:      %s\n', obj.Config.Path);
            fprintf('Last Dump: %d\n', floor(dTMax/dTimeStep/dNDump));
            fprintf('\n');

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
            fprintf(' Plasma Start:     %8.2f between dump %03d and %03d\n', dPStart, floor(dPStart/dTFac), ceil(dPStart/dTFac));
            fprintf(' Plasma End:       %8.2f between dump %03d and %03d\n', dPEnd,   floor(dPEnd/dTFac),   ceil(dPEnd/dTFac));
            fprintf('\n');
            fprintf(' Plasma Start:     %8.2f m\n', dPStart*dLFac);
            fprintf(' Plasma End:       %8.2f m\n', dPEnd*dLFac);
            fprintf(' Plasma Length:    %8.2f m\n', (dPEnd-dPStart)*dLFac);
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

            dMeanX1   = obj.Config.Variables.Beam.(sSpecies).MeanX1;
            dMeanX2   = obj.Config.Variables.Beam.(sSpecies).MeanX2;
            dSigmaX1  = obj.Config.Variables.Beam.(sSpecies).SigmaX1;
            dSigmaX2  = obj.Config.Variables.Beam.(sSpecies).SigmaX2;
            
            fprintf('\n');
            fprintf(' Beam Info for %s\n',sSpecies);
            fprintf('************************************\n');
            fprintf('\n');

            stInt = fExtractEq(sMathFunc, iDim, [dX1Min,dX1Max,dX2Min,dX2Max,dX3Min,dX3Max]);
            
            if strcmpi(sCoords, 'cylindrical')

                %sFunction = sprintf('%s.*%s.*x2', stInt.Equations{1}, stInt.Equations{2});
                sFunction = sprintf('%s.*x2', stInt.ForEval);
                fprintf(' Density Function:       %s\n',           stInt.Equation);
                fprintf(' X1 Mean, Sigma:         %7.2f, %9.4f\n', dMeanX1, dSigmaX1);
                fprintf(' X2 Mean, Sigma:         %7.2f, %9.4f\n', dMeanX2, dSigmaX2);
                fprintf('\n');
                
                fInt         = @(x1,x2) eval(sFunction);
                dBeamInt     = 2*pi*quad2d(fInt,stInt.Lims(1),stInt.Lims(2),0,stInt.Lims(4),'MaxFunEvals',15000,'Abstol',1e-3);
                
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

        function aReturn = Data(obj, iTime, sVal1, sVal2, sVal3)
            
            %
            %  Data-extraction function
            % **************************
            %
            %  Input Option 1:
            % =================
            %  iTime    :: Time dump to extract
            %  sType    :: Data type [DENSITY, FLD, PHA, RAW]
            %  sSet     :: Data set i.e. charge, x1p1, etc
            %  sSpecies :: Particle species
            %
            %  Input Option 2:
            % =================
            %  iTime    :: Time dump to extract
            %  oEPath   :: object.Elements path
            %  
            
            aReturn = [];

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
                return;
            end % if
            
            if nargin > 3

                sType     = upper(sVal1); % Type is always upper case
                sSet      = lower(sVal2); % Set is always lower case
                sSpecies  = fTranslateSpecies(sVal3);

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
                    case 'TRACKS'
                        sFolder = '';
                        sFile   = strcat(sSpecies, '-', lower(sType), '.h5');
                        iFiles  = obj.Elements.(sType).Info.Files;
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
                    case 'TRACKS'
                        sFolder = '';
                        sFile   = strcat(aPath(3), '-', lower(aPath(2)), '.h5');
                end % switch

            end % if
            
            if iTime >= iFiles && ~strcmpi(sType, 'TRACKS')
                fprintf(2, 'Error: Dump %d does not exist. Last dump is %d.\n', iTime, iFiles-1);
                return;
            end % if
            
            sLoad = strcat(sDataRoot, sFolder, sFile);
            
            if strcmpi(sType, 'RAW') || strcmpi(sType, 'TRACKS')

                if strcmpi(sType, 'RAW')
                    sGroup = '/';
                else
                    sGroup = strcat('/', sSet, '/');
                end % if
                
                h5Info = h5info(sLoad, sGroup);

                % Check if 3rd dimension exists
                bX3 = false;
                for i=1:length(h5Info.Datasets)
                    if strcmp(h5Info.Datasets(i).Name, [sGroup, 'x3'])
                        bX3 = true;
                    end % if
                end % for

                aCol1 = h5read(sLoad, [sGroup, 'x1']);
                aCol2 = h5read(sLoad, [sGroup, 'x2']);
                if bX3
                    aCol3 = h5read(sLoad, [sGroup, 'x3']);
                else
                    aCol3 = zeros(length(aCol1),1);
                end % if
                aCol4 = h5read(sLoad, [sGroup, 'p1']);
                aCol5 = h5read(sLoad, [sGroup, 'p2']);
                aCol6 = h5read(sLoad, [sGroup, 'p3']);
                aCol7 = h5read(sLoad, [sGroup, 'ene']);
                aCol8 = h5read(sLoad, [sGroup, 'q']);
                if strcmpi(sType, 'RAW')
                    aCol9 = h5read(sLoad, [sGroup, 'tag']);
                    aCol9 = double(transpose(aCol9));
                else
                    aCol9 = h5read(sLoad, [sGroup, 'n']);
                    aCol9 = double(aCol9);
                end % if
                aReturn = [aCol1 aCol2 aCol3 aCol4 aCol5 aCol6 aCol7 aCol8 aCol9];

            else

                aReturn = h5read(sLoad, strcat('/', sSet));
            
            end % if
            
        end % function
        
        function stReturn = ExportTags(obj, sTime, sSpecies, varargin)
            
            stReturn = {};

            sSpecies = fTranslateSpecies(sSpecies);
            iTime    = fStringToDump(obj, num2str(sTime));

            dBoxX1Min = obj.Config.Variables.Simulation.BoxX1Min;
            dBoxX1Max = obj.Config.Variables.Simulation.BoxX1Max;
            dBoxX2Min = obj.Config.Variables.Simulation.BoxX2Min;
            dBoxX2Max = obj.Config.Variables.Simulation.BoxX2Max;
            
            dTimeStep = obj.Config.Variables.Simulation.TimeStep;
            iNDump    = obj.Config.Variables.Simulation.NDump;
            dBoxStart = iTime*iNDump*dTimeStep;
            
            dLenFac   = obj.Config.Variables.Convert.SI.LengthFac;

            oOpt = inputParser;
            addParameter(oOpt, 'FileName', sprintf('%s.tags', sSpecies));
            addParameter(oOpt, 'Units',    'Norm');
            addParameter(oOpt, 'ZLim',     [dBoxX1Min dBoxX1Max]);
            addParameter(oOpt, 'RLim',     [dBoxX2Min dBoxX2Max]);
            addParameter(oOpt, 'MaxCount', 200);
            addParameter(oOpt, 'OrderBy',  'Random');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            aRaw      = obj.Data(iTime, 'RAW', '', sSpecies);
            aRaw(:,1) = aRaw(:,1)-dBoxStart;
            
            switch(lower(stOpt.Units));
                case 'm'
                    aRaw(:,1:3) = aRaw(:,1:3)*dLenFac;
                case 'cm'
                    aRaw(:,1:3) = aRaw(:,1:3)*dLenFac*1e2;
                case 'mm'
                    aRaw(:,1:3) = aRaw(:,1:3)*dLenFac*1e3;
            end % switch
            
            aRaw = aRaw(aRaw(:,1) >= stOpt.ZLim(1), :);
            aRaw = aRaw(aRaw(:,1) <= stOpt.ZLim(2), :);
            aRaw = aRaw(aRaw(:,2) >= stOpt.RLim(1), :);
            aRaw = aRaw(aRaw(:,2) <= stOpt.RLim(2), :);
        
            iCount = stOpt.MaxCount;
            if iCount > length(aRaw(:,1))
                iCount = length(aRaw(:,1));
            end % if
            
            switch(lower(stOpt.OrderBy))
                case 'random'
                    aRand = randperm(length(aRaw(:,1)));
                    aRaw  = aRaw(aRand(1:iCount),:);
            end % switch

            sFile = [obj.Path, '/', stOpt.FileName];
            oFile = fopen(sFile, 'w');
            
            fprintf(oFile, '! Number of tags\n');
            fprintf(oFile, '%010d\n', iCount);

            fprintf(oFile, '! Tag list\n');
            for i=1:iCount
                fprintf(oFile, '%010d %010d\n', aRaw(i,9), aRaw(i,10));
            end % for
            
            fclose(oFile);
            
            stReturn.Selection = aRaw;
            stReturn.File      = sFile;

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

