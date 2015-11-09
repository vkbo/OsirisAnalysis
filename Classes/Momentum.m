
%
% Class Momentum
%   A class to analyse and handle Osiris data related to the momentum and
%   energy of particles
%
% Constructor:
%   oData    : OsirisDara object
%   sSpecies : What species to study
%   Parameter pairs:
%     Units   : 'N' or 'SI'
%     X1Scale : Unit scale on x1 axis. 'Auto', or specify metric unit
%     X2Scale : Unit scale on x2 axis. 'Auto', or specify metric unit
%     X3Scale : Unit scale on x3 axis. 'Auto', or specify metric unit
%
% Set Methods:
%   Time  : Set time dump for dataset. Default is 0.
%   X1Lim : 2D array of limits for x1 axis. Default is full box.
%   X2Lim : 2D array of limits for x2 axis. Default is full box.
%   X3Lim : 2D array of limits for x3 axis. Default is full box.
%
% Public Methods:
%   SigmaEToEMean    : Returns a dataset with mean energy and spread.
%   Evolution        : Returns a dataset of momentum along an axis as a
%                      function of time (plasma length).
%   BeamSlip         : Returns a dataset of information on beam slipping.
%   MomentumToEnergy : Converts a vector of momenta to energy.
%

classdef Momentum

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data      = [];                        % OsirisData dataset
        Species   = '';                        % What species to analyse
        Time      = 0;                         % Current time (dumb number)
        Offset    = 0.0;                       % Coordinates for start of box
        X1Lim     = [];                        % Axes limits x1
        X2Lim     = [];                        % Axes limits x2
        X3Lim     = [];                        % Axes limits x3
        Units     = 'N';                       % Units of axes
        AxisUnits = {'N', 'N', 'N'};           % Units of axes
        AxisScale = {'Auto', 'Auto', 'Auto'};  % Scale of axes
        AxisRange = [0.0 0.0 0.0 0.0 0.0 0.0]; % Max and min of axes
        AxisFac   = [1.0, 1.0, 1.0];           % Axes scale factors
        Coords    = '';                        % Coordinates
        Dim       = 0;                         % Dimensions
        
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
        
        function obj = Momentum(oData, sSpecies, varargin)
            %
            % Momentum
            %   Momentum class constructor
            %
            % Properties:
            %   oData    : OsirisDara object
            %   sSpecies : What species to study
            %   Parameter pairs:
            %     Units   : 'N' or 'SI'
            %     X1Scale : Unit scale on x1 axis. 'Auto', or specify metric unit
            %     X2Scale : Unit scale on x2 axis. 'Auto', or specify metric unit
            %     X3Scale : Unit scale on x3 axis. 'Auto', or specify metric unit
            %  
            
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
            iDim      = obj.Data.Config.Variables.Simulation.Dimensions;
            dLFactor  = obj.Data.Config.Variables.Convert.SI.LengthFac;

            % Set Scale and Units
            obj.AxisScale = {stOpt.X1Scale, stOpt.X2Scale, stOpt.X3Scale};
            obj.Coords    = sCoords;
            obj.Dim       = iDim;

            % Evaluate units (does not support CGS at the moment)
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
            
            % Variables
            dTimeStep = obj.Data.Config.Variables.Simulation.TimeStep;
            iNDump    = obj.Data.Config.Variables.Simulation.NDump;
            dDeltaZ   = dTimeStep*iNDump;

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
            
            obj.Offset = dDeltaZ*obj.Time;
            
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
        
        function stReturn = SigmaEToEMean(obj, sStart, sStop)

            stReturn = {};

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            % Calculate range
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);

            % Calculate axes
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iStop+1);
            
            aMean  = zeros(1, length(aTAxis));
            aSigma = zeros(1, length(aTAxis));
            aData  = zeros(1, length(aTAxis));
            
            for i=iStart:iStop
                
                k = i-iStart+1;
                
                h5Data = obj.Data.Data(i, 'RAW', '', obj.Species);
                
                if length(h5Data(:,8)) == 1 && h5Data(1,8) == 0
                    aMean(k)  = 0.0;
                    aSigma(k) = 0.0;
                    aData(k)  = 0.0;
                else
                    aMean(k)  = obj.MomentumToEnergy(wmean(h5Data(:,4), abs(h5Data(:,8))));
                    aSigma(k) = obj.MomentumToEnergy(wstd(h5Data(:,4), abs(h5Data(:,8))));
                    aData(k)  = aSigma(k)/aMean(k);
                end % if
                
            end % for
            
            % Return data
            stReturn.TimeAxis = aTAxis;
            stReturn.Mean     = aMean;
            stReturn.Sigma    = aSigma;
            stReturn.Data     = aData;

        end % function

        function stReturn = Evolution(obj, sAxis, sStart, sStop, varargin)

            stReturn = {};
            
            if nargin < 3
                sStart = 'Start';
            end % if

            if nargin < 4
                sStop = 'End';
            end % if
            
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);

            oOpt = inputParser;
            addParameter(oOpt, 'Percentile', []);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            % Read simulation data
            dEMass = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;

            % Calculate axes
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iStop+1);

            stReturn.TimeAxis = aTAxis;

            switch(fMomentumAxis(sAxis))
                case 'p1'
                    iAxis = 4;
                case 'p2'
                    iAxis = 5;
                case 'p3'
                    iAxis = 6;
            end % switch
            
            for i=iStart:iStop
                
                k = i-iStart+1;

                aRAW = obj.Data.Data(i, 'RAW', '', obj.Species)*dEMass;

                stReturn.Average(k) = double(wmean(aRAW(:,iAxis),aRAW(:,8)));
                stReturn.Median(k)  = wprctile(aRAW(:,iAxis),50,abs(aRAW(:,8)));
                
                if ~isempty(stOpt.Percentile)
                    for p=1:length(stOpt.Percentile)
                        c = stOpt.Percentile(p);
                        if c < 1 || c > 100
                            continue;
                        end % if
                        sSet = sprintf('Percentile%d', c);
                        stReturn.(sSet)(k) = wprctile(aRAW(:,iAxis),c,abs(aRAW(:,8)));
                    end % for
                end % if

            end % for
    
        end % function

        function stReturn = BeamSlip(obj, sStart, sStop, dAdd)

            stReturn = {};

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if

            if nargin < 4
                dAdd = 0.0;
            end % if
            
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);
            
            % Variables
            dLFac     = obj.AxisFac(1);
            dTimeStep = obj.Data.Config.Variables.Simulation.TimeStep;
            iNDump    = obj.Data.Config.Variables.Simulation.NDump;
            dDeltaZ   = dTimeStep*iNDump;
            
            for i=iStart:iStop
                
                k = i-iStart+1;

                aRaw = obj.Data.Data(i, 'RAW', '', obj.Species);

                stReturn.Slip.Average(k)           = (dDeltaZ - dDeltaZ*sqrt(1-1/wmean(aRaw(:,4),aRaw(:,8))^2))*dLFac;
                stReturn.Slip.Median(k)            = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),50,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.Percentile10(k)      = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),10,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.Percentile90(k)      = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),90,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.FirstQuartile(k)     = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),25,abs(aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.ThirdQuartile(k)     = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRaw(:,4),75,abs(aRaw(:,8)))^2))*dLFac;

                stReturn.Position.Average(k)       = (wmean(aRaw(:,1),aRaw(:,8))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Median(k)        = (wprctile(aRaw(:,1),50,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Percentile10(k)  = (wprctile(aRaw(:,1),10,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Percentile90(k)  = (wprctile(aRaw(:,1),90,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.FirstQuartile(k) = (wprctile(aRaw(:,1),25,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.ThirdQuartile(k) = (wprctile(aRaw(:,1),75,abs(aRaw(:,8)))-(i*dDeltaZ))*dLFac;
                
                if k > 1
                    stReturn.ExpectedPos.Average(k)       = stReturn.Position.Average(1)       - sum(stReturn.Slip.Average(1:k-1));
                    stReturn.ExpectedPos.Median(k)        = stReturn.Position.Median(1)        - sum(stReturn.Slip.Median(1:k-1));
                    stReturn.ExpectedPos.Percentile10(k)  = stReturn.Position.Percentile10(1)  - sum(stReturn.Slip.Percentile10(1:k-1));
                    stReturn.ExpectedPos.Percentile90(k)  = stReturn.Position.Percentile90(1)  - sum(stReturn.Slip.Percentile90(1:k-1));
                    stReturn.ExpectedPos.FirstQuartile(k) = stReturn.Position.FirstQuartile(1) - sum(stReturn.Slip.FirstQuartile(1:k-1));
                    stReturn.ExpectedPos.ThirdQuartile(k) = stReturn.Position.ThirdQuartile(1) - sum(stReturn.Slip.ThirdQuartile(1:k-1));
                else
                    stReturn.ExpectedPos.Average(1)       = stReturn.Position.Average(1);
                    stReturn.ExpectedPos.Median(1)        = stReturn.Position.Median(1);
                    stReturn.ExpectedPos.Percentile10(1)  = stReturn.Position.Percentile10(1);
                    stReturn.ExpectedPos.Percentile90(1)  = stReturn.Position.Percentile90(1);
                    stReturn.ExpectedPos.FirstQuartile(1) = stReturn.Position.FirstQuartile(1);
                    stReturn.ExpectedPos.ThirdQuartile(1) = stReturn.Position.ThirdQuartile(1);
                end % if
                
                % Slip if added energy
                stReturn.Slip.AverageAdd(k) = (dDeltaZ - dDeltaZ*sqrt(1-1/(dAdd + wmean(aRaw(:,4),aRaw(:,8)))^2))*dLFac;
                stReturn.Slip.MedianAdd(k)  = (dDeltaZ - dDeltaZ*sqrt(1-1/(dAdd + wprctile(aRaw(:,4),50,abs(aRaw(:,8))))^2))*dLFac;
                if k > 1
                    stReturn.ExpectedAdd.Average(k) = stReturn.Position.Average(1) - sum(stReturn.Slip.AverageAdd(1:k-1));
                    stReturn.ExpectedAdd.Median(k)  = stReturn.Position.Median(1)  - sum(stReturn.Slip.MedianAdd(1:k-1));
                else
                    stReturn.ExpectedAdd.Average(1) = stReturn.Position.Average(1);
                    stReturn.ExpectedAdd.Median(1)  = stReturn.Position.Median(1);
                end % if
                
            end % for
            
            aTAxis = obj.fGetTimeAxis;
            
            stReturn.DeltaZ = dDeltaZ;
            stReturn.TAxis  = aTAxis(iStart+1:iStop+1);
    
        end % function

        function stReturn = PhaseSpace(obj, varargin)
            
            stReturn = {};

            oOpt = inputParser;
            addParameter(oOpt, 'Samples',      1);
            addParameter(oOpt, 'MinParticles', 100000);
            addParameter(oOpt, 'Histogram',    'No');
            addParameter(oOpt, 'Grid',         [1000 1000]);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            aRaw   = obj.Data.Data(obj.Time, 'RAW', '', obj.Species);
            aP     = sqrt(aRaw(:,4).^2 + aRaw(:,5).^2 + aRaw(:,6).^2);
            iLen   = length(aP);
            aERMS  = zeros(stOpt.Samples, 1);
            aENorm = zeros(stOpt.Samples, 1);
            
            aRX   = [];
            aRXP  = [];
            aRQ   = [];
            aGam  = [];
            
            iMin  = ceil(stOpt.MinParticles/iLen);
            if stOpt.Samples < iMin
                iS = iMin;
            else
                iS = stOpt.Samples;
            end % if

            for s=1:iS

                if obj.Dim == 2
                    aXth = rand(size(aRaw,1),1)*2*pi;
                else
                    aXth = aRaw(:,3);
                end % if

                if strcmpi(obj.Coords, 'cylindrical')
                    aPz  = aRaw(:,4);
                    aPr  = aRaw(:,5);
                    aPth = aRaw(:,6);
                    aPx  = aPr.*cos(aXth) - aPth.*sin(aXth);
                    aX   = aRaw(:,2).*cos(aXth)*obj.AxisFac(2);
                else
                    aPz  = aRaw(:,4);
                    aPx  = aRaw(:,5);
                    aX   = aRaw(:,2)*obj.AxisFac(2);
                end % if
 
                aGamma    = obj.MomentumToEnergy(aPz);
                aXPrime   = sin(aPx./aP)*1e3;
                aCharge   = aRaw(:,8)*obj.Data.Config.Variables.Convert.SI.ChargeFac;
                aCov      = wcov([aX, aXPrime], abs(aCharge));
                dGamma    = wmean(aGamma, abs(aCharge));
                dBeta     = sqrt(1 - 1/dGamma^2);
                aERMS(s)  = sqrt(det(aCov));
                aENorm(s) = sqrt(det(aCov))*dGamma*dBeta;
            
                if strcmpi(obj.Coords, 'cylindrical')
                    aX      = [-aX;aX];
                    aXPrime = [-aXPrime;aXPrime];
                    aCharge = [aCharge;aCharge];
                end % if
                
                if length(aRX) < stOpt.MinParticles
                    aRX  = [aRX;aX];
                    aRXP = [aRXP;aXPrime];
                    aRQ  = [aRQ;aCharge];
                end % if

            end % for
            
            iNE = length(aERMS) - 1;
            iNE = iNE + (iNE == 0);
            
            stReturn.Raw        = aRaw;
            stReturn.X          = aRX;
            stReturn.XUnit      = obj.AxisUnits{1};
            stReturn.XPrime     = aRXP;
            stReturn.XPrimeUnit = 'mrad';
            stReturn.Charge     = aRQ;
            stReturn.Weight     = abs(aRQ)/max(abs(aRQ));
            stReturn.Covariance = aCov;
            stReturn.ERMS       = mean(aERMS);
            stReturn.ERMSError  = 1.96*std(aERMS)/sqrt(iNE);
            stReturn.ENorm      = mean(aENorm);
            stReturn.ENormError = 1.96*std(aENorm)/sqrt(iNE);
            
            if strcmpi(stOpt.Histogram, 'No')
                return;
            end % if
            
            aHist   = zeros(stOpt.Grid(1),stOpt.Grid(2));
            
            dXMax   = max(abs(aRX));
            dXPMax  = max(abs(aRXP));
            dXMin   = -dXMax;
            dXPMin  = -dXPMax;

            dDX     = dXMax/((stOpt.Grid(1)-2)/2);
            dDXP    = dXPMax/((stOpt.Grid(2)-2)/2);
            aM      = floor(aRX/dDX)+(stOpt.Grid(1)/2)+1;
            aN      = floor(aRXP/dDXP)+(stOpt.Grid(2)/2)+1;
            
            for i=1:length(aM)
                aHist(aM(i),aN(i)) = aHist(aM(i),aN(i)) + aRQ(i);
            end % for
            
            stReturn.Hist   = abs(transpose(aHist))*1e9;
            stReturn.X1Axis = linspace(dXMin,dXMax,stOpt.Grid(1));
            stReturn.X2Axis = linspace(dXPMin,dXPMax,stOpt.Grid(2));
            stReturn.Count  = iLen*iMin;
            
        end % function
    
        function aReturn = MomentumToEnergy(obj, aMomentum)
            
            sType   = fSpeciesType(obj.Species);
            dRQM    = obj.Data.Config.Variables.(sType).(obj.Species).RQM;
            dEMass  = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;

            dPFac   = abs(dRQM)*dEMass;
            aReturn = sqrt(aMomentum.^2 + 1)*dPFac;
            
        end % function

    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function aReturn = fGetTimeAxis(obj)
            
            iDumps  = obj.Data.Elements.FLD.e1.Info.Files-1;
            
            dPStart = obj.Data.Config.Variables.Plasma.PlasmaStart;
            dTFac   = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dLFac   = obj.Data.Config.Variables.Convert.SI.LengthFac;
            
            aReturn = (linspace(0.0, dTFac*iDumps, iDumps+1)-dPStart)*dLFac;
            
        end % function

        function aReturn = fGetDiagAxis(obj, sAxis)
            
            sType = fSpeciesType(obj.Species);
            
            switch sAxis
                case 'x1'
                    dXMin = obj.Data.Config.Variables.(sType).(obj.Species).DiagX1Min;
                    dXMax = obj.Data.Config.Variables.(sType).(obj.Species).DiagX1Max;
                    iNX   = obj.Data.Config.Variables.(sType).(obj.Species).DiagNX1;
                    dLFac = obj.AxisFac(1);
                case 'x2'
                    dXMin = obj.Data.Config.Variables.(sType).(obj.Species).DiagX2Min;
                    dXMax = obj.Data.Config.Variables.(sType).(obj.Species).DiagX2Max;
                    iNX   = obj.Data.Config.Variables.(sType).(obj.Species).DiagNX2;
                    dLFac = obj.AxisFac(2);
                case 'x3'
                    dXMin = obj.Data.Config.Variables.(sType).(obj.Species).DiagX3Min;
                    dXMax = obj.Data.Config.Variables.(sType).(obj.Species).DiagX3Max;
                    iNX   = obj.Data.Config.Variables.(sType).(obj.Species).DiagNX3;
                    dLFac = obj.AxisFac(3);
            end % switch

            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function
        
    end % methods

end % classdef
