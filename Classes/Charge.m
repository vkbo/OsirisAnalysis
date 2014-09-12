%
%  Class Object :: Analyse Beam Charge
% *************************************
%

classdef Charge

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data = []; % OsirisData dataset
        Beam = ''; % What beam to ananlyse
        Time = 0;  % Current time (dumb number)
        
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
        
        function obj = Charge(oData, sBeam)
            
            if nargin < 2
                sBeam = 'EB';
            end % if
            
            obj.Data = oData;
            obj.Beam = fTranslateSpecies(sBeam);
            
        end % function
        
    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function obj = set.Data(obj, oData)

            obj.Data = oData;
            
        end % function
        
        function obj = set.Beam(obj, sBeam)
            
            obj.Beam = fTranslateSpecies(sBeam);
            
        end % function
        
        function obj = set.Time(obj, sTime)
            
            sTime = num2str(sTime);
            
            iEnd = fStringToDump(obj.Data, 'end');
            
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

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function stReturn = Density(obj)
            
            stReturn = {};
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Beam);
            aData  = transpose([fliplr(h5Data),h5Data]);
            aZAxis = obj.fGetBoxAxis('x1');
            aRAxis = obj.fGetBoxAxis('x2');
            aRAxis = [-fliplr(aRAxis),aRAxis];
            
            stReturn.Data  = aData;
            stReturn.ZAxis = aZAxis;
            stReturn.RAxis = aRAxis;
            
        end % function
        
        function stReturn = BeamCharge(obj)
            
            stReturn = {};
            
            aDensity = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Beam);
            aProj    = obj.Data.Data(obj.Time, 'PHA', 'x1', obj.Beam);
            aRaw     = obj.Data.Data(obj.Time, 'RAW', '', obj.Beam);
            
            dRQM     = obj.Data.Config.Variables.Beam.(obj.Beam).RQM;
            dDensity = obj.Data.Config.Variables.Beam.(obj.Beam).Density;
            dRAWFrac = obj.Data.Config.Variables.Beam.(obj.Beam).RAWFraction;
            
            dQ = sum(aRaw(:,8));
            %dQ = dQ*dRQM;
            dQ = dQ*dRAWFrac;
            %dQ = dQ/0.5;           % Raw factor
            %dQ = dQ/0.25;          % Raw factor
            %dQ = dQ*4;             % PPC
            %dQ = dQ*-1;            % RQM
            %dQ = dQ*1836.1527;     % RQM
            %dQ = dQ*16.7056e-1;       % Density
            %dQ = dQ*0.03922;       % Density
            %dQ = dQ*2*pi;          % Geometry
            %dQ = dQ*1.6022e-10;    % Elementary charge in nC
            %dQ = dQ/(531.41e-6)^2; % c/omega_p
            
            
            stReturn.SumD = sum(aDensity(:));
            stReturn.SumP = sum(aProj);
            stReturn.Proj = aProj;
            stReturn.Raw  = aRaw;
            stReturn.Q    = dQ;
            
        end % function
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function aReturn = fGetTimeAxis(obj)
            
            iDumps  = obj.Data.Elements.DENSITY.(obj.Beam).charge.Info.Files-1;
            
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
                case 'x2'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX2Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX2Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX2;
                case 'x3'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX3Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX3Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX3;
            end % switch

            dLFac   = obj.Data.Config.Variables.Convert.SI.LengthFac;
            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function

    end % methods

end % classdef

