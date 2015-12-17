
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
        SliceAxis   = 2;                         % Slice axis (3D)
        Slice       = 0;                         % Slice coordinate (3D)

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
            
            % Read Input Parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Units',   'N');
            addParameter(oOpt, 'X1Scale', 'Auto');
            addParameter(oOpt, 'X2Scale', 'Auto');
            addParameter(oOpt, 'X3Scale', 'Auto');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Set Scale
            obj.AxisScale = {stOpt.X1Scale, stOpt.X2Scale, stOpt.X3Scale};

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
            
            iAxis = floor(iAxis);
            
            if iAxis > 0 && iAxis <= obj.Dim
                obj.SliceAxis = iAxis;
            else
                fprintf(2, 'Error: Not a proper axis.\n');
            end % if
            
        end % function

        function obj = set.Slice(obj, iSlice)
            
            aAxis  = obj.fGetBoxAxis(sprintf('x%d',obj.SliceAxis);
            iSlice = floor(iSlice);
            
            obj.Slice = fGetIndex(aAxis,iSlice);
            
        end % function

    end % methods

    %
    % Public Methods
    %
    
    methods(Access='public')

        function sReturn = PlasmaPosition(obj)

            sReturn = 'Unknown Position';

            dLFactor = obj.Data.Config.Convert.SI.LengthFac;
            dTFactor = obj.Data.Config.Convert.SI.TimeFac;
            iPStart  = obj.Data.StringToDump('PStart');
            iPEnd    = obj.Data.StringToDump('PEnd');

            if obj.Time < iPStart
                sReturn = sprintf('at %0.2f m Before Plasma', (iPStart-obj.Time)*dTFactor*dLFactor);
            end % if

            if obj.Time >= iPStart && obj.Time <= iPEnd
                sReturn = sprintf('at %0.2f m Into Plasma', (obj.Time-iPStart)*dTFactor*dLFactor);
            end % if

            if obj.Time > iPEnd
                sReturn = sprintf('at %0.2f m After Plasma', (obj.Time-iPEnd)*dTFactor*dLFactor);
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

    end % methods
    
end % classdef
