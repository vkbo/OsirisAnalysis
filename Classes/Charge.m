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
        
        function stReturn = Density(obj, aLimits)
            
            stReturn = {};
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Beam);
            aData  = transpose([fliplr(h5Data),h5Data]);
            aZAxis = obj.fGetBoxAxis('x1');
            aRAxis = obj.fGetBoxAxis('x2');
            aRAxis = [-fliplr(aRAxis),aRAxis];

            if nargin == 2
                if length(aLimits) == 4
                    iZMin = fGetIndex(aZAxis,aLimits(1));
                    iZMax = fGetIndex(aZAxis,aLimits(2));
                    iRMin = fGetIndex(aRAxis,aLimits(3));
                    iRMax = fGetIndex(aRAxis,aLimits(4));

                    aData  = aData(iRMin:iRMax,iZMin:iZMax);
                    aZAxis = aZAxis(iZMin:iZMax);
                    aRAxis = aRAxis(iRMin:iRMax);
                end % if 
            end % if
            
            stReturn.Data  = aData;
            stReturn.ZAxis = aZAxis;
            stReturn.RAxis = aRAxis;
            stReturn.Zeta  = obj.fGetZeta();
            
        end % function
        
        function stReturn = BeamCharge(obj, aLimits)
            
            stReturn = {};
            
            aRaw     = obj.Data.Data(obj.Time, 'RAW', '', obj.Beam);
            
            dRAWFrac = obj.Data.Config.Variables.Beam.(obj.Beam).RAWFraction;
            dLFactor = obj.Data.Config.Variables.Convert.SI.LengthFac;
            dECharge = obj.Data.Config.Variables.Constants.ElementaryCharge;
            
            if nargin == 2 && length(aLimits) == 4

                dZMin = aLimits(1)/dLFactor;
                dZMax = aLimits(2)/dLFactor;
                dRMin = aLimits(3)/dLFactor;
                dRMax = aLimits(4)/dLFactor;
                
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= dZMin & aRaw(:,1) <= dZMax);
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= dRMin & aRaw(:,2) <= dRMax);
                
            end % if

            if nargin == 2 && length(aLimits) == 2

                [~, iPeak] = max(abs(aRaw(:,8)));
                
                dZPos = aRaw(iPeak,1);
                dRPos = aRaw(iPeak,2);
                dZRad = aLimits(1)/dLFactor;
                dRRad = aLimits(2)/dLFactor;
                
                aZ = aRaw(:,1)-dZPos;
                aR = aRaw(:,2)-dRPos;
                
                aRaw(:,11) = aZ;
                aRaw(:,12) = aR;
                %aRaw(:,13) = 

            end % if

            dQ = sum(aRaw(:,8));   % Sum of RAW field q
            dQ = dQ/dRAWFrac;      % Correct for fraction of particles dumped
            dQ = dQ*1e20;
            dQ = dQ*dLFactor^4;
            %dQ = dQ*8.4083977;
            dQ = dQ*2*pi*1.3382381; %8.4066;
            %dQ = dQ/(dLFactor^3);  % Correct for unit of length
            dQ = dQ*dECharge;      % Convert to coulomb
            %dQ = dQ/99.388;        % Correction factor 100 is uknonwn
            dQ = dQ*1e9;           % Convert to nC
            
            stReturn.QTotal = dQ;
            stReturn.RAW    = aRaw;
            
        end % function

        function stReturn = Beamlets(obj, dThreshold)
            
            if nargin < 2
                dThreshold = 0.01;
            end % if
            
            stReturn = {};
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Beam);
            
            aData = abs(sum(h5Data,2));
            aThreshold = aData/max(aData);
            aThreshold = aThreshold > dThreshold;
            
            aBeamlets = [];
            
            iPrev = 0;
            
            for i=1:length(aData)
                
                if aThreshold(i) == 1 && iPrev == 0
                    aBeamlets(1,end+1) = i;
                end % if
                
                if aThreshold(1) == 0 && iPrev == 1
                    aBeamlets(2,end) = i;
                end % if
                
                iPrev = aThreshold(i);
                
            end % for
            
            if iPrev == 1
                aBeamlet(2,end) = length(aData);
            end % if
            
            dTotal = sum(aData);
            
            aFraction = [];
            
            for i=1:length(aBeamlets(1,:))
                
                aFraction(i) = sum(aData(aBeamlets(1,i):aBeamlets(2,i)))/dTotal;
                
            end % for
            
            dMissing = 1-sum(aFraction);
            
            %stReturn.RAWData   = h5Data;
            %stReturn.Data      = aData;
            %stReturn.Threshold = aThreshold;
            stReturn.Beamlets  = aBeamlets;
            stReturn.Count     = length(aBeamlets(1,:));
            stReturn.Fraction  = aFraction;
            stReturn.Total     = dTotal;
            stReturn.Missing   = dMissing;
            
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
        
        function dReturn = fGetZeta(obj)
            
            dLFactor = obj.Data.Config.Variables.Convert.SI.LengthFac;
            dTFactor = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dPStart  = obj.Data.Config.Variables.Plasma.PlasmaStart;
            
            dReturn  = (obj.Time*dTFactor - dPStart)*dLFactor;
            
        end % function

    end % methods

end % classdef

