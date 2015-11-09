
%
%  Class Object to hold Osiris data
% **********************************
%  Version dev1.2
%

classdef OsirisData
    
    %
    % Public Properties
    %
    
    properties (GetAccess = 'public', SetAccess = 'public')

        Path        = '';     % Path to dataset
        PathID      = '';     % Path as ID instead of free text input
        Elements    = {};     % Struct of all datafiles in dataset ('MS/' subfolder)
        MSData      = {};     % Struct of all MS data
        Config      = [];     % Content of the config files and extraction of all runtime variables
        DataSets    = {};     % Available datasets in folders indicated by LocalConfig.m
        DefaultPath = {};     % Default data folder
        Silent      = 0;      % Set to 1 to disable command window output
        Temp        = '/tmp'; % Temp folder (set in LocalConfig.m)

    end % properties

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')

        DefaultData = {}; % Data in default folder
        Translate   = {}; % Tool for translating Osiris variables

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
                obj.Silent = 1;
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
            obj.Config.Path      = obj.Path;
            obj.Config.HasData   = iHasData;
            obj.Config.HasTracks = iHasTracks;
            obj.Config.Completed = iCompleted;
            
            if obj.MSData.MinFiles == obj.MSData.MaxFiles
               obj.Config.Consistent = true;
            else
               obj.Config.Consistent = false;
            end % if
            
            obj.Translate = Variables(obj.Config.Variables.Simulation.Coordinates);

        end % function
        
        function obj = set.Elements(obj, stElements)

            obj.Elements = stElements;

        end % function
        
    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function Version(obj)
            
            fprintf('OsirisAnalysis Version dev1.2\n');
            
        end % function
        
        function stReturn = LookupVar(obj, sName, vType)
            %
            %  OsirisData.LookupVar
            % **********************
            %  Just a wrapper for obj.Translate.Lookup()
            %
            %  Input
            % =======
            %  sName :: Text to translate
            %  vType :: Suggestion for data type
            %
            
            if nargin < 3
                vType = '';
            end % if
            
            stReturn = obj.Translate.Lookup(sName, vType);
            
        end % function

        function stReturn = Info(obj)
            
            %
            %  Prints basic simulation info extracted from Config object
            % ***********************************************************
            %

            stReturn  = {};

            dTMax     = obj.Config.Variables.Simulation.TMax;
            dTimeStep = obj.Config.Variables.Simulation.TimeStep;
            dNDump    = obj.Config.Variables.Simulation.NDump;

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
            
            if ~obj.Silent
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
            %  Attempts to calculate beam data
            % *********************************
            %
            
            stReturn  = {};
            sSpecies  = obj.Translate.Lookup(sSpecies,'Beam').Name;
            
            dC        = obj.Config.Variables.Constants.SpeedOfLight;
            dE        = obj.Config.Variables.Constants.ElementaryCharge;
            dLFac     = obj.Config.Variables.Convert.SI.LengthFac;
            dT        = obj.Config.Variables.Simulation.TimeStep;
            
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
            
            if ~obj.Silent
                fprintf('\n');
                fprintf(' Beam Info for %s\n',sSpecies);
                fprintf('************************************\n');
                fprintf('\n');
            end % if

            stFunc   = fExtractEq(sMathFunc, iDim, [dX1Min,dX1Max,dX2Min,dX2Max,dX3Min,dX3Max]);
            fProfile = @(x1,x2) eval(stFunc.ForEval);
            
            if strcmpi(sCoords, 'cylindrical')

                dSIMeanX1  = dMeanX1*dLFac;
                dSIMeanX2  = dMeanX2*dLFac;
                dSISigmaX1 = dSigmaX1*dLFac;
                dSISigmaX2 = dSigmaX2*dLFac;
                
                stReturn.Equation = stFunc.Equation;
                stReturn.X1Mean   = dSIMeanX1;
                stReturn.X2Mean   = dSIMeanX2;
                stReturn.X1Sigma  = dSISigmaX1;
                stReturn.X2Sigma  = dSISigmaX2;

                [dSIMeanX1,  sUnitM1] = fAutoScale(dSIMeanX1, 'm');
                [dSIMeanX2,  sUnitM2] = fAutoScale(dSIMeanX2, 'm');
                [dSISigmaX1, sUnitS1] = fAutoScale(dSISigmaX1, 'm');
                [dSISigmaX2, sUnitS2] = fAutoScale(dSISigmaX2, 'm');

                sFunction = sprintf('%s.*x2', stFunc.ForEval);
                if ~obj.Silent
                    fprintf(' Density Function:       %s\n', stFunc.Equation);
                    fprintf(' X1 Mean, Sigma:         %7.2f, %9.4f [%7.2f %s, %7.2f %s]\n', dMeanX1, dSigmaX1, dSIMeanX1, sUnitM1, dSISigmaX1, sUnitS1);
                    fprintf(' X2 Mean, Sigma:         %7.2f, %9.4f [%7.2f %s, %7.2f %s]\n', dMeanX2, dSigmaX2, dSIMeanX2, sUnitM2, dSISigmaX2, sUnitS2);
                    fprintf('\n');
                end % if
                
                % Beam integral
                aSpanX1 = stFunc.Lims(1):dT:stFunc.Lims(2);
                aSpanX2 = stFunc.Lims(3):dT:stFunc.Lims(4);
                for i=1:length(aSpanX2)
                    aReturn(:,i) = fProfile(aSpanX1,aSpanX2(i))*aSpanX2(i);
                end % for
                aReturn  = aReturn.*(aReturn > 0);
                dBeamInt = 2*pi*sum(aReturn(:))*dT^2;
                
                dBeamVol     = dBeamInt * dC^3/dNOmegaP^3;
                dBeamNum     = dBeamVol * dDensity * dN0;
                dBeamCharge  = dBeamNum * dE;
                dBeamDensity = dBeamNum/dBeamVol;
                dBeamPlasma  = dBeamDensity/(dN0*dPMax);
                dPeakCurrent = dBeamCharge*dC / sqrt(2*pi*(dSigmaX1*dLFac)^2);
                
                stReturn.Volume    = dBeamVol;
                stReturn.Particles = dBeamNum;
                stReturn.Charge    = dBeamCharge;
                stReturn.Density   = dBeamDensity;
                stReturn.Ratio     = dBeamPlasma;
                stReturn.Current   = dPeakCurrent;
                
                [dPeakCurrent, dCurrentUnit] = fAutoScale(dPeakCurrent, 'A');
                [dBeamCharge,  sChargeUnit]  = fAutoScale(dBeamCharge,  'C');
                
                if ~obj.Silent
                    fprintf(' Max Plasma Density:     %0.3e m^-3\n', dN0*dPMax);
                    fprintf(' Max Plasma Frequency:   %0.3e s^-1\n', dMOmegaP);
                    fprintf('\n');
                    fprintf(' Beam Integral:          %0.3f \n',     dBeamInt);
                    fprintf(' Beam Volume:            %0.3e m^3\n',  dBeamVol);
                    fprintf(' Beam Charge:            %0.3f %s\n',   dBeamCharge, sChargeUnit);
                    fprintf(' Beam Particle Count:    %0.3e \n',     dBeamNum);
                    fprintf(' Beam Density:           %0.3e M^-3\n', dBeamDensity);
                    fprintf('\n');
                    fprintf(' Beam/Plasma Ratio:      %0.3e \n',     dBeamPlasma);
                    fprintf('\n');
                    fprintf(' Beam Peak Current:      %0.3f %s\n',    dPeakCurrent, dCurrentUnit);
                end % if

            end % if
            
            if ~obj.Silent
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
                fprintf(' object.Data(iTime, *)\n');
                fprintf('***********************\n');
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
            sType     = upper(sType);                        % Type is always upper case
            sSet      = lower(sSet);                         % Set is always lower case
            sSpecies  = obj.Translate.Lookup(sSpecies).Name; % Species translated to standard format
            % This needs to be extended so it will accept files stored with non-standard names for species

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

                aReturn = h5read(sLoad, ['/',sSet]);
            
            end % if
            
        end % function
        
        function stReturn = ExportTags(obj, sTime, sSpecies, varargin)
            
            stReturn = {};

            sSpecies = obj.TranslateInput(sSpecies);
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
        
        function bReturn = DataSetExists(obj, sType, sSet, sSpecies)
            
            bReturn = false;
            
            [~,iMS] = size(obj.MSData.Data);
            for m=1:iMS
                if strcmp(obj.MSData.Data(m).Type, sType) && strcmp(obj.MSData.Data(m).Set, sSet) && strcmp(obj.MSData.Data(m).Species, sSpecies)
                    bReturn = true;
                    break;
                end % if
            end % for
            
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
            
            stReturn.Data     = stData;
            stReturn.Index    = stIndex;
            stReturn.MinFiles = iMin;
            stReturn.MaxFiles = iMax;
            
        end % function
        
    end % methods
    
end % classdef

