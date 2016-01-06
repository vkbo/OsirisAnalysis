
%
%  Class Object :: Wrapper for Osiris data sets
% **********************************************
%  Version Dev1.4
%

classdef OsirisData
    
    %
    % Properties
    %
    
    properties(GetAccess='public', SetAccess='public')

        Path        = '';    % Path to dataset
        PathID      = '';    % Path as ID instead of free text input
        Config      = [];    % Content of the config files and extraction of all runtime variables
        Silent      = false; % Set to 1 to disable command window output
        RunningZ    = true;  % Uses box coordinates instead of simulation coordinates

    end % properties

    properties(GetAccess='public', SetAccess='private')

        Elements    = {};    % Struct of all datafiles in dataset ('MS/' subfolder)
        MSData      = {};    % Struct of all MS data
        DataSets    = {};    % Available datasets in folders indicated by LocalConfig.m
        DefaultPath = {};    % Default data folder
        Temp        = '';    % Temp folder (set in LocalConfig.m)
        Translate   = {};    % Tool for translating Osiris variables
        HasData     = false; % True if folder 'MS' exists
        HasTracks   = false; % True if folder 'MS/TRACKS' exists
        Completed   = false; % True if folder 'TIMINGS' exists
        Consistent  = false; % True if all data folders have the same number of files

    end % properties

    properties(GetAccess='private', SetAccess='private')

        DefaultData = {};    % Data in default folder

    end % properties
    
    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisData(varargin)
            
            % Parse input
            oOpt = inputParser;
            addParameter(oOpt, 'Silent', 'No');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            if strcmpi(stOpt.Silent, 'Yes')
                obj.Silent = true;
            end % if

            % Initiate OsirisData
            LocalConfig;
            
            obj.Temp          = sLocalTemp;
            obj.Config        = OsirisConfig;
            obj.Config.Silent = obj.Silent;
            
            obj.DefaultPath = stFolders;
            if ~obj.Silent
                fprintf('Scanning default data folder(s)\n');
            end % if
            
            stFields = fieldnames(obj.DefaultPath);

            for f=1:length(stFields)

                sName  = stFields{f};
                sPath  = obj.DefaultPath.(stFields{f}).Path;
                iDepth = obj.DefaultPath.(stFields{f}).Depth;
                
                obj.DefaultPath.(stFields{f}).Available = 0;

                if isdir(sPath)
                    
                    if ~obj.Silent
                        fprintf('Scanning %s\n', sPath);
                    end % if
                    obj.DefaultPath.(stFields{f}).Available = 1;
                    
                    stScan.(sName)(1) = struct('Path', sPath, 'Name', sName, 'Level', 0);
                    for r=0:iDepth-1
                        for p=1:length(stScan.(sName))
                            if stScan.(sName)(p).Level == r
                                stDir = dir(stScan.(sName)(p).Path);
                                for d=1:length(stDir)
                                    if stDir(d).isdir == 1 && ~strcmp(stDir(d).name, '.') && ~strcmp(stDir(d).name, '..')
                                        stScan.(sName)(end+1) = struct('Path',  [stScan.(sName)(p).Path, '/', stDir(d).name], ...
                                                                       'Name',  stDir(d).name, ...
                                                                       'Level', r+1);
                                    end % if
                                end % for
                            end % if
                        end % for
                    end % for
                    
                    for s=1:length(stScan.(sName))
                        if stScan.(sName)(s).Level == iDepth
                            sSet = structname(stScan.(sName)(s).Name);

                            obj.DataSets.ByName.(sSet).Path      = stScan.(sName)(s).Path;
                            obj.DataSets.ByName.(sSet).HasData   = isdir([stScan.(sName)(s).Path, '/MS']);
                            obj.DataSets.ByName.(sSet).HasTracks = isdir([stScan.(sName)(s).Path, '/MS/TRACKS']);
                            obj.DataSets.ByName.(sSet).Completed = isdir([stScan.(sName)(s).Path, '/TIMINGS']);

                            obj.DataSets.ByPath.(sName).(sSet).Path      = stScan.(sName)(s).Path;
                            obj.DataSets.ByPath.(sName).(sSet).HasData   = isdir([stScan.(sName)(s).Path, '/MS']);
                            obj.DataSets.ByPath.(sName).(sSet).HasTracks = isdir([stScan.(sName)(s).Path, '/MS/TRACKS']);
                            obj.DataSets.ByPath.(sName).(sSet).Completed = isdir([stScan.(sName)(s).Path, '/TIMINGS']);
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
        
        function obj = set.Path(obj, vInput)
            
            %
            %  Sets obj.Path and scans data tree
            % ***********************************
            %
            
            iHasData   = 0;
            iHasTracks = 0;
            iCompleted = 0;
            
            if isstruct(vInput)
                if isfield(vInput, 'Path')
                    obj.Path   = vInput.Path;
                    iHasData   = vInput.HasData;
                    iHasTracks = vInput.HasTracks;
                    iCompleted = vInput.Completed;
                else
                    fprintf(2, 'Error: Path not recognised or found.\n');
                    return;
                end % if
            elseif isdir(vInput)
                obj.Path   = vInput;
                iHasData   = isdir([vInput, '/MS']);
                iHasTracks = isdir([vInput, '/MS/TRACKS']);
                iCompleted = isdir([vInput, '/TIMINGS']);
            else
                sField = structname(vInput);
                if isfield(obj.DataSets.ByName, sField)
                    obj.Path   = obj.DataSets.ByName.(sField).Path;
                    iHasData   = obj.DataSets.ByName.(sField).HasData;
                    iHasTracks = obj.DataSets.ByName.(sField).HasTracks;
                    iCompleted = obj.DataSets.ByName.(sField).Completed;
                else
                    fprintf(2, 'Error: Path not recognised or found.\n');
                    return;
                end % if
            end % if

            if ~obj.Silent
                fprintf('Path is %s\n', obj.Path);
            end % if
            
            % Scanning MS folder
            obj.Elements = obj.fScanFolder([obj.Path, '/MS'], '');
            obj.MSData   = obj.fScanElements;

            % Set path in OsirisConfig object
            obj.Config.Path = obj.Path;
            obj.HasData     = iHasData;
            obj.HasTracks   = iHasTracks;
            obj.Completed   = iCompleted;
            
            if obj.MSData.MinFiles == obj.MSData.MaxFiles
               obj.Consistent = true;
            else
               obj.Consistent = false;
            end % if
            
            obj.Translate = Variables(obj.Config.Simulation.Coordinates, obj.RunningZ);
            
            % Output Dataset Info
            if ~obj.Silent
                if obj.HasData
                    fprintf('Folder contains simulation data.\n');
                end % if
                if obj.HasTracks
                    fprintf('Folder contains tracking data.\n');
                end % if
                if ~obj.Completed
                    fprintf('Simulation is incomplete.\n');
                end % if
                if ~obj.Consistent
                    fprintf('Simulation has varying number of time dumps.\n');
                end % if
            end % if

        end % function
        
        function obj = set.Elements(obj, stElements)

            obj.Elements = stElements;

        end % function
        
    end % methods
    
    %
    % Public Methods
    %
    
    methods(Access = 'public')
        
        function Version(~)
            
            fprintf('OsirisAnalysis Version Dev1.4\n');
            
        end % function
        
        function stReturn = Info(obj)
            
            %
            %  Prints basic simulation info extracted from Config object
            % ***********************************************************
            %

            stReturn  = {};

            dTMax     = obj.Config.Simulation.TMax;
            dTimeStep = obj.Config.Simulation.TimeStep;
            dNDump    = obj.Config.Simulation.NDump;

            if ~obj.Silent
                fprintf('\n');
                fprintf(' Dataset Info\n');
                fprintf('**************\n');
                fprintf('\n');
                fprintf('Name:      %s\n', obj.Config.Name);
                fprintf('Path:      %s\n', obj.Config.Path);
                fprintf('Last Dump: %d\n', floor(dTMax/dTimeStep/dNDump));
                fprintf('\n');
            end % if

            stReturn.Name     = obj.Config.Name;
            stReturn.Path     = obj.Config.Path;
            stReturn.LastDump = floor(dTMax/dTimeStep/dNDump);

        end % function
        
        function stReturn = PlasmaInfo(obj)
            
            %
            %  Prints basic plasma info extracted from Config object
            % *******************************************************
            %
            
            stReturn  = {};

            dPStart   = obj.Config.Simulation.PlasmaStart;
            dPEnd     = obj.Config.Simulation.PlasmaEnd;
            dTFac     = obj.Config.Convert.SI.TimeFac;
            dLFac     = obj.Config.Convert.SI.LengthFac;

            dN0       = obj.Config.Simulation.N0;
            dNOmegaP  = obj.Config.Simulation.OmegaP;
            dMOmegaP  = obj.Config.Simulation.PhysOmegaP;
            dNLambdaP = obj.Config.Simulation.LambdaP;
            dMLambdaP = obj.Config.Simulation.PhysLambdaP;
            dPMax     = obj.Config.Simulation.MaxPlasmaFac;
            
            if ~obj.Silent
                fprintf('\n');
                fprintf(' Plasma Info\n');
                fprintf('*************\n');
                fprintf('\n');
                fprintf(' Plasma Start:           %8.2f between dump %03d and %03d\n', dPStart, floor(dPStart/dTFac), ceil(dPStart/dTFac));
                fprintf(' Plasma End:             %8.2f between dump %03d and %03d\n', dPEnd,   floor(dPEnd/dTFac),   ceil(dPEnd/dTFac));
                fprintf('\n');
                fprintf(' Plasma Start:           %8.2f m\n', dPStart*dLFac);
                fprintf(' Plasma End:             %8.2f m\n', dPEnd*dLFac);
                fprintf(' Plasma Length:          %8.2f m\n', (dPEnd-dPStart)*dLFac);
                fprintf('\n');
                fprintf(' Plasma Density:         %8.2e m^-3\n', dN0);
                fprintf(' Plasma Frequency:       %8.2e s^-1\n', dNOmegaP);
                fprintf(' Plasma Skin Depth:      %8.2e mm\n',   dNLambdaP*1e3);
                fprintf('\n');
                fprintf(' Peak Plasma Density:    %8.2e m^-3\n', dN0*dPMax);
                fprintf(' Peak Plasma Frequency:  %8.2e s^-1\n', dMOmegaP);
                fprintf(' Peak Plasma Skin Depth: %8.2e mm\n',   dMLambdaP*1e3);
                fprintf('\n');
            end % if
            
            stReturn.Start.ZPos     = dPStart*dLFac;
            stReturn.Start.Dump     = dPStart;
            stReturn.Start.Between  = [floor(dPStart/dTFac) ceil(dPStart/dTFac)];
            stReturn.End.ZPos       = dPEnd*dLFac;
            stReturn.End.Dump       = dPEnd;
            stReturn.End.Between    = [floor(dPEnd/dTFac) ceil(dPEnd/dTFac)];
            stReturn.Density.Norm   = dN0;
            stReturn.Density.Peak   = dN0*dPMax;
            stReturn.Frequency.Norm = dNOmegaP;
            stReturn.Frequency.Peak = dMOmegaP;
            stReturn.SkinDepth.Norm = dNLambdaP;
            stReturn.SkinDepth.Peak = dMLambdaP;

        end % function
        
        function stReturn = BeamInfo(obj, sSpecies)
            
            %
            %  Attempts to Calculate Beam Info
            % *********************************
            %
            
            stReturn = {};
            sSpecies = obj.Translate.Lookup(sSpecies,'Beam').Name;
            
            iDim     = obj.Config.Simulation.Dimensions;
            dLFac    = obj.Config.Convert.SI.LengthFac;
            dQFac    = obj.Config.Convert.SI.ChargeFac;
            dPFac    = obj.Config.Convert.SI.ParticleFac;
            dCharge  = obj.Config.Particles.Species.(sSpecies).Profile.Charge;
            
            if ~obj.Silent
                fprintf('\n');
                fprintf(' Beam Info for %s\n',sSpecies);
                fprintf('************************************\n');
                fprintf('\n');
            end % if

            %
            % Sigma and Mean
            %

            try
                aAxis    = obj.Config.Particles.Species.(sSpecies).Profile.ProfileX1.Axis;
                aData    = obj.Config.Particles.Species.(sSpecies).Profile.ProfileX1.Value;
                oFit     = fit(double(aAxis)',double(aData)','Gauss1');
                dMeanX1  = oFit.b1;
                dSigmaX1 = oFit.c1/sqrt(2);
            catch
                dMeanX1  = 0.0;
                dSigmaX1 = 0.0;
            end % try

            try
                aAxis    = obj.Config.Particles.Species.(sSpecies).Profile.ProfileX2.Axis;
                aData    = obj.Config.Particles.Species.(sSpecies).Profile.ProfileX2.Value;
                oFit     = fit(double(aAxis)',double(aData)','Gauss1');
                dMeanX2  = oFit.b1;
                dSigmaX2 = oFit.c1/sqrt(2);
            catch
                dMeanX2  = 0.0;
                dSigmaX2 = 0.0;
            end % try

            try
                aAxis    = obj.Config.Particles.Species.(sSpecies).Profile.ProfileX3.Axis;
                aData    = obj.Config.Particles.Species.(sSpecies).Profile.ProfileX3.Value;
                oFit     = fit(double(aAxis)',double(aData)','Gauss1');
                dMeanX3  = oFit.b1;
                dSigmaX3 = oFit.c1/sqrt(2);
            catch
                dMeanX3  = 0.0;
                dSigmaX3 = 0.0;
            end % try

            dSIMeanX1  = dMeanX1*dLFac;
            dSIMeanX2  = dMeanX2*dLFac;
            dSIMeanX3  = dMeanX3*dLFac;
            dSISigmaX1 = dSigmaX1*dLFac;
            dSISigmaX2 = dSigmaX2*dLFac;
            dSISigmaX3 = dSigmaX3*dLFac;

            stReturn.X1Mean   = dSIMeanX1;
            stReturn.X2Mean   = dSIMeanX2;
            stReturn.X3Mean   = dSIMeanX3;
            stReturn.X1Sigma  = dSISigmaX1;
            stReturn.X2Sigma  = dSISigmaX2;
            stReturn.X3Sigma  = dSISigmaX3;

            [dSIMeanX1,  sUnitM1] = fAutoScale(dSIMeanX1,'m');
            [dSIMeanX2,  sUnitM2] = fAutoScale(dSIMeanX2,'m');
            [dSIMeanX3,  sUnitM3] = fAutoScale(dSIMeanX3,'m');
            [dSISigmaX1, sUnitS1] = fAutoScale(dSISigmaX1,'m');
            [dSISigmaX2, sUnitS2] = fAutoScale(dSISigmaX2,'m');
            [dSISigmaX3, sUnitS3] = fAutoScale(dSISigmaX3,'m');
            
            if ~obj.Silent
                fprintf(' X1 Mean, Sigma: %7.2f, %9.4f [%7.2f %2s, %7.2f %2s]\n',dMeanX1,dSigmaX1,dSIMeanX1,sUnitM1,dSISigmaX1,sUnitS1);
                fprintf(' X2 Mean, Sigma: %7.2f, %9.4f [%7.2f %2s, %7.2f %2s]\n',dMeanX2,dSigmaX2,dSIMeanX2,sUnitM2,dSISigmaX2,sUnitS2);
                if iDim > 2
                    fprintf(' X3 Mean, Sigma: %7.2f, %9.4f [%7.2f %2s, %7.2f %2s]\n',dMeanX3,dSigmaX3,dSIMeanX3,sUnitM3,dSISigmaX3,sUnitS3);
                end % if
                fprintf('\n');
            end % if

            dBeamCharge  = dCharge*dQFac;
            dBeamNum     = dCharge*dPFac;

            stReturn.Particles = dBeamNum;
            stReturn.Charge    = dBeamCharge;

            [dBeamCharge, sChargeUnit] = fAutoScale(dBeamCharge,'C');

            if ~obj.Silent
                fprintf(' Total Charge:      %0.3f %s\n', dBeamCharge, sChargeUnit);
                fprintf(' Particle Count:    %0.3e \n',   dBeamNum);
                fprintf('\n');
            end % if
            
        end % function

        function aReturn = Data(obj, iTime, sType, sSet, sSpecies)
            
            %
            %  Data-extraction function
            % **************************
            %
            %  Input:
            % ========
            %  iTime    :: Time dump to extract
            %  sType    :: Data type [DENSITY, FLD, PHA, RAW, TRACKS]
            %  sSet     :: Data set i.e. charge, x1p1, etc
            %  sSpecies :: Particle species
            %
            
            % Input/Output
            aReturn = [];

            if nargin == 1
                fprintf('\n');
                fprintf(' Data-extraction function\n');
                fprintf('**************************\n');
                fprintf('\n');
                fprintf(' Input:\n');
                fprintf('========\n');
                fprintf(' iTime    :: Time dump to extract\n');
                fprintf(' sType    :: Data type [DENSITY, FLD, PHA, RAW, TRACKS]\n');
                fprintf(' sSet     :: Data set i.e. charge, x1p1, etc\n');
                fprintf(' sSpecies :: Particle species\n');
                fprintf('\n');
                return;
            end % if
            
            if strcmp(obj.Path, '')
                fprintf(2, 'Error: No dataset has been loaded.\n');
                return;
            end % if
            
            % Convert and check input values
            sType     = upper(sType); % Type is always upper case
            sSet      = lower(sSet);  % Set is always lower case
            
            % Species translated to standard format, and then to actual file name used
            sSpecies  = obj.Translate.Lookup(sSpecies).Name;
            if ~isempty(sSpecies)
                sSpecies  = obj.Config.Particles.Species.(sSpecies).Name;
            end % if

            if isempty(sType)
                fprintf(2, 'Error: Data type needs to be specified.\n');
                return;
            end % if
            if ~obj.DataSetExists(sType, sSet, sSpecies)
                fprintf(2, 'Error: Specified data set does not exist.\n');
                return;
            end % if
            if isempty(sSet)
                sSet = 'None';
            end % if
            if isempty(sSpecies)
                sSpecies = 'None';
            end % if

            % Extract path
            iIndex    = obj.MSData.Index.(sType).(sSet).(sSpecies);
            sFolder   = obj.MSData.Data(iIndex).Path;
            iFiles    = obj.MSData.Data(iIndex).Files;
            sTimeNExt = sprintf('%06d', iTime);
            sDataRoot = [obj.Path, '/MS'];

            switch (sType)
                case 'DENSITY'
                    sFile = ['/',sSet,'-',sSpecies,'-',sTimeNExt,'.h5'];
                case 'FLD'
                    sFile = ['/',sSet,'-',sTimeNExt,'.h5'];
                case 'PHA'
                    sFile = ['/',sSet,'-',sSpecies,'-',sTimeNExt,'.h5'];
                case 'RAW'
                    sFile = ['/',sType,'-',sSpecies,'-',sTimeNExt,'.h5'];
                case 'TRACKS'
                    sFile = ['/',sSpecies,'-tracks.h5'];
            end % switch

            % Check if datafile exists
            if iTime >= iFiles && ~strcmpi(sType, 'TRACKS')
                fprintf(2, 'Error: Dump %d does not exist. Last dump is %d.\n', iTime, iFiles-1);
                return;
            end % if
            
            sLoad = [sDataRoot, sFolder, sFile];
            
            if strcmpi(sType, 'RAW') || strcmpi(sType, 'TRACKS')

                if strcmpi(sType, 'RAW')
                    sGroup = '/';
                else
                    sGroup = strcat('/', sSet, '/');
                end % if
                
                aCol1 = h5read(sLoad, [sGroup, 'x1']);
                aCol2 = h5read(sLoad, [sGroup, 'x2']);
                if obj.Config.Simulation.Dimensions == 3
                    aCol3 = h5read(sLoad, [sGroup, 'x3']);
                else
                    aCol3 = aCol1*0.0;
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

                aReturn = h5read(sLoad, ['/',sSet]);
            
            end % if
            
        end % function
        
        function bReturn = DataSetExists(obj, sType, sSet, sSpecies)
            
            bReturn = false;
            
            [~,iMS] = size(obj.MSData.Data);
            for m=1:iMS
                if strcmp(obj.MSData.Data(m).Type, sType) && strcmp(obj.MSData.Data(m).Set, sSet) && strcmp(obj.MSData.Data(m).Species, sSpecies)
                    bReturn = true;
                    return;
                end % if
            end % for
            
        end % function

        function bReturn = SaveAnalysis(obj, stData, sClass, sMethod, sSubject, sData, iTime, sReplace)
            
            bReturn = false;
            sPath   = obj.Path;
            
            % Check if analysis folder exists
            sPath = [sPath, '/AN'];
            if ~isdir(sPath)
                try
                    mkdir(sPath);
                catch
                    fprint('Failed to create folder %s\n',sPath);
                    return;
                end % try
            end % if
            
            % Check if class folder exists
            sPath = [sPath, '/', sClass];
            if ~isdir(sPath)
                try
                    mkdir(sPath);
                catch
                    fprint('Failed to create folder %s\n',sPath);
                    return;
                end % try
            end % if

            % Check if method folder exists
            sPath = [sPath, '/', sMethod];
            if ~isdir(sPath)
                try
                    mkdir(sPath);
                catch
                    fprint('Failed to create folder %s\n',sPath);
                    return;
                end % try
            end % if
            
            % Generate FileName
            if iTime < 0
                sTime = 'RANGE';
            else
                sTime = sprintf('%05d',iTime);
            end % if
            
            if strcmpi(sReplace, 'Replace')
                sFile = sprintf('%s-%s-%s-000.mat',sSubject,sData,sTime);
            else
                for i=1:100
                    sFile = sprintf('%s-%s-%s-%03d.mat',sSubject,sData,sTime,i);
                    if ~exist([sPath, '/', sFile],'file')
                        break;
                    end % if
                end % for
            end % if

            % TimeStamp
            aTime      = clock;
            aTime(6)   = round(aTime(6));
            sTimeStamp = sprintf('%04.0f-%02.0f-%02.0f %02.0f:%02.0f:%02.0f', aTime);

            % Save File
            stSave.Save           = stData;
            stSave.Save.TimeStamp = sTimeStamp;
            save([sPath, '/', sFile],'-struct','stSave');
            
            bReturn = true;
            
        end % function

        function stReturn = ExportTags(obj, sTime, sSpecies, varargin)
            
            stReturn = {};

            sSpecies = obj.TranslateInput(sSpecies);
            iTime    = obj.StringToDump(num2str(sTime));

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
        
        function stReturn = Timings(obj, bPrint)
            
            stReturn = {};

            if nargin < 2
                bPrint = 0;
            end % if
            
            sPath = [obj.Config.Path '/TIMINGS/'];
            if ~isdir(sPath)
                fprintf(2, 'Error: No timing data for simulation %s\n', obj.Config.Name);
                return;
            end % if
            
            sFile   = strtrim(fileread([sPath  '/timings-final']));
            stLines = strsplit(sFile,'\n');
            iLines  = numel(stLines);
            
            if iLines < 5
                fprintf(2, 'Error: Unknown timing format for simulation %s\n', obj.Config.Name);
                return;
            end % if
            
            stReturn.Iterations = fix(str2double(stLines{1}(15:end)));
            
            stReturn.Timings(iLines-5).Event = [];
            stReturn.Timings(iLines-5).Avg   = [];
            stReturn.Timings(iLines-5).Min   = [];
            stReturn.Timings(iLines-5).Max   = [];
            for l=5:iLines
                sLine = stLines{l};
                
                if length(sLine) < 99
                    continue;
                end % if

                stReturn.Timings(l-4).Event = strtrim(sLine(1:42));
                stReturn.Timings(l-4).Avg   = str2double(sLine(43:62));
                stReturn.Timings(l-4).Min   = str2double(sLine(62:82));
                stReturn.Timings(l-4).Max   = str2double(sLine(82:end));
            end % for
            
            % Print Report if Requested
 
            if ~bPrint
                return;
            end % if
            
            fprintf('+--------------------------------------+-------------+-------------+-------------+\n');
            fprintf('|                                Event |   Average   |   Minimum   |   Maximum   |\n');
            fprintf('+--------------------------------------+-------------+-------------+-------------+\n');
            for r=2:iLines-5
                fprintf('| %36s | %s | %s | %s |\n', ...
                    stReturn.Timings(r).Event, ...
                    fTimeToString(stReturn.Timings(r).Avg,2), ...
                    fTimeToString(stReturn.Timings(r).Min,2), ...
                    fTimeToString(stReturn.Timings(r).Max,2));
            end % for
            fprintf('+--------------------------------------+-------------+-------------+-------------+\n');
            fprintf('| %36s | %s | %s | %s |\n', ...
                'Total Run Time', ...
                fTimeToString(stReturn.Timings(1).Avg,2), ...
                fTimeToString(stReturn.Timings(1).Min,2), ...
                fTimeToString(stReturn.Timings(1).Max,2));
            fprintf('+--------------------------------------+-------------+-------------+-------------+\n');
            
        end % function

        function iReturn = StringToDump(obj, vValue)

            iReturn = 0;
            sString = num2str(vValue);

            if isempty(sString)
                return;
            end % if

            if strcmp(sString(end), 'm')
                % Function will translate from metres to closest dump
                % Not yet implemented
                iReturn = 0;
                return;
            end % if

            if isintegerstring(sString)
                iReturn = floor(str2double(sString));
                return;
            end % if

            if strcmpi(sString, 'Start')
                iReturn = 0;
                return;
            end % if

            if strcmpi(sString, 'End')
                iReturn = obj.MSData.MinFiles - 1;
                if iReturn < 0
                    iReturn = 0;
                end % if
                return;
            end % if

            if strcmpi(sString, 'PStart')
                dPStart   = obj.Config.Simulation.PlasmaStart;
                dTimeStep = obj.Config.Simulation.TimeStep;
                iNDump    = obj.Config.Simulation.NDump;
                iReturn   = round(dPStart/(dTimeStep*iNDump));
                if iReturn > obj.MSData.MinFiles - 1
                    iReturn = obj.MSData.MinFiles - 1;
                end % if
                if iReturn < 0
                    iReturn = 0;
                end % if
                return;
            end % if

            if strcmpi(sString, 'PEnd')
                dPEnd     = obj.Config.Simulation.PlasmaEnd;
                dTimeStep = obj.Config.Simulation.TimeStep;
                iNDump    = obj.Config.Simulation.NDump;
                iReturn   = round(dPEnd/(dTimeStep*iNDump));
                if iReturn > obj.MSData.MinFiles - 1
                    iReturn = obj.MSData.MinFiles - 1;
                end % if
                if iReturn < 0
                    iReturn = 0;
                end % if
                return;
            end % if

        end % function
        
    end % methods
    
    %
    % Private Methods
    %
    
    methods(Access = 'private')
        
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
        
        function stReturn = fScanElements(obj)
            
            stReturn = struct();
            stData   = struct();
            stIndex  = struct();
            iRow     = 1;
            iMax     = 0;
            iMin     = 1e6;
            
            stType = fieldnames(obj.Elements);
            for i=2:length(stType)
                
                sType = stType{i};
                switch(sType)

                    case 'DENSITY'
                        stSpecies = fieldnames(obj.Elements.(sType));
                        for j=2:length(stSpecies)
                            sSpecies = stSpecies{j};
                            stSet    = fieldnames(obj.Elements.(sType).(sSpecies));
                            for k=2:length(stSet)
                                sSet = stSet{k};
                                stData(iRow).Type    = sType;
                                stData(iRow).Set     = sSet;
                                stData(iRow).Species = sSpecies;
                                stData(iRow).Path    = obj.Elements.(sType).(sSpecies).(sSet).Info.Path;
                                stData(iRow).Files   = obj.Elements.(sType).(sSpecies).(sSet).Info.Files;
                                stIndex.(sType).(sSet).(sSpecies) = iRow;

                                iFiles = stData(iRow).Files;
                                if iFiles > iMax
                                    iMax = iFiles;
                                end % if
                                if iFiles < iMin
                                    iMin = iFiles;
                                end % if
                                iRow = iRow + 1;
                            end % for
                        end % for
                        
                    case 'FLD'
                        stSet = fieldnames(obj.Elements.(sType));
                        for j=2:length(stSet)
                            sSet = stSet{j};
                            stData(iRow).Type    = sType;
                            stData(iRow).Set     = sSet;
                            stData(iRow).Species = '';
                            stData(iRow).Path    = obj.Elements.(sType).(sSet).Info.Path;
                            stData(iRow).Files   = obj.Elements.(sType).(sSet).Info.Files;
                            stIndex.(sType).(sSet).None = iRow;

                            iFiles = stData(iRow).Files;
                            if iFiles > iMax
                                iMax = iFiles;
                            end % if
                            if iFiles < iMin
                                iMin = iFiles;
                            end % if
                            iRow = iRow + 1;
                        end % for
                        
                    case 'PHA'
                        stSet = fieldnames(obj.Elements.(sType));
                        for j=2:length(stSet)
                            sSet      = stSet{j};
                            stSpecies = fieldnames(obj.Elements.(sType).(sSet));
                            for k=2:length(stSpecies)
                                sSpecies = stSpecies{k};
                                stData(iRow).Type    = sType;
                                stData(iRow).Set     = sSet;
                                stData(iRow).Species = sSpecies;
                                stData(iRow).Path    = obj.Elements.(sType).(sSet).(sSpecies).Info.Path;
                                stData(iRow).Files   = obj.Elements.(sType).(sSet).(sSpecies).Info.Files;
                                stIndex.(sType).(sSet).(sSpecies) = iRow;

                                iFiles = stData(iRow).Files;
                                if iFiles > iMax
                                    iMax = iFiles;
                                end % if
                                if iFiles < iMin
                                    iMin = iFiles;
                                end % if
                                iRow = iRow + 1;
                            end % for
                        end % for

                    case 'RAW'
                        stSpecies = fieldnames(obj.Elements.(sType));
                        for j=2:length(stSpecies)
                            sSpecies = stSpecies{j};
                            stData(iRow).Type    = sType;
                            stData(iRow).Set     = '';
                            stData(iRow).Species = sSpecies;
                            stData(iRow).Path    = obj.Elements.(sType).(sSpecies).Info.Path;
                            stData(iRow).Files   = obj.Elements.(sType).(sSpecies).Info.Files;
                            stIndex.(sType).None.(sSpecies) = iRow;

                            iFiles = stData(iRow).Files;
                            if iFiles > iMax
                                iMax = iFiles;
                            end % if
                            if iFiles < iMin
                                iMin = iFiles;
                            end % if
                            iRow = iRow + 1;
                        end % for
                        
                    case 'TRACKS'
                        stData(iRow).Type    = sType;
                        stData(iRow).Set     = '';
                        stData(iRow).Species = '';
                        stData(iRow).Path    = obj.Elements.(sType).Info.Path;
                        stData(iRow).Files   = obj.Elements.(sType).Info.Files;
                        stIndex.(sType).None.None = iRow;
                        iRow = iRow + 1;

                end % switch
            end % for
            
            if iMin == 1e6
                iMin = 0;
            end % if
            
            stReturn.Data     = stData;
            stReturn.Index    = stIndex;
            stReturn.MinFiles = iMin;
            stReturn.MaxFiles = iMax;
            
        end % function

    end % methods

    %
    % Static Methods
    %
    
    methods(Static)

        function iReturn = RawToIndex(sAxis)

            switch(sAxis)
                case 'x1'
                    iReturn = 1;
                case 'x2'
                    iReturn = 2;
                case 'x3'
                    iReturn = 3;
                case 'p1'
                    iReturn = 4;
                case 'p2'
                    iReturn = 5;
                case 'p3'
                    iReturn = 6;
                case 'ene'
                    iReturn = 7;
                case 'energy'
                    iReturn = 7;
                case 'q'
                    iReturn = 8;
                case 'charge'
                    iReturn = 8;
                case 'tag1'
                    iReturn = 9;
                case 'tag2'
                    iReturn = 10;
                otherwise
                    iReturn = 0;
            end % switch

        end % function

    end % methods
    
end % classdef

