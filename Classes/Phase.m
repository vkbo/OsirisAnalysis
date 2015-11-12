
%
%  Class Object :: Analyse Phase
% *******************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to the phase data
%    outputs for particles.
%
%  Constructor:
%    oData    : OsirisDara object
%    sSpecies : What species to study
%    Parameter pairs:
%      Units   : 'N', 'SI' or 'CGS'
%      X1Scale : Unit scale on x1 axis. 'Auto', or specify metric unit
%      X2Scale : Unit scale on x2 axis. 'Auto', or specify metric unit
%      X3Scale : Unit scale on x3 axis. 'Auto', or specify metric unit
%
%  Set Methods:
%    Time  : Set time dump for dataset. Default is 0.
%    X1Lim : 2D array of limits for x1 axis. Default is full box.
%    X2Lim : 2D array of limits for x2 axis. Default is full box.
%    X3Lim : 2D array of limits for x3 axis. Default is full box.
%
%  Public Methods:
%    Phase1D   : Returns a dataset with the distribution of a phase-type
%                variable in one dimension
%    Phase2D   : Returns a dataset with the density of two phase type
%                variables in two dimensions.
%    Scatter2D : Same as Phase2D, but creates the plot from macroparticles
%                instead.
%

classdef Phase < OsirisType

    %
    % Properties
    %

    properties(GetAccess = 'public', SetAccess = 'public')
        
        Species = ''; % Species to analyse

    end % properties
    
    %
    % Constructor
    %

    methods
        
        function obj = Phase(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, varargin{:});
            
            % Set species
            stSpecies = obj.Translate.Lookup(sSpecies);
            if stSpecies.isSpecies
                obj.Species = stSpecies;
            else
                sDefault = obj.Data.Config.Variables.Species.WitnessBeam{1};
                fprintf(2, 'Error: ''%s'' is not a recognised species name. Using ''%s'' instead.\n', sSpecies, sDefault);
                obj.Species = obj.Translate.Lookup(sDefault);
            end % if
            
        end % function
        
    end % methods

    %
    % Public Methods
    %
    
    methods(Access = 'public')

        function stReturn = Phase1D(obj, sAxis, varargin)
            
            % Input/Output
            stReturn = {};
            
        end % function

        function stReturn = Phase2D(obj, sAxis1, sAxis2, varargin)
            
            % Input/Output
            stReturn = {};
            
            vAxis1 = obj.Data.Translate.Lookup(sAxis1);
            vAxis2 = obj.Data.Translate.Lookup(sAxis2);
            
            if ~vAxis1.isValidPhaseSpaceDiag
                fprintf(2, '%s is not a valid axis.\n',sAxis1);
                return;
            end % if

            if ~vAxis2.isValidPhaseSpaceDiag
                fprintf(2, '%s is not a valid axis.\n',sAxis2);
                return;
            end % if
            
            sAxis = '';
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',vAxis1.Name,vAxis2.Name),obj.Species.Name)
                sAxis   = sprintf('%s%s',vAxis1.Name,vAxis2.Name);
                bRotate = false;
            end % if
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',vAxis2.Name,vAxis1.Name),obj.Species.Name)
                sAxis   = sprintf('%s%s',vAxis2.Name,vAxis1.Name);
                bRotate = true;
            end % if
            if isempty(sAxis)
                fprintf(2, 'There is no combined phase data for %s and %s.\n',sAxis1,sAxis2);
                return;
            end % if
            
            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'HLim',  []);
            addParameter(oOpt, 'HAuto', 'No');
            addParameter(oOpt, 'VLim',  []);
            addParameter(oOpt, 'VAuto', 'No');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            % Get dataset values
            dEMass = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
            
            % Retrieve data
            aData = obj.Data.Data(obj.Time,'PHA',sAxis,obj.Species.Name);
            dSum  = sum(aData(:));
            aData = aData/dSum;
            
            if bRotate
                aData = transpose(aData);
            end % if
            
            aHAxis = obj.fGetDiagAxis(sAxis1);
            aVAxis = obj.fGetDiagAxis(sAxis2);

            % Return ranges
            stReturn.AxisRange = [aHAxis(1) aHAxis(end) aVAxis(1) aVAxis(end)];
            stReturn.AxisFac   = obj.AxisFac(1)*[1.0 1.0];
            stReturn.AxisUnit  = {'N','N'};

            if strcmpi(obj.Units, 'SI')
                stReturn.AxisUnit = {'m','m'};
                if strcmpi(sAxis1(1),'p')
                    stReturn.AxisFac(1)  = dEMass;
                    stReturn.AxisUnit{1} = 'eV/c';
                end % if
                if strcmpi(sAxis2(1),'p')
                    stReturn.AxisFac(2)  = dEMass;
                    stReturn.AxisUnit{2} = 'eV/c';
                end % if
            end % if

            % Crop data and axes
            if ~isempty(stOpt.HLim) || strcmpi(stOpt.HAuto, 'Yes')

                if strcmpi(stOpt.HAuto, 'No')
                
                    iMin = fGetIndex(aHAxis, stOpt.HLim(1));
                    iMax = fGetIndex(aHAxis, stOpt.HLim(2));
                    
                else
                    
                    % Auto scale
                    iLen = length(aHAxis);

                    iMin = 1;
                    for i=1:iLen
                        if sum(aData(:,i)) > 0
                            iMin = i;
                            break;
                        end % if
                    end % for

                    iMax = iLen;
                    for i=iMax:-1:1
                        if sum(aData(:,i)) > 0
                            iMax = i;
                            break;
                        end % if
                    end % for
                    
                    iMargin = floor((iMax-iMin)*0.5);
                    if iMargin < 10
                        iMargin = 10;
                    end % if
                    iMin = iMin-iMargin;
                    iMax = iMax+iMargin;
                    
                    if iMin < 1
                        iMin = 1;
                    end % if
                    if iMax > iLen
                        iMax = iLen;
                    end % if

                end % if

                % Crop
                aData  = aData(:,iMin:iMax);
                aHAxis = aHAxis(iMin:iMax);

            end % if

            if ~isempty(stOpt.VLim) || strcmpi(stOpt.VAuto, 'Yes')

                if strcmpi(stOpt.VAuto, 'No')
                
                    iMin   = fGetIndex(aVAxis, stOpt.VLim(1));
                    iMax   = fGetIndex(aVAxis, stOpt.VLim(2));
                    
                else
                    
                    % Auto scale
                    iLen = length(aVAxis);
                    
                    iMin = 1;
                    for i=1:iLen
                        if sum(aData(i,:)) > 0
                            iMin = i;
                            break;
                        end % if
                    end % for

                    iMax = iLen;
                    for i=iMax:-1:1
                        if sum(aData(i,:)) > 0
                            iMax = i;
                            break;
                        end % if
                    end % for
                    
                    iMargin = floor((iMax-iMin)*0.5);
                    if iMargin < 10
                        iMargin = 10;
                    end % if
                    iMin = iMin-iMargin;
                    iMax = iMax+iMargin;
                    
                    if iMin < 1
                        iMin = 1;
                    end % if
                    if iMax > iLen
                        iMax = iLen;
                    end % if
                    
                end % if

                % Crop
                aData  = aData(iMin:iMax,:);
                aVAxis = aVAxis(iMin:iMax);
                
            end % if

            stReturn.Data    = aData;
            stReturn.Ratio   = abs(sum(aData(:)));
            stReturn.HAxis   = aHAxis;
            stReturn.VAxis   = aVAxis;
            stReturn.DataSet = sAxis;
            
        end % function
        
        function stReturn = Scatter2D(obj, sAxis1, sAxis2, varargin)
            
            % Input/Output
            stReturn = {};
            
            vAxis1 = obj.Data.Translate.Lookup(sAxis1);
            vAxis2 = obj.Data.Translate.Lookup(sAxis2);
            
            if ~vAxis1.isValidPhaseSpaceDiag
                fprintf(2, '%s is not a valid axis.\n',sAxis1);
                return;
            end % if

            if ~vAxis2.isValidPhaseSpaceDiag
                fprintf(2, '%s is not a valid axis.\n',sAxis2);
                return;
            end % if
            
            sAxis = '';
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',vAxis1.Name,vAxis2.Name),obj.Species.Name)
                sAxis   = sprintf('%s%s',vAxis1.Name,vAxis2.Name);
                bRotate = false;
            end % if
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',vAxis2.Name,vAxis1.Name),obj.Species.Name)
                sAxis   = sprintf('%s%s',vAxis2.Name,vAxis1.Name);
                bRotate = true;
            end % if
            if isempty(sAxis)
                fprintf(2, 'There is no combined phase data for %s and %s.\n',sAxis1,sAxis2);
                return;
            end % if
            
            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'HLim',   []);
            addParameter(oOpt, 'VLim',   []);
            addParameter(oOpt, 'Sample', 10000);
            addParameter(oOpt, 'Grid1',  100);
            addParameter(oOpt, 'Grid2',  100);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            % Get dataset values
            dEMass = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
            dTFac  = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dQFac  = obj.Data.Config.Variables.Convert.SI.ChargeFac;
            
            % Retrieve data
            aRaw = obj.Data.Data(obj.Time,'RAW','',obj.Species.Name);
            
            % Move x1 to box start
            aRaw(:,1) = aRaw(:,1) - dTFac*obj.Time;

            % Removing elements outside box on horizontal axis
            dHFac  = 1.0;
            sHUnit = 'm';
            switch(sAxis1(1))
                case 'x'
                    stOpt.HLim = stOpt.HLim/obj.AxisFac(obj.Data.RawToIndex(sAxis1));
                    dHFac      = obj.AxisFac(obj.Data.RawToIndex(sAxis1));
                case 'p'
                    stOpt.HLim = stOpt.HLim/dEMass;
                    dHFac      = dEMass;
                    sHUnit     = 'eV';
            end % switch
            if ~isempty(stOpt.HLim)
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= stOpt.HLim(1) & aRaw(:,1) <= stOpt.HLim(2));
            end % if

            % Removing elements outside box on vertical axis
            dVFac  = 1.0;
            sVUnit = 'm';
            switch(sAxis2(1))
                case 'x'
                    stOpt.VLim = stOpt.VLim/obj.AxisFac(obj.Data.RawToIndex(sAxis2));
                    dVFac      = obj.AxisFac(obj.Data.RawToIndex(sAxis2));
                case 'p'
                    stOpt.VLim = stOpt.VLim/dEMass;
                    dVFac      = dEMass;
                    sVUnit     = 'eV';
            end % switch
            if ~isempty(stOpt.VLim)
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= stOpt.VLim(1) & aRaw(:,2) <= stOpt.VLim(2));
            end % if
            
            % Cut zero data
            aRaw = aRaw(find(aRaw(:,8)),:);
            
            % Sample data
            iCount = length(aRaw(:,1));
            if iCount > stOpt.Sample
                aRand = randperm(iCount);
                aRaw  = aRaw(aRand(1:stOpt.Sample),:);
            end % if
            
            % Scale axes
            if strcmpi(obj.Units, 'SI')
                aRaw(:,1) = aRaw(:,1)*obj.AxisFac(1);
                aRaw(:,2) = aRaw(:,2)*obj.AxisFac(2);
                aRaw(:,3) = aRaw(:,3)*obj.AxisFac(3);
                aRaw(:,4) = aRaw(:,4)*dEMass;
                aRaw(:,5) = aRaw(:,5)*dEMass;
                aRaw(:,6) = aRaw(:,6)*dEMass;
                stReturn.AxisUnit = {sHUnit, sVUnit};
            else
                stReturn.AxisUnit = {'N', 'N'};
            end % if
            
            % Select wanted axes
            [aQ,aI] = sort(abs(aRaw(:,8)));
            aHData  = aRaw(aI,obj.Data.RawToIndex(sAxis1));
            aVData  = aRaw(aI,obj.Data.RawToIndex(sAxis2));
            
            stReturn.Raw   = aRaw;
            stReturn.HData = aHData;
            stReturn.VData = aVData;
            stReturn.Count = length(aHData);

            % Grid data
            iNH = stOpt.Grid1;
            iNV = stOpt.Grid2;
            
            aQData = aQ*dQFac;
            aGrid  = zeros(iNV,iNH);
            
            if ~isempty(aHData) && ~isempty(aVData)

                dHMin  = min(aHData);
                aHData = aHData-dHMin;
                dHMax  = max(aHData);
                aHData = int16(round(aHData/dHMax*(iNH-1)))+1;

                dVMin  = min(aVData);
                aVData = aVData-dVMin;
                dVMax  = max(aVData);
                aVData = int16(round(aVData/dVMax*(iNV-1)))+1;

                for i=1:length(aHData)
                    aGrid(aVData(i),aHData(i)) = aGrid(aVData(i),aHData(i))+abs(aQData(i));
                end % for
                
                aHAxis = linspace(dHMin, dHMin+dHMax, iNH);
                aVAxis = linspace(dVMin, dVMin+dVMax, iNV);
                aRange = [dHMin dHMin+dHMax dVMin dVMin+dVMax];

            else
                
                aHAxis = [];
                aVAxis = [];
                aRange = [0 0 0 0];

            end % if

            stReturn.Data      = aGrid*iCount/length(aHData);
            stReturn.HAxis     = aHAxis;
            stReturn.VAxis     = aVAxis;
            stReturn.DataSet   = sAxis;
            stReturn.AxisRange = aRange;
            stReturn.AxisFac   = [dHFac dVFac];
            
        end % function
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods(Access = 'private')
        
        function aReturn = fGetDiagAxis(obj, sAxis)
            
            if obj.Species.isBeam
                sSPType = 'Beam';
            elseif obj.Species.isPlasma
                sSPType = 'Plasma';
            else
                fprintf(2,'Error: Unknown species type.\n');
                return;
            end % if
            
            switch sAxis
                case 'x1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNX1;
                    dFac = obj.AxisFac(1);
                case 'x2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNX2;
                    dFac = obj.AxisFac(2);
                case 'x3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNX3;
                    dFac = obj.AxisFac(3);
                case 'p1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNP1;
                    dFac = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
                case 'p2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNP2;
                    dFac = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
                case 'p3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNP3;
                    dFac = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
            end % switch
            
            if strcmpi(obj.Units, 'N')
                dFac = 1.0;
            end % if

            aReturn = linspace(dMin, dMax, iN)*dFac;
            
        end % function
        
    end % methods

end % classdef
