%
%  Class Object to analyse E-fields
% **********************************
%

classdef EField

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data      = [];                       % OsirisData dataset
        Time      = 0;                        % Current time (dumb number)
        X1Lim     = [];                       % Axes limits x1
        X2Lim     = [];                       % Axes limits x2
        X3Lim     = [];                       % Axes limits x3
        Units     = 'N';                      % Units of axes
        AxisUnits = {'N', 'N', 'N'};          % Units of axes
        AxisScale = {'Auto', 'Auto', 'Auto'}; % Scale of axes
        AxisFac   = [1.0, 1.0, 1.0];          % Axes scale factors
        
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
        
        function obj = EField(oData, varargin)
            
            % Set data
            obj.Data = oData;

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


            % Evaluate units
            switch(lower(stOpt.Units))

                case 'si'
                    obj.Units         = 'SI';
                    [dX1Fac, sX1Unit] = fLengthScale(obj.AxisScale{1}, 'm');
                    [dX2Fac, sX2Unit] = fLengthScale(obj.AxisScale{2}, 'm');
                    [dX3Fac, sX3Unit] = fLengthScale(obj.AxisScale{3}, 'm');
                    obj.AxisFac       = [dLFactor*dX1Fac, dLFactor*dX2Fac, dLFactor*dX3Fac];
                    obj.AxisUnits     = {sX1Unit, sX2Unit, sX3Unit};

                otherwise
                    obj.Units   = 'N';
                    obj.AxisFac = [1.0, 1.0, 1.0];
                    if strcmpi(sCoords, 'cylindrical')
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'rad'};
                    else
                        obj.AxisUnits = {'c/\omega_p', 'c_/\omega_p', 'c/\omega_p'};
                    end % if

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
             
            if length(aX1Lim) ~= 2
                fprintf(2, 'Error: x1 limit needs to be a vector of dimension 2.\n');
                return;
            end % if
             
            obj.X1Lim = aX1Lim/obj.AxisFac(1);
             
        end % function
         
        function obj = set.X2Lim(obj, aX2Lim)
 
            if length(aX2Lim) ~= 2
                fprintf(2, 'Error: x2 limit needs to be a vector of dimension 2.\n');
                return;
            end % if
             
            obj.X2Lim = aX2Lim/obj.AxisFac(2);
             
        end % function
 
        function obj = set.X3Lim(obj, aX3Lim)
 
            if length(aX3Lim) ~= 2
                fprintf(2, 'Error: x3 limit needs to be a vector of dimension 2.\n');
                return;
            end % if
             
            obj.X3Lim = aX3Lim/obj.AxisFac(3);
             
        end % function

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function SigmaEToEMean(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            fprintf('Test: %d\n', fStringToDump(obj.Data, 'End'));

        end % function

        function FieldEvolution(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);
            
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iStop+1);
            
            for i=iStart:iStop
                
                
                
            end % for
        
        end % function
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function aTAxis = fGetTimeAxis(obj);
            
            iDumps  = obj.Data.Elements.FLD.e1.Info.Files-1;
            
            dPStart = obj.Data.Config.Variables.Plasma.PlasmaStart;
            dTFac   = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dLFac   = obj.Data.Config.Variables.Convert.SI.LengthFac;
            
            aTAxis = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
            
        end % function
    
    end % methods

end % classdef
