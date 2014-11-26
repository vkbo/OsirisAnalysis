%
%  Class Object :: Analyse Species Charge
% ****************************************
%

classdef Charge

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data      = [];                       % OsirisData dataset
        Species   = '';                       % Species to ananlyse
        Time      = 0;                        % Current time (dumb number)
        X1Lim     = [];                       % Axes limits x1
        X2Lim     = [];                       % Axes limits x2
        X3Lim     = [];                       % Axes limits x3
        ZZero     = '';                       % Zero point on Z axis
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
        
        function obj = Charge(oData, sSpecies, varargin)
            
            % Set data and species
            obj.Data    = oData;
            obj.Species = fTranslateSpecies(sSpecies);

            
            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Units',   'N');
            addParameter(oOpt, 'X1Scale', 'Auto');
            addParameter(oOpt, 'X2Scale', 'Auto');
            addParameter(oOpt, 'X3Scale', 'Auto');
            addParameter(oOpt, 'RScale',  '');
            addParameter(oOpt, 'XScale',  '');
            addParameter(oOpt, 'YScale',  '');
            addParameter(oOpt, 'ZScale',  '');
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
            
            if ~isempty(stOpt.RScale)
                obj.AxisScale{2} = stOpt.RScale;
            end % if
            
            if ~isempty(stOpt.XScale)
                obj.AxisScale{3} = stOpt.XScale;
            end % if
            
            if ~isempty(stOpt.YScale)
                obj.AxisScale{2} = stOpt.YScale;
            end % if

            if ~isempty(stOpt.ZScale)
                obj.AxisScale{1} = stOpt.ZScale;
            end % if

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
             
            if aX2Lim(1) < 0
                aX2Lim(1) = 0;
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
        
        function stReturn = Density(obj)
            
            stReturn = {};
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species);
            if obj.X2Lim(1) == 0
                aData  = transpose([fliplr(h5Data),h5Data]);
            else
                aData  = transpose(h5Data);
            end % if
            aZAxis = obj.fGetBoxAxis('x1');
            aRAxis = obj.fGetBoxAxis('x2');
            if obj.X2Lim(1) == 0
                aRAxis = [-fliplr(aRAxis),aRAxis];
            end % if

            iZMin  = fGetIndex(aZAxis, obj.X1Lim(1));
            iZMax  = fGetIndex(aZAxis, obj.X1Lim(2));
            if obj.X2Lim(1) == 0
                iRMin  = fGetIndex(aRAxis, -obj.X2Lim(2));
            else
                iRMin  = fGetIndex(aRAxis, obj.X2Lim(1));
            end % if
            iRMax  = fGetIndex(aRAxis, obj.X2Lim(2));

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
            
            
            dRAWFrac  = obj.Data.Config.Variables.Beam.(obj.Species).RAWFraction;
            dTFactor  = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dRQM      = obj.Data.Config.Variables.Beam.(obj.Species).RQM;
            dSign     = dRQM/abs(dRQM);
            
            aRaw      = obj.Data.Data(obj.Time, 'RAW', '', obj.Species);
            iCount    = length(aRaw(:,1));
            aRaw(:,1) = aRaw(:,1) - dTFactor*obj.Time;
            
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= obj.X1Lim(1)/obj.AxisFac(1) & aRaw(:,1) <= obj.X1Lim(2)/obj.AxisFac(1));
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= obj.X2Lim(1)/obj.AxisFac(2) & aRaw(:,2) <= obj.X2Lim(2)/obj.AxisFac(2));
            
            if strcmpi(sShape, 'ellipse') && length(aLimits) == 4

                dZPos = aLimits(1)/obj.AxisFac(1);
                dRPos = aLimits(2)/obj.AxisFac(2);
                dZRad = aLimits(3)/obj.AxisFac(1);
                dRRad = aLimits(4)/obj.AxisFac(2);

                % Applying condition:
                aRaw(:,8) = aRaw(:,8).*(((aRaw(:,1)-dZPos).^2/dZRad^2 + (aRaw(:,2)-dRPos).^2/dRRad^2) <= 1);

                stReturn.Box    = 'Ellipse';
                stReturn.Coords = [dZPos, dRPos, dZRad, dRRad];

            end % if
            
            % Total charge
            
            dQ = sum(aRaw(:,8));      % Sum of RAW field q
            dQ = dQ/dRAWFrac;         % Correct for fraction of particles dumped

            % Unit conversion
            
            switch obj.Units
                case 'SI'
                    dP = dQ*obj.Data.Config.Variables.Convert.SI.ParticleFac;
                    dQ = dQ*obj.Data.Config.Variables.Convert.SI.ChargeFac;
                case 'N'
                    dP = dQ*obj.Data.Config.Variables.Convert.Norm.ParticleFac;
                    dQ = dQ*obj.Data.Config.Variables.Convert.Norm.ChargeFac;
            end % switch
            
            % Meta data
            
            iSCount = nnz(aRaw(:,8));
            dExact  = dQ/sqrt(iCount/dRAWFrac);
            dSErrorQ = abs(dQ/(dRAWFrac*sqrt(iSCount))-dExact);
            dSErrorP = abs(dP/(dRAWFrac*sqrt(iSCount))-dExact);
            
            % Return data
            
            stReturn.QTotal              = dQ;
            stReturn.Particles           = dP*dSign;
            stReturn.RAWFraction         = dRAWFrac;
            stReturn.RAWCount            = iCount;
            stReturn.SampleCount         = iSCount;
            stReturn.ChargeSampleError   = dSErrorQ;
            stReturn.ParticleSampleError = dSErrorP;
            
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

