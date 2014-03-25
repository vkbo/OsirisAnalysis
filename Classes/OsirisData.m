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
    
            obj.RawFields = {'x1','x2','x3','p1','p2','p3','ene','q','tag1','tag2'};
            obj.Config    = OsirisConfig();
            
            obj.DefaultPath{1} = '/scratch/Data';
            obj.DefaultPath{2} = '/media/vkbo/External/Work/Data';
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

        function PlasmaInfo(obj)
            
            dPStart = obj.Config.Variables.Plasma.PlasmaStart;
            dPEnd   = obj.Config.Variables.Plasma.PlasmaEnd;
            dTFac   = obj.Config.Variables.Convert.SI.TimeFac;
            
            fprintf('Plasma Start: %7.1f @ Dump %03d:%03d\n', dPStart, floor(dPStart/dTFac), ceil(dPStart/dTFac));
            fprintf('Plasma End:   %7.1f @ Dump %03d:%03d\n', dPEnd,   floor(dPEnd/dTFac),   ceil(dPEnd/dTFac));
            
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
            fprintf('Path is %s\n', obj.Path);
            
            % Scanning first level

            aDirs1 = dir(strcat(obj.Path, '/MS/'));
            for i=1:length(aDirs1)
            
                if aDirs1(i).isdir && ~strcmp(aDirs1(i).name, '.') && ~strcmp(aDirs1(i).name, '..')
                
                    sName1  = strrep(aDirs1(i).name, '-', '_');
                    sPath   = aDirs1(i).name;
                    iFiles1 = 0;
                    
                    obj.Elements.(sName1) = struct('Path', sPath, 'Files', 0);
                    
                    % Scanning second level

                    aDirs2  = dir(strcat(obj.Path, '/MS/', sName1, '/'));
                    for j=1:length(aDirs2)
                    
                        if aDirs2(j).isdir && ~strcmp(aDirs2(j).name, '.') && ~strcmp(aDirs2(j).name, '..')

                            sName2  = strrep(aDirs2(j).name, '-', '_');
                            sPath   = strcat(aDirs1(i).name, '/', aDirs2(j).name);
                            iFiles2 = 0;

                            obj.Elements.(sName1).(sName2) = struct('Path', sPath, 'Files', 0);
                            
                            % Scanning third level

                            aDirs3  = dir(strcat(obj.Path, '/MS/', sName1, '/', sName2, '/'));
                            for k=1:length(aDirs3)

                                if aDirs3(k).isdir && ~strcmp(aDirs3(k).name, '.') && ~strcmp(aDirs3(k).name, '..')
                                
                                    sName3  = strrep(aDirs3(k).name, '-', '_');
                                    sPath   = strcat(aDirs1(i).name, '/', aDirs2(j).name, '/', aDirs3(k).name); 
                                    iFiles3 = 0;                            

                                    obj.Elements.(sName1).(sName2).(sName3) = struct('Path', sPath);
                                    
                                    % Counting files in fourth level

                                    aDirs4  = dir(strcat(obj.Path, '/MS/', sName1, '/', sName2, '/', sName3, '/'));
                                    for l=1:length(aDirs4)
                                        if ~aDirs4(l).isdir
                                            iFiles3 = iFiles3 + 1;
                                        end % if
                                    end % for
                                    obj.Elements.(sName1).(sName2).(sName3).Files = iFiles3;

                                elseif ~aDirs3(k).isdir
                                
                                    iFiles2 = iFiles2 + 1;
                                
                                end % if

                                obj.Elements.(sName1).(sName2).Files = iFiles2;

                            end % for
                            
                        elseif ~aDirs2(j).isdir
                            
                            iFiles1 = iFiles1 + 1;
                            
                        end % if

                    end % for

                    obj.Elements.(sName1).Files = iFiles1;

                end % if

            end % for

            % Set path in OsirisConfig object
            obj.Config.Path = obj.Path;
            

        end % function
        
        function obj = set.PathID(obj, iID)
            
            if iID > 0 && iID <= length(obj.DefaultData)
                obj.PathID = iID;
                obj.Path   = obj.DefaultData{iID};
            else
                fprintf('Error: Folder with ID %d is not in the list.\n', iID);
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
        
        function h5Data = Data(obj, iTime, sVal1, sVal2, sVal3)
            
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
                    case 'FLD'
                        sFolder = strcat(sSet, '/');
                        sFile   = strcat(sSet, '-', sTimeNExt);
                    case 'PHA'
                        sFolder = strcat(sSet, '/', sSpecies, '/');
                        sFile   = strcat(sSet, '-', sSpecies, '-', sTimeNExt);
                    case 'RAW'
                        sFolder = strcat(sSpecies, '/');
                        sFile   = strcat(sType, '-', sSpecies, '-', sTimeNExt);
                end % switch

            else
                
                aPath = strsplit(char(sVal1.Path), '/');
                sType = aPath{1};
                sSet  = '';

                sTimeNExt = strcat(sprintf('%06d', iTime), '.h5');
                sDataRoot = strcat(obj.Path, '/MS/', sType, '/');

                switch (sType)
                    case 'DENSITY'
                        sFolder = strcat(aPath(2), '/', aPath(3), '/');
                        sFile   = strcat(aPath(3), '-', aPath(2), '-', sTimeNExt);
                        sSet    = aPath{3};
                    case 'FLD'
                        sFolder = strcat(aPath(2), '/');
                        sFile   = strcat(aPath(2), '-', sTimeNExt);
                        sSet    = aPath{2};
                    case 'PHA'
                        sFolder = strcat(aPath(2), '/', aPath(3), '/');
                        sFile   = strcat(aPath(2), '-', aPath(3), '-', sTimeNExt);
                        sSet    = aPath{2};
                    case 'RAW'
                        sFolder = strcat(aPath(2), '/');
                        sFile   = strcat(aPath(1), '-', aPath(2), '-', sTimeNExt);
                end % switch

            end % if
            
            sLoad  = char(strcat(sDataRoot, sFolder, sFile));
            fprintf('File: %s\n', sLoad);
            
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
        
        
    end % methods
    
end % classdef

