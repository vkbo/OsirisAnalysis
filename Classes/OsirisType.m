
%
%  Class Object :: SuperClass for Osiris Data Types
% **************************************************
%

classdef OsirisType

    %
    % Properties
    %
    
    properties(GetAccess='public', SetAccess='public')
        
        Time        = 0;                         % Current time (dumb number)
        X1Lim       = [];                        % Axes limits x1
        X2Lim       = [];                        % Axes limits x2
        X3Lim       = [];                        % Axes limits x3
        SliceAxis   = 3;                         % Slice axis (3D)
        Slice       = 0;                         % Slice coordinate (3D)
        Error       = false;                     % True if object failed to initialise

    end % properties

    properties(GetAccess='public', SetAccess='private')
        
        Data        = {};                        % OsirisData dataset
        Species     = {};                        % Holds species information
        Config      = {};                        % Holds relevant OsirisConfig data
        Units       = 'N';                       % Units of axes
        AxisUnits   = {'N' 'N' 'N'};             % Units of axes
        AxisScale   = {'Auto' 'Auto' 'Auto'};    % Scale of axes
        AxisRange   = [0.0 0.0 0.0 0.0 0.0 0.0]; % Max and min of axes
        AxisFac     = [1.0 1.0 1.0];             % Axes scale factors
        ParticleFac = 1.0;                       % Q-to-particles factor
        ChargeFac   = 1.0;                       % Q-to-charge factor
        Coords      = '';                        % Coordinates
        Cylindrical = false;                     % Is cylindrical, true/false
        Dim         = 0;                         % Dimensions
        BoxOffset   = 0.0;                       % Start of the box in simulation

    end % properties
    
    properties(GetAccess='protected', SetAccess='protected')
        
        Translate   = {};                        % Lookup class for variables
        
    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = OsirisType(oData, sSpecies, varargin)
            
            % Set Data
            obj.Data = oData;

            % Read config
            aXMin    = obj.Data.Config.Simulation.XMin;
            aXMax    = obj.Data.Config.Simulation.XMax;
            sCoords  = obj.Data.Config.Simulation.Coordinates;
            bCyl     = obj.Data.Config.Simulation.Cylindrical;
            dLFactor = obj.Data.Config.Convert.SI.LengthFac;
            iDim     = obj.Data.Config.Simulation.Dimensions;

            % Set Variables
            obj.Dim         = iDim;
            obj.Coords      = sCoords;
            obj.Cylindrical = bCyl;
            obj.Translate   = Variables(sCoords);
            
            % Set Species
            if ~isempty(sSpecies)
                if ~strcmpi(sSpecies,'None')
                    stSpecies = obj.Translate.Lookup(sSpecies);
                    if stSpecies.isSpecies
                        obj.Species = stSpecies;
                        obj.Config  = obj.Data.Config.Particles.Species.(obj.Species.Name);
                    else
                        sDefault = obj.Data.Config.Particles.WitnessBeam{1};
                        fprintf(2, 'Error: ''%s'' is not a recognised species name. Using ''%s'' instead.\n', sSpecies, sDefault);
                        obj.Species = obj.Translate.Lookup(sDefault);
                        obj.Config  = obj.Data.Config.Particles.Species.(obj.Species.Name);
                    end % if
                end % if
            else
                obj.Error = true;
            end % if
            
            % Read Input Parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Units',   'N');
            addParameter(oOpt, 'Scale',   '');
            addParameter(oOpt, 'X1Scale', 'Auto');
            addParameter(oOpt, 'X2Scale', 'Auto');
            addParameter(oOpt, 'X3Scale', 'Auto');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Set Scale
            if isempty(stOpt.Scale)
                obj.AxisScale = {stOpt.X1Scale, stOpt.X2Scale, stOpt.X3Scale};
            else
                obj.AxisScale = {stOpt.Scale, stOpt.Scale, stOpt.Scale};
            end % if

            % Evaluate Units
            switch(lower(stOpt.Units))

                case 'si'
                    obj.Units = 'SI';
                    
                    [dX1Fac, sX1Unit]  = obj.fLengthScale(obj.AxisScale{1}, 'm');
                    [dX2Fac, sX2Unit]  = obj.fLengthScale(obj.AxisScale{2}, 'm');
                    [dX3Fac, sX3Unit]  = obj.fLengthScale(obj.AxisScale{3}, 'm');
                    obj.AxisFac        = [dLFactor*dX1Fac, dLFactor*dX2Fac, dLFactor*dX3Fac];
                    obj.AxisUnits      = {sX1Unit, sX2Unit, sX3Unit};
                    obj.AxisRange(1:2) = [aXMin(1) aXMax(1)]*obj.AxisFac(1);
                    obj.AxisRange(3:4) = [aXMin(2) aXMax(2)]*obj.AxisFac(2);
                    obj.AxisRange(5:6) = [aXMin(3) aXMax(3)]*obj.AxisFac(3);
                    
                    obj.ParticleFac    = obj.Data.Config.Convert.SI.ParticleFac;
                    obj.ChargeFac      = obj.Data.Config.Convert.SI.ChargeFac;

                case 'cgs'
                    obj.Units = 'CGS';
                    
                    [dX1Fac, sX1Unit]  = obj.fLengthScale(obj.AxisScale{1}, 'cm');
                    [dX2Fac, sX2Unit]  = obj.fLengthScale(obj.AxisScale{2}, 'cm');
                    [dX3Fac, sX3Unit]  = obj.fLengthScale(obj.AxisScale{3}, 'cm');
                    obj.AxisFac        = [dLFactor*dX1Fac, dLFactor*dX2Fac, dLFactor*dX3Fac];
                    obj.AxisUnits      = {sX1Unit, sX2Unit, sX3Unit};
                    obj.AxisRange(1:2) = [aXMin(1) aXMax(1)]*obj.AxisFac(1);
                    obj.AxisRange(3:4) = [aXMin(2) aXMax(2)]*obj.AxisFac(2);
                    obj.AxisRange(5:6) = [aXMin(3) aXMax(3)]*obj.AxisFac(3);
                    
                    obj.ParticleFac    = obj.Data.Config.Convert.CGS.ParticleFac;
                    obj.ChargeFac      = obj.Data.Config.Convert.CGS.ChargeFac;

                otherwise
                    obj.Units = 'N';

                    obj.AxisFac = [1.0, 1.0, 1.0];
                    if obj.Cylindrical
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'rad'};
                    else
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'c/\omega_p'};
                    end % if
                    obj.AxisRange   = [aXMin(1) aXMax(1) aXMin(2) aXMax(2) aXMin(3) aXMax(3)];

                    obj.ParticleFac = obj.Data.Config.Convert.Norm.ParticleFac;
                    obj.ChargeFac   = obj.Data.Config.Convert.Norm.ChargeFac;

            end % switch

            % Set defult axis limits
            obj.X1Lim = [aXMin(1) aXMax(1)]*obj.AxisFac(1);
            if obj.Cylindrical
                obj.X2Lim = [-aXMax(2) aXMax(2)]*obj.AxisFac(2);
            else
                obj.X2Lim = [ aXMin(2) aXMax(2)]*obj.AxisFac(2);
            end % if
            obj.X3Lim = [aXMin(3) aXMax(3)]*obj.AxisFac(3);
            
            % Set default slice for 3D
            if obj.Dim == 3
                obj.SliceAxis = 3;
                obj.Slice     = 0.0;
            end % if

        end % function

    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function obj = set.Time(obj, sTime)
            
            sTime = num2str(sTime);
            iEnd  = obj.Data.StringToDump('end');
            
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
                
                obj.Time      = obj.Data.StringToDump(sTime);
                obj.BoxOffset = obj.Time*obj.Data.Config.Convert.SI.TimeFac;

            end % if
            
        end % function
        
        function obj = set.X1Lim(obj, aX1Lim)

            dX1Min = obj.Data.Config.Simulation.XMin(1);
            dX1Max = obj.Data.Config.Simulation.XMax(1);

            if length(aX1Lim) ~= 2
                fprintf(2, 'Error: x1 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX1Lim(2) < aX1Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if

            if aX1Lim(1)/obj.AxisFac(1) < dX1Min || aX1Lim(1)/obj.AxisFac(1) > dX1Max ...
            || aX1Lim(2)/obj.AxisFac(1) < dX1Min || aX1Lim(2)/obj.AxisFac(1) > dX1Max
                fprintf('Warning: X1Lim input is out of range. Range is %.2f–%.2f %s.\n', dX1Min*obj.AxisFac(1), dX1Max*obj.AxisFac(1), obj.AxisUnits{1});
                aX1Lim(1) = dX1Min*obj.AxisFac(1);
            end % if

            obj.X1Lim = aX1Lim/obj.AxisFac(1);

        end % function
         
        function obj = set.X2Lim(obj, aX2Lim)
 
            dX2Min = obj.Data.Config.Simulation.XMin(2);
            dX2Max = obj.Data.Config.Simulation.XMax(2);

            if length(aX2Lim) ~= 2
                fprintf(2, 'Error: x2 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX2Lim(2) < aX2Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if
            
            if obj.Cylindrical

                if aX2Lim(1)/obj.AxisFac(2) < -dX2Max || aX2Lim(1)/obj.AxisFac(2) > dX2Max ...
                || aX2Lim(2)/obj.AxisFac(2) < -dX2Max || aX2Lim(2)/obj.AxisFac(2) > dX2Max
                    fprintf('Warning: X2Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                            -dX2Max*obj.AxisFac(2), dX2Max*obj.AxisFac(2), obj.AxisUnits{2});
                    aX2Lim = [-dX2Max*obj.AxisFac(2) dX2Max*obj.AxisFac(2)];
                end % if

            else
                
                if aX2Lim(1)/obj.AxisFac(2) < dX2Min || aX2Lim(1)/obj.AxisFac(2) > dX2Max ...
                || aX2Lim(2)/obj.AxisFac(2) < dX2Min || aX2Lim(2)/obj.AxisFac(2) > dX2Max
                    fprintf('Warning: X2Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                            dX2Min*obj.AxisFac(2), dX2Max*obj.AxisFac(2), obj.AxisUnits{2});
                    aX2Lim = [dX2Min*obj.AxisFac(2) dX2Max*obj.AxisFac(2)];
                end % if

            end % if

            obj.X2Lim = aX2Lim/obj.AxisFac(2);
             
        end % function
 
        function obj = set.X3Lim(obj, aX3Lim)

            dX3Min = obj.Data.Config.Simulation.XMin(3);
            dX3Max = obj.Data.Config.Simulation.XMax(3);

            if length(aX3Lim) ~= 2
                fprintf(2, 'Error: x3 limit needs to be a vector of dimension 2.\n');
                return;
            end % if

            if aX3Lim(2) < aX3Lim(1)
                fprintf(2, 'Error: second value must be larger than first value.\n');
                return;
            end % if

            if aX3Lim(1)/obj.AxisFac(3) < dX3Min || aX3Lim(1)/obj.AxisFac(3) > dX3Max ...
            || aX3Lim(2)/obj.AxisFac(3) < dX3Min || aX3Lim(2)/obj.AxisFac(3) > dX3Max
                fprintf('Warning: X3Lim input is out of range. Range is %.2f–%.2f %s.\n', ...
                        dX3Min*obj.AxisFac(3), dX3Max*obj.AxisFac(3), obj.AxisUnits{3});
                aX3Lim = [dX3Min*obj.AxisFac(3) dX3Max*obj.AxisFac(3)];
            end % if

            obj.X3Lim = aX3Lim/obj.AxisFac(3);

        end % function
        
        function obj = set.SliceAxis(obj, iAxis)
            
            if isempty(iAxis)
                return;
            end % if
            
            iAxis = floor(iAxis);
            
            if iAxis > 0 && iAxis <= obj.Dim
                obj.SliceAxis = iAxis;
            else
                fprintf(2, 'Error: Not a proper axis.\n');
            end % if
            
            obj.Slice = 0.0;
            
        end % function

        function obj = set.Slice(obj, dSlice)
            
            if isempty(dSlice)
                return;
            end % if

            aAxis     = obj.fGetBoxAxis(sprintf('x%d',obj.SliceAxis));
            obj.Slice = fGetIndex(aAxis,dSlice);
            
        end % function

    end % methods

    %
    % Public Methods
    %
    
    methods(Access='public')

        function sReturn = PlasmaPosition(obj)

            sReturn = 'Unknown Position';

            dTFac    = obj.Data.Config.Convert.SI.TimeFac;
            dLFac    = obj.Data.Config.Convert.SI.LengthFac;
            dPStart  = obj.Data.Config.Simulation.PlasmaStart;
            dPEnd    = obj.Data.Config.Simulation.PlasmaEnd;
            
            dSimPos  = obj.Time*dTFac;
            dDeltaT  = dTFac*dLFac;
            dTMag    = round(log10(dDeltaT));
            
            dScale = 1.0;
            sUnit  = 'm';
            if dTMag < -1
                dScale = 1.0e2;
                sUnit  = 'cm';
            end % if
            if dTMag < -2
                dScale = 1.0e3;
                sUnit  = 'mm';
            end % if

            if dSimPos < dPStart
                sReturn = sprintf('at %0.2f %s Before Plasma',(dPStart-dSimPos)*dLFac*dScale,sUnit);
            end % if

            if dSimPos >= dPStart && dSimPos <= dPEnd
                sReturn = sprintf('at %0.2f %s Into Plasma',(dSimPos-dPStart)*dLFac*dScale,sUnit);
            end % if

            if dSimPos > dPEnd
                sReturn = sprintf('at %0.2f %s After Plasma',(dSimPos-dPEnd)*dLFac*dScale,sUnit);
            end % if

        end % function

    end % methods

    %
    % Private Methods
    %
    
    methods(Access='private')
        
        function [dScale, sUnit] = fLengthScale(~, sToUnit, sFromUnit)

            dScale = 1.0;
            sUnit  = 'm';

            if nargin < 2
                sFromUnit = 'm';
            end % if

            switch(lower(sFromUnit))
                case 'pm'
                    dScale = dScale * 1.0e-12;
                case 'å'
                    dScale = dScale * 1.0e-10;
                case 'nm'
                    dScale = dScale * 1.0e-9;
                case 'um'
                    dScale = dScale * 1.0e-6;
                case 'µm'
                    dScale = dScale * 1.0e-6;
                case 'mm'
                    dScale = dScale * 1.0e-3;
                case 'cm'
                    dScale = dScale * 1.0e-2;
                case 'm'
                    dScale = dScale * 1.0;
                case 'km'
                    dScale = dScale * 1.0e3;
            end % switch

            switch(lower(sToUnit))
                case 'pm'
                    dScale = dScale * 1.0e12;
                    sUnit  = 'pm';
                case 'å'
                    dScale = dScale * 1.0e10;
                    sUnit  = 'Å';
                case 'nm'
                    dScale = dScale * 1.0e9;
                    sUnit  = 'nm';
                case 'um'
                    dScale = dScale * 1.0e6;
                    sUnit  = 'µm';
                case 'µm'
                    dScale = dScale * 1.0e6;
                    sUnit  = 'µm';
                case 'mm'
                    dScale = dScale * 1.0e3;
                    sUnit  = 'mm';
                case 'cm'
                    dScale = dScale * 1.0e2;
                    sUnit  = 'cm';
                case 'm'
                    dScale = dScale * 1.0;
                    sUnit  = 'm';
                case 'km'
                    dScale = dScale * 1.0e-3;
                    sUnit  = 'km';
            end % switch

        end % function

    end % methods

    %
    % Protected Methods
    %
    
    methods(Access='protected')
        
        function stReturn = fParseGridData1D(obj, aData, iStart, iAverage, varargin)

            % Input/Output
            stReturn = {};
            
            % Parse input
            oOpt = inputParser;
            addParameter(oOpt, 'GridDiag', {});
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            iDim       = obj.Dim;
            iSliceAxis = obj.SliceAxis;

            % Check if data is already sliced
            if numel(stOpt.GridDiag) == 3
                if strcmpi(stOpt.GridDiag{1},'slice')
                    iDim       = 2;
                    iSliceAxis = str2num(stOpt.GridDiag{2}(2));
                end % if
            end % if

            % Dimensions

            if ndims(aData) ~= iDim || iDim == 1
                return;
            end % if
            
            switch iSliceAxis
                case 1
                    sHAxis = 'x2';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x2');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 2
                    sHAxis = 'x1';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 3
                    sHAxis = 'x1';
                    sVAxis = 'x2';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x2');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
            end % switch

            if iDim == 3
                switch iSliceAxis
                    case 1
                        aData  = squeeze(aData(obj.Slice,:,:));
                    case 2
                        aData  = squeeze(aData(:,obj.Slice,:));
                    case 3
                        aData  = squeeze(aData(:,:,obj.Slice));
                end % switch
            end % if
            
            % Get H-Limits
            iHMin  = fGetIndex(aHAxis, aHLim(1));
            iHMax  = fGetIndex(aHAxis, aHLim(2));
            
            % Get V-Limits
            iVN    = numel(aVAxis);
            if ~obj.Cylindrical
                iStart = iStart+iVN/2;
            end % if

            % Crop Dataset
            iEnd   = iStart+iAverage-1;
            aData  = squeeze(mean(aData(iHMin:iHMax,iStart:iEnd),2));
            aHAxis = aHAxis(iHMin:iHMax);
            
            % Return Data
            stReturn.Data  = aData;
            stReturn.HAxis = aHAxis;
            stReturn.HLim  = [iHMin iHMax];
            stReturn.VLim  = [aVAxis(iStart) aVAxis(iEnd+1)];
            stReturn.Axes  = {sHAxis,sVAxis};

        end % function
        
        function stReturn = fParseGridData2D(obj, aData, varargin)
            
            % Input/Output
            stReturn = {};
            
            % Parse input
            oOpt = inputParser;
            addParameter(oOpt, 'SignFlip', false);
            addParameter(oOpt, 'GridDiag', {});
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            iDim       = obj.Dim;
            iSliceAxis = obj.SliceAxis;

            % Check if data is already sliced
            if numel(stOpt.GridDiag) == 3
                if strcmpi(stOpt.GridDiag{1},'slice')
                    iDim       = 2;
                    iSliceAxis = str2num(stOpt.GridDiag{2}(2));
                end % if
            end % if

            % Dimensions

            if ndims(aData) ~= iDim || iDim == 1
                return;
            end % if

            switch iSliceAxis
                case 1
                    sHAxis = 'x2';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x2');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 2
                    sHAxis = 'x1';
                    sVAxis = 'x3';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x3');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X3Lim(1)*obj.AxisFac(3), obj.X3Lim(2)*obj.AxisFac(3)];
                case 3
                    sHAxis = 'x1';
                    sVAxis = 'x2';
                    aHAxis = obj.fGetBoxAxis('x1');
                    aVAxis = obj.fGetBoxAxis('x2');
                    aHLim  = [obj.X1Lim(1)*obj.AxisFac(1), obj.X1Lim(2)*obj.AxisFac(1)];
                    aVLim  = [obj.X2Lim(1)*obj.AxisFac(2), obj.X2Lim(2)*obj.AxisFac(2)];
            end % switch

            if iDim == 3
                switch iSliceAxis
                    case 1
                        aData  = squeeze(aData(obj.Slice,:,:));
                    case 2
                        aData  = squeeze(aData(:,obj.Slice,:));
                    case 3
                        aData  = squeeze(aData(:,:,obj.Slice));
                end % switch
            end % if

            % Check if cylindrical
            if obj.Cylindrical
                if stOpt.SignFlip
                    aData = transpose([-fliplr(aData),aData]);
                else
                    aData = transpose([ fliplr(aData),aData]);
                end % if
                aVAxis = [-fliplr(aVAxis), aVAxis];
            else
                aData = transpose(aData);
            end % if
            
            % Get Limits
            iHMin = fGetIndex(aHAxis, aHLim(1));
            iHMax = fGetIndex(aHAxis, aHLim(2));
            iVMin = fGetIndex(aVAxis, aVLim(1));
            iVMax = fGetIndex(aVAxis, aVLim(2));

            % Crop Dataset
            aData  = aData(iVMin:iVMax,iHMin:iHMax);
            aHAxis = aHAxis(iHMin:iHMax);
            aVAxis = aVAxis(iVMin:iVMax);
            
            % Return Data
            stReturn.Data  = aData;
            stReturn.HAxis = aHAxis;
            stReturn.VAxis = aVAxis;
            stReturn.HLim  = [iHMin iHMax];
            stReturn.VLim  = [iVMin iVMax];
            stReturn.Axes  = {sHAxis,sVAxis};

        end % function
        
        function aReturn = fGetTimeAxis(obj)
            
            iDumps  = obj.Data.MSData.MaxFiles-1;
            
            dPStart = obj.Data.Config.Simulation.PlasmaStart;
            dTFac   = obj.Data.Config.Convert.SI.TimeFac;
            dLFac   = obj.Data.Config.Convert.SI.LengthFac;
            
            aReturn = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
            
        end % function

        function aReturn = fGetBoxAxis(obj, sAxis)
            
            switch sAxis
                case 'x1'
                    dXMin = obj.Data.Config.Simulation.XMin(1);
                    dXMax = obj.Data.Config.Simulation.XMax(1);
                    iNX   = obj.Data.Config.Simulation.Grid(1);
                    dLFac = obj.AxisFac(1);
                case 'x2'
                    dXMin = obj.Data.Config.Simulation.XMin(2);
                    dXMax = obj.Data.Config.Simulation.XMax(2);
                    iNX   = obj.Data.Config.Simulation.Grid(2);
                    dLFac = obj.AxisFac(2);
                case 'x3'
                    dXMin = obj.Data.Config.Simulation.XMin(3);
                    dXMax = obj.Data.Config.Simulation.XMax(3);
                    iNX   = obj.Data.Config.Simulation.Grid(3);
                    dLFac = obj.AxisFac(3);
                otherwise
                    dXMin = 0.0;
                    dXMax = 0.0;
                    iNX   = 0;
                    dLFac = 0;
            end % switch

            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function
        
        function dReturn = fGetZPos(obj)
            
            dLFactor = obj.Data.Config.Convert.SI.LengthFac;
            dTFactor = obj.Data.Config.Convert.SI.TimeFac;
            dPStart  = obj.Data.Config.Simulation.PlasmaStart;
            
            dReturn  = (obj.Time*dTFactor - dPStart)*dLFactor;
            
        end % function
        
        function bReturn = fError(obj)
            
            bReturn = false;
            
            if obj.Error
                
                fprintf(2, 'OsirisType object not initialised properly.\n');
                bReturn = true;
                
            end % if
            
        end % function

        function aReturn = fMomentumToEnergy(obj, aMomentum)
            
            dRQM    = obj.Config.RQM;
            dEMass  = obj.Data.Config.Constants.EV.ElectronMass;
            dPFac   = abs(dRQM)*dEMass;
            aReturn = sqrt(aMomentum.^2 + 1)*dPFac;
            
        end % function
        
        function aReturn = fPruneRaw(obj, aRaw, iVar, dMin, dMax)
            
            % By default do nothing.
            aReturn = aRaw;
            
            if iVar < 1 || iVar > 8 || isempty(dMin) && isempty(dMax)
                return;
            end % if
            
            if ~isempty(dMin)
                aInd = aReturn(:,iVar) < dMin;
                aReturn(aInd,:) = [];
            end % if

            if ~isempty(dMax)
                aInd = aReturn(:,iVar) > dMax;
                aReturn(aInd,:) = [];
            end % if
            
        end % function
        
        function aRaw = fRawToXi(obj, aRaw)

            dOffset = obj.Data.Config.Simulation.TimeStep*obj.Data.Config.Simulation.NDump*obj.Time;
            aRaw(:,1) = aRaw(:,1) - dOffset;
            
        end % function

    end % methods
    
end % classdef
