
%
%  Class Object :: Analyse Species Phase
% ***************************************
%

classdef Phase

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data      = [];                        % OsirisData dataset
        Species   = '';                        % What species to analyse
        Time      = 0;                         % Current time (dumb number)
        X1Lim     = [];                        % Axes limits x1
        X2Lim     = [];                        % Axes limits x2
        X3Lim     = [];                        % Axes limits x3
        Units     = 'N';                       % Units of axes
        AxisUnits = {'N', 'N', 'N'};           % Units of axes
        AxisScale = {'Auto', 'Auto', 'Auto'};  % Scale of axes
        AxisRange = [0.0 0.0 0.0 0.0 0.0 0.0]; % Max and min of axes
        AxisFac   = [1.0, 1.0, 1.0];           % Axes scale factors
        Coords    = '';                        % Coordinates
        
    end % properties

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Phase(oData, sSpecies, varargin)
            
            % Set data and species
            obj.Data    = oData;
            obj.Species = oData.TranslateInput(sSpecies);

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Units',   'N');
            addParameter(oOpt, 'X1Scale', 'Auto');
            addParameter(oOpt, 'X2Scale', 'Auto');
            addParameter(oOpt, 'X3Scale', 'Auto');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Read config
            dBoxX1Min = obj.Data.Config.Variables.Simulation.BoxX1Min;
            dBoxX1Max = obj.Data.Config.Variables.Simulation.BoxX1Max;
            dBoxX2Min = obj.Data.Config.Variables.Simulation.BoxX2Min;
            dBoxX2Max = obj.Data.Config.Variables.Simulation.BoxX2Max;
            dBoxX3Min = obj.Data.Config.Variables.Simulation.BoxX3Min;
            dBoxX3Max = obj.Data.Config.Variables.Simulation.BoxX3Max;
            sCoords   = obj.Data.Config.Variables.Simulation.Coordinates;
            dLFactor  = obj.Data.Config.Variables.Convert.SI.LengthFac;

            % Set Scale and Units
            obj.AxisScale = {stOpt.X1Scale, stOpt.X2Scale, stOpt.X3Scale};
            obj.Coords    = sCoords;

            % Evaluate units
            switch(lower(stOpt.Units))

                case 'si'
                    obj.Units          = 'SI';
                    [dX1Fac, sX1Unit]  = fLengthScale(obj.AxisScale{1}, 'm');
                    [dX2Fac, sX2Unit]  = fLengthScale(obj.AxisScale{2}, 'm');
                    [dX3Fac, sX3Unit]  = fLengthScale(obj.AxisScale{3}, 'm');
                    obj.AxisFac        = [dLFactor*dX1Fac, dLFactor*dX2Fac, dLFactor*dX3Fac];
                    obj.AxisUnits      = {sX1Unit, sX2Unit, sX3Unit};
                    obj.AxisRange(1:2) = [dBoxX1Min dBoxX1Max]*obj.AxisFac(1);
                    obj.AxisRange(3:4) = [dBoxX2Min dBoxX2Max]*obj.AxisFac(2);
                    obj.AxisRange(5:6) = [dBoxX3Min dBoxX3Max]*obj.AxisFac(3);

                otherwise
                    obj.Units   = 'N';
                    obj.AxisFac = [1.0, 1.0, 1.0];
                    if strcmpi(sCoords, 'cylindrical')
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'rad'};
                    else
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'c/\omega_p'};
                    end % if
                    obj.AxisRange = [dBoxX1Min dBoxX1Max dBoxX2Min dBoxX2Max dBoxX3Min dBoxX3Max];

            end % switch


            % Set defult axis limits
            obj.X1Lim = [dBoxX1Min, dBoxX1Max]*obj.AxisFac(1);
            if strcmpi(sCoords, 'cylindrical')
                obj.X2Lim = [-dBoxX2Max, dBoxX2Max]*obj.AxisFac(2);
            else
                obj.X2Lim = [ dBoxX2Min, dBoxX2Max]*obj.AxisFac(2);
            end % if
            obj.X3Lim = [dBoxX3Min, dBoxX3Max]*obj.AxisFac(3);
            
        end % function
        
    end % methods

    %
    % Setters and Getters
    %

    methods

        function obj = set.Time(obj, sTime)
            
            sTime = num2str(sTime);
            iEnd  = fStringToDump(obj.Data, 'end');
            
            if strcmpi(sTime, 'next') || strcmpi(sTime, 'n')

                obj.Time = obj.Time + 1;
                if obj.Time > iEnd
                    obj.Time = iEnd;
                end % if

            elseif strcmpi(sTime, 'prev') || strcmpi(sTime, 'previous') || strcmpi(sTime, 'p')
            
                obj.Time = obj.Time - 1;
                if obj.Time < 0
                    obj.Time = 0;
                end % if

            else
                
                obj.Time = fStringToDump(obj.Data, sTime);

            end % if
            
        end % function

        function obj = set.X1Lim(obj, aX1Lim)

            dBoxX1Min = obj.Data.Config.Variables.Simulation.BoxX1Min;
            dBoxX1Max = obj.Data.Config.Variables.Simulation.BoxX1Max;

            if length(aX1Lim) ~= 2
                fprintf(2, 'Error: x1 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX1Lim(2) < aX1Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if

            if aX1Lim(1)/obj.AxisFac(1) < dBoxX1Min || aX1Lim(1)/obj.AxisFac(1) > dBoxX1Max ...
            || aX1Lim(2)/obj.AxisFac(1) < dBoxX1Min || aX1Lim(2)/obj.AxisFac(1) > dBoxX1Max
                fprintf('Warning: X1Lim input is out of range. Range is %.2f–%.2f %s.\n', dBoxX1Min*obj.AxisFac(1), dBoxX1Max*obj.AxisFac(1), obj.AxisUnits{1});
                aX1Lim(1) = dBoxX1Min*obj.AxisFac(1);
            end % if

            obj.X1Lim = aX1Lim/obj.AxisFac(1);

        end % function

        function obj = set.X2Lim(obj, aX2Lim)
 
            dBoxX2Min = obj.Data.Config.Variables.Simulation.BoxX2Min;
            dBoxX2Max = obj.Data.Config.Variables.Simulation.BoxX2Max;
            sCoords   = obj.Data.Config.Variables.Simulation.Coordinates;

            if length(aX2Lim) ~= 2
                fprintf(2, 'Error: x2 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX2Lim(2) < aX2Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if
            
            if strcmpi(sCoords, 'cylindrical')

                if aX2Lim(1)/obj.AxisFac(2) < -dBoxX2Max || aX2Lim(1)/obj.AxisFac(2) > dBoxX2Max ...
                || aX2Lim(2)/obj.AxisFac(2) < -dBoxX2Max || aX2Lim(2)/obj.AxisFac(2) > dBoxX2Max
                    fprintf('Warning: X2Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                            -dBoxX2Max*obj.AxisFac(2), dBoxX2Max*obj.AxisFac(2), obj.AxisUnits{2});
                    aX2Lim = [-dBoxX2Max*obj.AxisFac(2) dBoxX2Max*obj.AxisFac(2)];
                end % if

            else
                
                if aX2Lim(1)/obj.AxisFac(2) < dBoxX2Min || aX2Lim(1)/obj.AxisFac(2) > dBoxX2Max ...
                || aX2Lim(2)/obj.AxisFac(2) < dBoxX2Min || aX2Lim(2)/obj.AxisFac(2) > dBoxX2Max
                    fprintf('Warning: X2Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                            dBoxX2Min*obj.AxisFac(2), dBoxX2Max*obj.AxisFac(2), obj.AxisUnits{2});
                    aX2Lim = [dBoxX2Min*obj.AxisFac(2) dBoxX2Max*obj.AxisFac(2)];
                end % if

            end % if

            obj.X2Lim = aX2Lim/obj.AxisFac(2);
             
        end % function

        function obj = set.X3Lim(obj, aX3Lim)

            dBoxX3Min = obj.Data.Config.Variables.Simulation.BoxX3Min;
            dBoxX3Max = obj.Data.Config.Variables.Simulation.BoxX3Max;

            if length(aX3Lim) ~= 2
                fprintf(2, 'Error: x3 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX3Lim(2) < aX3Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if

            if aX3Lim(1)/obj.AxisFac(3) < dBoxX3Min || aX3Lim(1)/obj.AxisFac(3) > dBoxX3Max ...
            || aX3Lim(2)/obj.AxisFac(3) < dBoxX3Min || aX3Lim(2)/obj.AxisFac(3) > dBoxX3Max
                fprintf('Warning: X3Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                        dBoxX3Min*obj.AxisFac(3), dBoxX3Max*obj.AxisFac(3), obj.AxisUnits{3});
                aX3Lim = [dBoxX3Min*obj.AxisFac(3) dBoxX3Max*obj.AxisFac(3)];
            end % if

            obj.X3Lim = aX3Lim/obj.AxisFac(3);

        end % function

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')

        function stReturn = Phase1D(obj, sAxis, varargin)
            
            % Input/Output
            stReturn = {};
            
        end % function

        function stReturn = Phase2D(obj, sAxis1, sAxis2, varargin)
            
            % Input/Output
            stReturn = {};
            
            if ~isAxis(sAxis1)
                fprintf(2, '%s is not a valid axis.\n',sAxis1);
                return;
            end % if

            if ~isAxis(sAxis2)
                fprintf(2, '%s is not a valid axis.\n',sAxis2);
                return;
            end % if
            
            sAxis = '';
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',sAxis1,sAxis2),obj.Species)
                sAxis   = sprintf('%s%s',sAxis1,sAxis2);
                bRotate = false;
            end % if
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',sAxis2,sAxis1),obj.Species)
                sAxis   = sprintf('%s%s',sAxis2,sAxis1);
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
            aData = obj.Data.Data(obj.Time,'PHA',sAxis,obj.Species);
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
            
            if ~isAxis(sAxis1)
                fprintf(2, '%s is not a valid axis.\n',sAxis1);
                return;
            end % if

            if ~isAxis(sAxis2)
                fprintf(2, '%s is not a valid axis.\n',sAxis2);
                return;
            end % if
            
            sAxis = '';
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',sAxis1,sAxis2),obj.Species)
                sAxis   = sprintf('%s%s',sAxis1,sAxis2);
                bRotate = false;
            end % if
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',sAxis2,sAxis1),obj.Species)
                sAxis   = sprintf('%s%s',sAxis2,sAxis1);
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
            aRaw = obj.Data.Data(obj.Time,'RAW','',obj.Species);
            
            % Move x1 to box start
            aRaw(:,1) = aRaw(:,1) - dTFac*obj.Time;

            % Removing elements outside box on horizontal axis
            dHFac  = 1.0;
            sHUnit = 'm';
            switch(sAxis1(1))
                case 'x'
                    stOpt.HLim = stOpt.HLim/obj.AxisFac(fRawAxisToIndex(sAxis1));
                    dHFac      = obj.AxisFac(fRawAxisToIndex(sAxis1));
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
                    stOpt.VLim = stOpt.VLim/obj.AxisFac(fRawAxisToIndex(sAxis2));
                    dVFac      = obj.AxisFac(fRawAxisToIndex(sAxis2));
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
            aHData  = aRaw(aI,fRawAxisToIndex(sAxis1));
            aVData  = aRaw(aI,fRawAxisToIndex(sAxis2));
            
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
    
    methods (Access = 'private')
        
        function aReturn = fGetTimeAxis(obj)
            
            iDumps  = obj.Data.Elements.DENSITY.(obj.Species).charge.Info.Files-1;
            
            dPStart = obj.Data.Config.Variables.Plasma.PlasmaStart;
            dTFac   = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dLFac   = obj.Data.Config.Variables.Convert.SI.LengthFac;
            
            aReturn = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
            
        end % function

        function aReturn = fGetBoxAxis(obj, sAxis)
            
            switch sAxis
                case 'x1'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX1Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX1Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX1;
                    dLFac = obj.AxisFac(1);
                case 'x2'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX2Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX2Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX2;
                    dLFac = obj.AxisFac(2);
                case 'x3'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX3Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX3Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX3;
                    dLFac = obj.AxisFac(3);
            end % switch

            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function

        function aReturn = fGetDiagAxis(obj, sAxis)
            
            sSPType = fSpeciesType(obj.Species);
            
            switch sAxis
                case 'x1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagX1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagX1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagNX1;
                    dFac = obj.AxisFac(1);
                case 'x2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagX2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagX2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagNX2;
                    dFac = obj.AxisFac(2);
                case 'x3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagX3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagX3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagNX3;
                    dFac = obj.AxisFac(3);
                case 'p1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagP1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagP1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagNP1;
                    dFac = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
                case 'p2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagP2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagP2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagNP2;
                    dFac = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
                case 'p3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagP3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagP3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species).DiagNP3;
                    dFac = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
            end % switch
            
            if strcmpi(obj.Units, 'N')
                dFac = 1.0;
            end % if

            aReturn = linspace(dMin, dMax, iN)*dFac;
            
        end % function
        
        function dReturn = fGetZPos(obj)
            
            dLFactor = obj.Data.Config.Variables.Convert.SI.LengthFac;
            dTFactor = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dPStart  = obj.Data.Config.Variables.Plasma.PlasmaStart;
            
            dReturn  = (obj.Time*dTFactor - dPStart)*dLFactor;
            
        end % function

    end % methods

end % classdef
