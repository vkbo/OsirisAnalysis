%
%  Class Object :: Analyse Species Charge
% ****************************************
%

classdef Charge

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data    = [];  % OsirisData dataset
        Species = '';  % What species to ananlyse
        Time    = 0;   % Current time (dumb number)
        ZLim    = [];  % Z axis limits
        RLim    = [];  % R axis limits
        ZZero   = '';  % Zero point on Z axis
        Units   = 'N'; % Unit of axes
        ZScale  = 1.0; % Scale of Z axis
        RScale  = 1.0; % Scale of R axis
        
    end % properties

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')
        
        ZFac = 1.0; % Z axis scale factor
        RFac = 1.0; % R axis scale factor

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Charge(oData, sSpecies)
            
            if nargin < 2
                sSpecies = 'EB';
            end % if
            
            obj.Data    = oData;
            obj.Species = fTranslateSpecies(sSpecies);
            
            dBoxX1Min = obj.Data.Config.Variables.Simulation.BoxX1Min;
            dBoxX1Max = obj.Data.Config.Variables.Simulation.BoxX1Max;
            dBoxX2Max = obj.Data.Config.Variables.Simulation.BoxX2Max;
            
            obj.ZLim = [ dBoxX1Min, dBoxX1Max];
            obj.RLim = [-dBoxX2Max, dBoxX2Max];
            
        end % function
        
    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function obj = set.Data(obj, oData)

            obj.Data = oData;
            
        end % function
        
        function obj = set.Species(obj, sSpecies)
            
            obj.Species = fTranslateSpecies(sSpecies);
            
        end % function
        
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
        
        function obj = set.ZLim(obj, aZLim)
            
            if length(aZLim) ~= 2
                fprintf(2, 'Error: Z limit needs to be a vector of dimension 2.\n');
                return;
            end % if
            
            obj.ZLim = aZLim/obj.ZScale;
            
        end % function
        
        function obj = set.RLim(obj, aRLim)

            if length(aRLim) ~= 2
                fprintf(2, 'Error: R limit needs to be a vector of dimension 2.\n');
                return;
            end % if
            
            if aRLim(1) < 0
                aRLim(1) = 0;
            end % if
            
            obj.RLim = aRLim/obj.RScale;
            
        end % function

        function obj = set.Units(obj, sUnits)
            
            switch(lower(sUnits))
                
                case 'n'
                    obj.Units = 'N';
                case 'norm'
                    obj.Units = 'N';
                case 'normalised'
                    obj.Units = 'N';
                case 'normalized'
                    obj.Units = 'N';
                    
                case 'si'
                    obj.Units = 'SI';
                    obj.ZScale = 'm';
                    obj.RScale = 'm';
                    
            end % switch
            
        end % function
        
        function obj = set.ZScale(obj, sUnit)
            
            dScale   = 1.0;
            dLFactor = obj.Data.Config.Variables.Convert.SI.LengthFac;
            
            switch(obj.Units)
                case 'N'
                    dScale = dScale * 1.0;
                case 'SI'
                    dScale = dScale * dLFactor;
            end % switch
            
            obj.ZFac = dScale*fLengthScale(sUnit);
            obj.ZLim = obj.ZLim*obj.ZFac;
            
        end % function
        
        function obj = set.RScale(obj, sUnit)
            
            dScale   = 1.0;
            dLFactor = obj.Data.Config.Variables.Convert.SI.LengthFac;
            
            switch(obj.Units)
                case 'N'
                    dScale = dScale * 1.0;
                case 'SI'
                    dScale = dScale * dLFactor;
            end % switch
            
            obj.RFac = dScale*fLengthScale(sUnit);
            obj.RLim = obj.RLim*obj.RFac;
            
        end % function

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function stReturn = Density(obj)
            
            stReturn = {};
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species);
            if obj.RLim(1) == 0
                aData  = transpose([fliplr(h5Data),h5Data]);
            else
                aData  = transpose(h5Data);
            end % if
            aZAxis = obj.fGetBoxAxis('x1');
            aRAxis = obj.fGetBoxAxis('x2');
            if obj.RLim(1) == 0
                aRAxis = [-fliplr(aRAxis),aRAxis];
            end % if

            iZMin  = fGetIndex(aZAxis, obj.ZLim(1));
            iZMax  = fGetIndex(aZAxis, obj.ZLim(2));
            if obj.RLim(1) == 0
                iRMin  = fGetIndex(aRAxis, -obj.RLim(2));
            else
                iRMin  = fGetIndex(aRAxis, obj.RLim(1));
            end % if
            iRMax  = fGetIndex(aRAxis, obj.RLim(2));

            aData  = aData(iRMin:iRMax,iZMin:iZMax);
            aZAxis = aZAxis(iZMin:iZMax);
            aRAxis = aRAxis(iRMin:iRMax);
            
            stReturn.Data  = aData;
            stReturn.ZAxis = aZAxis;
            stReturn.RAxis = aRAxis;
            stReturn.ZPos  = obj.fGetZPos();
            
        end % function

        function stReturn = Fourier(obj, aRange)
            
            stReturn = {};
            
            if nargin < 2
                aRange = [];
            end % if
            
            dPlasmaFac = obj.Data.Config.Variables.Plasma.MaxPlasmaFac;
            dXMin      = obj.Data.Config.Variables.Simulation.BoxX1Min;
            dXMax      = obj.Data.Config.Variables.Simulation.BoxX1Max;
            dBoxSize   = dXMax-dXMin;
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species);
            if isempty(aRange)
                aProj = abs(sum(transpose(h5Data),1));
            else
                if length(aRange) == 1
                    aProj = abs(sum(transpose(h5Data(:,aRange(1))),1));
                else
                    aProj = abs(sum(transpose(h5Data(:,aRange(1):aRange(1))),1));
                end % if
            end % if

            iLen   = length(aProj);
            iN     = 2^nextpow2(iLen);
            aFFT   = fft(aProj,iN)/iLen;
            aXAxis = 2*pi*iLen/dBoxSize/2*linspace(0,1,iN/2+1)/sqrt(dPlasmaFac);
            
            stReturn.Proj  = aProj;
            stReturn.Data  = 2*abs(aFFT(1:iN/2+1));
            stReturn.XAxis = aXAxis;
            stReturn.ZPos  = obj.fGetZPos();
            
        end % function

        function stReturn = Wavelet(obj, aRange, varargin)
            
            % Input/Output
            
            stReturn = {};
            
            if nargin < 2
                aRange = [];
            end % if

            oOpt = inputParser;
            addParameter(oOpt, 'Octaves', 7);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            

            % Simulation parameters

            dPlasmaFac = obj.Data.Config.Variables.Plasma.MaxPlasmaFac;
            dLFac      = obj.Data.Config.Variables.Convert.SI.LengthFac;
            iBoxNX     = obj.Data.Config.Variables.Simulation.BoxNX1;
            dXMin      = obj.Data.Config.Variables.Simulation.BoxX1Min;
            dXMax      = obj.Data.Config.Variables.Simulation.BoxX1Max;
            dBoxSize   = dXMax-dXMin;

            
            % Get dataset
            
            aData = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species);
            
            if isempty(aRange)
                aProj = abs(sum(transpose(aData),1));
            else
                if length(aRange) == 1
                    aProj = abs(sum(transpose(aData(:,aRange(1))),1));
                else
                    aProj = abs(sum(transpose(aData(:,aRange(1):aRange(1))),1));
                end % if
            end % if
            
            aProj = aProj/max(aProj);
            

            % Wavelet parameters
            
            iN    = length(aProj);
            dZ    = dBoxSize/double(iBoxNX)/sqrt(dPlasmaFac);
            iPad  = 1;
            dDJ   = 0.02;
            dS0   = 2*dZ;
            dJ1   = stOpt.Octaves/dDJ;

            
            % Wavelet
            
            [aWave, aPeriod, aScale, aCOI] = wavelet(aProj, dZ, iPad, dDJ, dS0, dJ1, 'MORLET', 6);
            
            
            % Return
            
            stReturn.Input     = aProj;
            stReturn.Data      = aWave;
            stReturn.Real      = real(aWave);
            stReturn.Imaginary = imag(aWave);
            stReturn.Amplitude = abs(aWave);
            stReturn.Phase     = atan(imag(aWave)/real(aWave));
            stReturn.Power     = abs(aWave).^2;
            stReturn.Period    = aPeriod;
            stReturn.Scale     = aScale;
            stReturn.COI       = aCOI;
            stReturn.XAxis     = obj.fGetBoxAxis('x1');
            stReturn.ZPos      = obj.fGetZPos();
            
        end % function
        
        function stReturn = BeamCharge(obj, sShape, aLimits)
            
            stReturn = {};
            
            if nargin < 3
                aLimits = [];
            end % if
            
            if nargin < 2
                sShape = '';
            end % if
            
            if ~isBeam(obj.Species)
                fprintf(2, 'Error: Species %s is not a beam.\n', obj.Species);
                return;
            end % if
            
            dBoxX1Min = obj.Data.Config.Variables.Simulation.BoxX1Min;
            dBoxX1Max = obj.Data.Config.Variables.Simulation.BoxX1Max;
            dBoxX2Min = obj.Data.Config.Variables.Simulation.BoxX2Min;
            dBoxX2Max = obj.Data.Config.Variables.Simulation.BoxX2Max;
            iBoxNZ    = obj.Data.Config.Variables.Simulation.BoxNX1;
            iBoxNR    = obj.Data.Config.Variables.Simulation.BoxNX2;
            
            dBoxZSize = dBoxX1Max - dBoxX1Min;
            dBoxRSize = dBoxX2Max - dBoxX2Min;
            dBoxNZ    = double(iBoxNZ);
            dBoxNR    = double(iBoxNR);
            
            dRAWFrac  = obj.Data.Config.Variables.Beam.(obj.Species).RAWFraction;
            dLFactor  = obj.Data.Config.Variables.Convert.SI.LengthFac;
            dECharge  = obj.Data.Config.Variables.Constants.ElementaryCharge;
            dN0       = obj.Data.Config.Variables.Plasma.N0;
            dTFactor  = obj.Data.Config.Variables.Convert.SI.TimeFac;

            aRaw      = obj.Data.Data(obj.Time, 'RAW', '', obj.Species);
            iCount    = length(aRaw(:,1));
            aRaw(:,1) = aRaw(:,1) - dTFactor*obj.Time;
            
            obj.ZLim/obj.ZFac;
            obj.RLim/obj.RFac;
            
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= obj.ZLim(1)/obj.ZFac & aRaw(:,1) <= obj.ZLim(2)/obj.ZFac);
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= obj.RLim(1)/obj.RFac & aRaw(:,2) <= obj.RLim(2)/obj.RFac);
            
            if strcmpi(sShape, 'ellipse') && length(aLimits) == 4

                dZPos = aLimits(1)/obj.ZFac;
                dRPos = aLimits(2)/obj.RFac;
                dZRad = aLimits(3)/obj.ZFac;
                dRRad = aLimits(4)/obj.RFac;

                % Applying condition:
                aRaw(:,8) = aRaw(:,8).*(((aRaw(:,1)-dZPos).^2/dZRad^2 + (aRaw(:,2)-dRPos).^2/dRRad^2) <= 1);

                stReturn.Box    = 'Ellipse';
                stReturn.Coords = [dZPos, dRPos, dZRad, dRRad];

            end % if
            
            dQ = sum(aRaw(:,8));      % Sum of RAW field q
            dQ = dQ/dRAWFrac;         % Correct for fraction of particles dumped
            dQ = dQ*dN0;              % Plasma density
            dQ = dQ*dLFactor^3;       % Convert from normalised units to unitless
            dQ = dQ*2*pi;             % Cylindrical factor
            dQ = dQ*dBoxRSize/dBoxNR; % Radial cell size
            dQ = dQ*dBoxZSize/dBoxNZ; % Longitudinal cell size
            dQ = dQ*dECharge;         % Convert to coulomb
            dQ = dQ*1e9;              % Convert to nC
            
            iSelCount = nnz(aRaw(:,8));
            dExact    = dQ/sqrt(iCount/dRAWFrac);
            dRelError = abs(dQ/(dRAWFrac*sqrt(iSelCount))-dExact);
            
            stReturn.QTotal         = dQ;
            stReturn.RAWFraction    = dRAWFrac;
            stReturn.RAWCount       = iCount;
            stReturn.SelectionCount = iSelCount;
            stReturn.FractionError  = dRelError;
            
        end % function

        function stReturn = Beamlets(obj, dThreshold)
            
            if nargin < 2
                dThreshold = 0.01;
            end % if
            
            stReturn = {};
            
            if ~isBeam(obj.Species)
                fprintf(2, 'Error: Species %s is not a beam.\n', obj.Species);
                return;
            end % if

            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species);
            
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
                    dLFac = obj.ZFac;
                case 'x2'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX2Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX2Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX2;
                    dLFac = obj.RFac;
                case 'x3'
                    dXMin = obj.Data.Config.Variables.Simulation.BoxX3Min;
                    dXMax = obj.Data.Config.Variables.Simulation.BoxX3Max;
                    iNX   = obj.Data.Config.Variables.Simulation.BoxNX3;
                    dLFac = 1.0;
            end % switch

            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function
        
        function dReturn = fGetZPos(obj)
            
            dLFactor = obj.Data.Config.Variables.Convert.SI.LengthFac;
            dTFactor = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dPStart  = obj.Data.Config.Variables.Plasma.PlasmaStart;
            
            dReturn  = (obj.Time*dTFactor - dPStart)*dLFactor;
            
        end % function

    end % methods

end % classdef

