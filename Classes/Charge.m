
%
%  Class Object :: Analyse Charge
% ********************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to the charge
%    and current density of particles.
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
%

classdef Charge < OsirisType

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
        
        function obj = Charge(oData, sSpecies, varargin)
            
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
        
        function stReturn = Density(obj)
            
            % Input/Output
            stReturn = {};

            % Get simulation variables
            dNMax = obj.Data.Config.Variables.Plasma.MaxPlasmaFac;
            
            % Get data and axes
            aData   = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);
            aX1Axis = obj.fGetBoxAxis('x1');
            aX2Axis = obj.fGetBoxAxis('x2');

            % Check if cylindrical
            if obj.Cylindrical
                aData   = transpose([fliplr(aData),aData]);
                aX2Axis = [-fliplr(aX2Axis), aX2Axis];
            else
                aData   = transpose(aData);
            end % if
            
            iX1Min = fGetIndex(aX1Axis, obj.X1Lim(1)*obj.AxisFac(1));
            iX1Max = fGetIndex(aX1Axis, obj.X1Lim(2)*obj.AxisFac(1));
            iX2Min = fGetIndex(aX2Axis, obj.X2Lim(1)*obj.AxisFac(2));
            iX2Max = fGetIndex(aX2Axis, obj.X2Lim(2)*obj.AxisFac(2));

            % Crop and scale dataset
            aData   = aData(iX2Min:iX2Max,iX1Min:iX1Max)/dNMax;
            aX1Axis = aX1Axis(iX1Min:iX1Max);
            aX2Axis = aX2Axis(iX2Min:iX2Max);
            
            % Return data
            stReturn.Data   = aData;
            stReturn.X1Axis = aX1Axis;
            stReturn.X2Axis = aX2Axis;
            stReturn.ZPos   = obj.fGetZPos();
            
        end % function

        function stReturn = Lineout(obj, iStart, iAverage)

            % Input/Output
            stReturn = {};
            
            if nargin < 3
                iAverage = 1;
            end % if
            
            if nargin < 2
                iStart = 3;
            end % if
            
            % Get simulation variables
            dE0     = obj.Data.Config.Variables.Convert.SI.E0;
            
            % Get data and axes
            aData   = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);
            aX1Axis = obj.fGetBoxAxis('x1');
            aX2Axis = obj.fGetBoxAxis('x2');
            
            iX1Min = fGetIndex(aX1Axis, obj.X1Lim(1)*obj.AxisFac(1));
            iX1Max = fGetIndex(aX1Axis, obj.X1Lim(2)*obj.AxisFac(1));
            
            % Crop and scale dataset
            iEnd    = iStart+iAverage-1;
            aData   = transpose(mean(aData(iX1Min:iX1Max,iStart:iEnd),2))*dE0;
            aX1Axis = aX1Axis(iX1Min:iX1Max);
            
            % Return data
            stReturn.Data    = aData;
            stReturn.X1Axis  = aX1Axis;
            stReturn.X1Range = obj.AxisRange(1:2);
            stReturn.X2Range = [aX2Axis(iStart) aX2Axis(iEnd+1)];
            stReturn.ZPos    = obj.fGetZPos();        
        
        end % function

        function stReturn = Current(obj, sAxis)
            
            % Input/Output
            stReturn = {};
            
            sAxis = lower(sAxis);
            if ~ismember(sAxis, {'j1','j2','j3'}) || ~obj.Data.DataSetExists('DENSITY',sAxis,obj.Species.Name)
                fprintf(2, 'Error: Current %s does not exist in dataset.\n', sAxis);
                return;
            end % if

            % Get simulation variables
            sCoords = obj.Data.Config.Variables.Simulation.Coordinates;
            
            if strcmpi(obj.Units, 'SI')
                switch(sAxis)
                    case 'j1'
                        dJFac = obj.Data.Config.Variables.Convert.SI.J1Fac;
                    case 'j2'
                        dJFac = obj.Data.Config.Variables.Convert.SI.J2Fac;
                    case 'j3'
                        dJFac = obj.Data.Config.Variables.Convert.SI.J3Fac;
                end % switch
            else
                dJFac = 1.0;
            end % if
            
            % Get data and axes
            aData   = obj.Data.Data(obj.Time, 'DENSITY', sAxis, obj.Species.Name);
            aX1Axis = obj.fGetBoxAxis('x1');
            aX2Axis = obj.fGetBoxAxis('x2');

            % Check if cylindrical
            if strcmpi(sCoords, 'cylindrical')
                aData   = transpose([fliplr(aData),aData]);
                aX2Axis = [-fliplr(aX2Axis), aX2Axis];
            else
                aData   = transpose(aData);
            end % if
            
            iX1Min = fGetIndex(aX1Axis, obj.X1Lim(1)*obj.AxisFac(1));
            iX1Max = fGetIndex(aX1Axis, obj.X1Lim(2)*obj.AxisFac(1));
            iX2Min = fGetIndex(aX2Axis, obj.X2Lim(1)*obj.AxisFac(2));
            iX2Max = fGetIndex(aX2Axis, obj.X2Lim(2)*obj.AxisFac(2));

            % Crop and scale dataset
            aData   = aData(iX2Min:iX2Max,iX1Min:iX1Max)*dJFac;
            aX1Axis = aX1Axis(iX1Min:iX1Max);
            aX2Axis = aX2Axis(iX2Min:iX2Max);
            
            % Return data
            stReturn.Data   = aData;
            stReturn.X1Axis = aX1Axis;
            stReturn.X2Axis = aX2Axis;
            stReturn.ZPos   = obj.fGetZPos();
            
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
            
            h5Data = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);
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
            aData = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);

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
        
        function stReturn = BeamCharge(obj, varargin)
            
            % Input/Output
            stReturn = {};

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Ellipse', []);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            
            % Species must be a beam
            if ~obj.Species.isBeam
                fprintf(2, 'Error: Species %s is not a beam.\n', obj.Species.Name);
                return;
            end % if
            
            
            dRAWFrac  = obj.Data.Config.Variables.Beam.(obj.Species.Name).RAWFraction;
            dTFactor  = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dRQM      = obj.Data.Config.Variables.Beam.(obj.Species.Name).RQM;
            dSign     = dRQM/abs(dRQM);
            
            aRaw      = obj.Data.Data(obj.Time, 'RAW', '', obj.Species.Name);
            iCount    = length(aRaw(:,1));
            aRaw(:,1) = aRaw(:,1) - dTFactor*obj.Time;
            
            % Eliminate charge outside box. In cylindrical X2Lim(1) < 0 is 0
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= obj.X1Lim(1) & aRaw(:,1) <= obj.X1Lim(2));
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= obj.X2Lim(1) & aRaw(:,2) <= obj.X2Lim(2));
            
            if length(stOpt.Ellipse) == 4

                dXPos = stOpt.Ellipse(1)/obj.AxisFac(1);
                dRPos = stOpt.Ellipse(2)/obj.AxisFac(2);
                dZRad = stOpt.Ellipse(3)/obj.AxisFac(1);
                dRRad = stOpt.Ellipse(4)/obj.AxisFac(2);

                % Applying condition:
                aRaw(:,8) = aRaw(:,8).*(((aRaw(:,1)-dZPos).^2/dZRad^2 + (aRaw(:,2)-dRPos).^2/dRRad^2) <= 1);

                stReturn.Box    = 'Ellipse';
                stReturn.Coords = [dZPos, dRPos, dZRad, dRRad];

            end % if
            
            % Total charge
            
            dQ = sum(aRaw(:,8))/dRAWFrac; % Sum of RAW field q
            dP = dQ*obj.ParticleFac;
            dQ = dQ*obj.ChargeFac;
            
            % Meta data
            
            iSCount  = nnz(aRaw(:,8));
            dExact   = dQ/sqrt(iCount/dRAWFrac);
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

        function stReturn = Beamlets(obj, varargin)
            
            % Input/Output
            stReturn = {};

            % Values
            dMaxPlasma = obj.Data.Config.Variables.Plasma.MaxPlasmaFac;
            sCoords    = obj.Data.Config.Variables.Simulation.Coordinates;
            dRAWFrac   = obj.Data.Config.Variables.Beam.(obj.Species.Name).RAWFraction;
            dTFactor   = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dRQM       = obj.Data.Config.Variables.Beam.(obj.Species.Name).RQM;

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'IgnoreLimits',    'No');
            addParameter(oOpt, 'BeamProminence',  0.5); % In fraction of maximum
            addParameter(oOpt, 'MinPeakDistance', 0.5); % In units of max(lambda_p)
            addParameter(oOpt, 'SmoothSpan',      0.5); % In units of max(lambda_p)
            addParameter(oOpt, 'RadialInclude',   0.9); % How much radial charge to include
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Species must be a beam
            if ~obj.Species.isBeam
                fprintf(2, 'Error: Species %s is not a beam.\n', obj.Species.Name);
                return;
            end % if

            % Load charge density data
            h5Data  = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);
            h5Data  = double(abs(h5Data));
            [nX1,~] = size(h5Data);

            % Get axes
            aX1Axis = obj.fGetBoxAxis('x1');
            aX2Axis = obj.fGetBoxAxis('x2');
            if strcmpi(sCoords, 'Cylindrical')
                aX2Axis = [-fliplr(aX2Axis) aX2Axis];
            end % if

            % Calculate Span value for smooth function and MinPeakDistance for findpeaks
            dSpan     = stOpt.SmoothSpan * 2*pi/sqrt(dMaxPlasma) * obj.AxisFac(1) / (aX1Axis(2)-aX1Axis(1)) / nX1;
            dMinPeakD = stOpt.MinPeakDistance * 2*pi/sqrt(dMaxPlasma) * obj.AxisFac(1) / (aX1Axis(2)-aX1Axis(1));
            
            % Project data onto x1-axis and smooth
            aData   = abs(sum(h5Data,2));
            aSmooth = smooth(aData,dSpan,'loess');

            % Find peaks
            [aPeaks,aLocs,~,aProms] = findpeaks(aSmooth,'MinPeakDistance',dMinPeakD,'WidthReference','HalfHeight');
            
            % Eliminate peaks with prominence below threshold
            dMax   = max(abs(aSmooth));
            dMin   = min(abs(aSmooth));
            dThres = stOpt.BeamProminence*(dMax-dMin)+dMin;
            aPeaks = aPeaks.*(aProms >= dThres);
            aProms = aProms.*(aProms >= dThres);
            aPeaks(aPeaks == 0) = [];
            aProms(aProms == 0) = [];
            
            % Find peak boundaries based on soothed data
            iPeaks = length(aPeaks);
            aSpan  = zeros(2,iPeaks);
            if iPeaks > 0
                [~,iLoc] = min(flipud(aSmooth(1:aLocs(1))));
                aSpan(1,1) = aLocs(1)-iLoc;
                for i=2:iPeaks
                    [~,iLoc] = min(flipud(aSmooth(aLocs(i-1):aLocs(i))));
                    aSpan(1,i) = aLocs(i)-iLoc;
                end % for
                for i=1:iPeaks-1
                    [~,iLoc] = min(aSmooth(aLocs(i):aLocs(i+1)));
                    aSpan(2,i) = aLocs(i)+iLoc;
                end % for
                [~,iLoc] = min(aSmooth(aLocs(end):length(aSmooth)));
                aSpan(2,end) = aLocs(end)+iLoc;
            end % if

            % Preview plot for test purposes
            %figure(2);
            %plot(aData, 'r');
            %hold on;
            %plot(aSmooth,'b','LineWidth',2);
            %scatter(aSpan(1,:), ones(1,length(aSpan(1,:)))*-0.2, 'k+');
            %scatter(aSpan(2,:), ones(1,length(aSpan(2,:)))*-0.3, 'r+');
            %hold off;
            
            % Get RAW data
            aRaw      = obj.Data.Data(obj.Time, 'RAW', '', obj.Species.Name);
            aRaw(:,1) = (aRaw(:,1) - dTFactor*obj.Time)*obj.AxisFac(1);
            
            % Create return matrix
            stBeamlets(iPeaks) = struct();
            for i=1:iPeaks
                
                % X1 Data
                aProj = aData(aSpan(1,i):aSpan(2,i)).';
                aAxis = aX1Axis(aSpan(1,i):aSpan(2,i));
                
                [dMax,iMax] = max(aProj);
                dHalfMax    = dMax/2.0;
                iUpper      = 0;
                iLower      = 0;
                for k=iMax:length(aProj)
                    if aProj(k) <= dHalfMax
                        iUpper = k;
                        break;
                    end % if
                end % for
                for k=iMax:-1:1
                    if aProj(k) <= dHalfMax
                        iLower = k;
                        break;
                    end % if
                end % for

                stBeamlets(i).X1Start = aAxis(1);
                stBeamlets(i).X1Stop  = aAxis(end);
                stBeamlets(i).X1Proj  = aProj;
                stBeamlets(i).X1Peak  = aAxis(iMax);
                stBeamlets(i).X1FWHM  = [aAxis(iLower) aAxis(iUpper)];
                stBeamlets(i).X1Mean  = wmean(aAxis, aProj);
                stBeamlets(i).X1Std   = wstd(aAxis, aProj);
                
                % X2 Data
                aProj = sum(h5Data(aSpan(1,i):aSpan(2,i),:),1);
                aAxis = aX2Axis;
                dAQ     = 0.0;
                dSum    = sum(aProj);
                iRLim   = length(aProj);
                for r=1:length(aProj)
                    dAQ = dAQ + aProj(r);
                    if dAQ >= stOpt.RadialInclude*dSum
                        iRLim = r;
                        break;
                    end % if
                end % for
                if strcmpi(sCoords, 'Cylindrical')
                    aProj = [fliplr(aProj) aProj];
                end % if

                [dMax,iMax] = max(aProj);
                dHalfMax    = dMax/2.0;
                iUpper      = 0;
                iLower      = 0;
                for k=iMax:length(aProj)
                    if aProj(k) <= dHalfMax
                        iUpper = k;
                        break;
                    end % if
                end % for
                for k=iMax:-1:1
                    if aProj(k) <= dHalfMax
                        iLower = k;
                        break;
                    end % if
                end % for

                stBeamlets(i).X2Start = 0.0;
                stBeamlets(i).X2Stop  = iRLim;
                stBeamlets(i).X2Proj  = aProj;
                stBeamlets(i).X2Peak  = aAxis(iMax);
                stBeamlets(i).X2FWHM  = [aAxis(iLower) aAxis(iUpper)];
                stBeamlets(i).X2Mean  = wmean(aX2Axis, stBeamlets(i).X2Proj);
                stBeamlets(i).X2Std   = wstd(aX2Axis, stBeamlets(i).X2Proj);

                % Beamlet Charge
                stBeamlets(i).Charge = sum(aRaw(:,8).*( ...
                                           aRaw(:,1) >= aX1Axis(aSpan(1,i)) & ...
                                           aRaw(:,1) <= aX1Axis(aSpan(2,i))   ...
                                          ))*obj.ChargeFac/dRAWFrac;
            end % for
            
            % Return data
            stReturn.RAWData     = h5Data;
            stReturn.X1Axis      = aX1Axis;
            stReturn.X2Axis      = aX2Axis;
            stReturn.Projection  = aData';
            stReturn.Smooth      = aSmooth';
            stReturn.Peaks       = iPeaks;
            stReturn.Prominence  = transpose(aProms);
            stReturn.Span        = aSpan;
            stReturn.Beamlets    = stBeamlets;
            stReturn.TotalCharge = sum(aRaw(:,8))*obj.ChargeFac/dRAWFrac;
            
        end % function
        
        function stReturn = ParticleSample(obj, varargin)
        
            % Input/Output
            stReturn = {};

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Sample',  200);
            addParameter(oOpt, 'Mirror',  'Yes');    % Mirror x2 axis if cylindrical
            addParameter(oOpt, 'Filter',  'Random'); % Random, WRandom, W2Random, Top, Bottom
            addParameter(oOpt, 'Weights', 'Charge'); % Charge, X1, X2, X3, P1, P2, P3, Energy
            addParameter(oOpt, 'Tags',    []);       % Return these tags instead (for tracking)
            addParameter(oOpt, 'Time',    obj.Time); % Possibility to override object time for internal use
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Read variables
            sCoords   = obj.Data.Config.Variables.Simulation.Coordinates;
            dTFactor  = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dEMass    = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
            dRQM      = obj.Data.Config.Variables.Beam.(obj.Species.Name).RQM;
            dSign     = dRQM/abs(dRQM);
            
            aRaw      = obj.Data.Data(stOpt.Time, 'RAW', '', obj.Species.Name);
            aRaw(:,1) = aRaw(:,1) - dTFactor*stOpt.Time;
            if strcmpi(sCoords, 'cylindrical')
                aRaw(:,8) = aRaw(:,8)./aRaw(:,2);
            end % if
            
            if ~isempty(stOpt.Tags)
                
                [~, iC] = size(stOpt.Tags);
                if iC ~= 2
                    fprintf(2,'Error: Tags matrix must have two columns.\n');
                    return;
                end % if
                
                aRaw(:,12) = ismember(aRaw(:,9:10),stOpt.Tags,'Rows');
                aRaw       = aRaw(aRaw(:,12)~=0,:);
                aRaw(:,11) = aRaw(:,8)*dSign;

            else

                % Removing elements outside box
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= obj.X1Lim(1) & aRaw(:,1) <= obj.X1Lim(2));
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= obj.X2Lim(1) & aRaw(:,2) <= obj.X2Lim(2));
                aRaw      = aRaw(aRaw(:,8)~=0,:);

                iCount = stOpt.Sample;
                if iCount > length(aRaw(:,1))
                    iCount = length(aRaw(:,1));
                end % if

                if strcmpi(sCoords, 'cylindrical') && strcmpi(stOpt.Mirror, 'yes')
                    aRaw = [aRaw; aRaw(:,1) -aRaw(:,2) aRaw(:,3:end)];
                end % if

                aRaw(:,11) = aRaw(:,8)*dSign;
                aRaw(:,12) = abs(aRaw(:,obj.Data.RawToIndex(lower(stOpt.Weights))));
                switch(lower(stOpt.Filter))
                    case 'random'
                        [~,aI]     = datasample(aRaw(:,1),iCount,'Replace',false);
                        aRaw       = aRaw(aI,:);
                    case 'wrandom'
                        aRaw(:,12) = aRaw(:,12)/max(aRaw(:,12));
                        [~,aI]     = datasample(aRaw(:,1),iCount,'Replace',false,'Weights',aRaw(:,12));
                        aRaw       = aRaw(aI,:);
                    case 'w2random'
                        aRaw(:,12) = aRaw(:,12).^2;
                        aRaw(:,12) = aRaw(:,12)/max(aRaw(:,12));
                        [~,aI]     = datasample(aRaw(:,1),iCount,'Replace',false,'Weights',aRaw(:,12));
                        aRaw       = aRaw(aI,:);
                    case 'top'
                        aRaw       = sortrows(aRaw,12);
                        aRaw       = aRaw(end-iCount+1:end,:);
                    case 'bottom'
                        aRaw       = sortrows(aRaw,12);
                        aRaw       = aRaw(1:iCount,:);
                end % switch
                
            end % if
            
            % Return data
            stReturn.X1      = aRaw(:,1)*obj.AxisFac(1);
            stReturn.X2      = aRaw(:,2)*obj.AxisFac(2);
            stReturn.X3      = aRaw(:,3)*obj.AxisFac(3);
            stReturn.P1      = aRaw(:,4)*dEMass;
            stReturn.P2      = aRaw(:,5)*dEMass;
            stReturn.P3      = aRaw(:,6)*dEMass;
            stReturn.Energy  = aRaw(:,7);
            stReturn.Charge  = aRaw(:,8)*obj.ChargeFac;
            stReturn.Tag1    = aRaw(:,9);
            stReturn.Tag2    = aRaw(:,10);
            stReturn.Count   = aRaw(:,11)*obj.ParticleFac;
            stReturn.Norm    = aRaw(:,11)./max(aRaw(:,11));
            stReturn.Weights = aRaw(:,12);
            stReturn.Area    = 7*(0.4 + stReturn.Norm);

        end % function
        
        function stReturn = Tracking(obj, sStart, sStop, varargin)
            
            % Input/Output
            stReturn = {};

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Sample',  10);
            addParameter(oOpt, 'Filter',  'Random'); % Random, WRandom, W2Random, Top, Bottom
            addParameter(oOpt, 'Weights', 'Charge'); % Charge, X1, X2, X3, P1, P2, P3, Energy
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            iStart = obj.Data.StringToDump(sStart);
            iStop  = obj.Data.StringToDump(sStop);
            iSteps = iStop-iStart+1;

            % Get Axes
            aTAxis = obj.fGetTimeAxis;
            
            % Get tags
            stData = obj.ParticleSample('Time',   iStop, ...
                                        'Sample', stOpt.Sample, ...
                                        'Mirror', 'No', ...
                                        'Filter', stOpt.Filter, ...
                                        'Weights',stOpt.Weights);
            aTags = [stData.Tag1 stData.Tag2];
            iTags = length(aTags(:,1));
            
            stTags = struct();
            aMean  = zeros(iStop-iStart+1,8);
            aWMean = zeros(iStop-iStart+1,8);
            aMax   = zeros(iStop-iStart+1,8);
            aMin   = zeros(iStop-iStart+1,8);
            for i=1:iTags
                sTag = sprintf('tag_%d_%d',aTags(i,1),aTags(i,2));
                stTags.(sTag)       = zeros(iSteps,12);
                stTags.(sTag)(:,9)  = aTags(i,1);
                stTags.(sTag)(:,10) = aTags(i,2);
            end % for
            
            fprintf('Tracking: %5.1f%%',0);
            for i=iStart:iStop
                stData = obj.ParticleSample('Time',i,'Tags',aTags);
                iInd   = i-iStart+1;
                iTags  = length(stData.X1);
                aTemp  = [];
                for t=1:iTags
                    sTag = sprintf('tag_%d_%d',stData.Tag1(t),stData.Tag2(t));
                    stTags.(sTag)(iInd,1)  = stData.X1(t);
                    stTags.(sTag)(iInd,2)  = stData.X2(t);
                    stTags.(sTag)(iInd,3)  = stData.X3(t);
                    stTags.(sTag)(iInd,4)  = stData.P1(t);
                    stTags.(sTag)(iInd,5)  = stData.P2(t);
                    stTags.(sTag)(iInd,6)  = stData.P3(t);
                    stTags.(sTag)(iInd,7)  = stData.Energy(t);
                    stTags.(sTag)(iInd,8)  = stData.Charge(t);
                    stTags.(sTag)(iInd,11) = stData.Count(t);
                    stTags.(sTag)(iInd,12) = stData.Weights(t);
                    if stTags.(sTag)(iInd,12)
                        aTemp(end+1,1) = stData.X1(t);
                        aTemp(end,  2) = stData.X2(t);
                        aTemp(end,  3) = stData.X3(t);
                        aTemp(end,  4) = stData.P1(t);
                        aTemp(end,  5) = stData.P2(t);
                        aTemp(end,  6) = stData.P3(t);
                        aTemp(end,  7) = stData.Energy(t);
                        aTemp(end,  8) = stData.Charge(t);
                    end % if
                end % for
                
                if ~isempty(aTemp)
                    aW = abs(aTemp(:,8));
                    aW = aW/sum(aW);
                    for a=1:8
                        aMean(iInd,a)  = mean(aTemp(:,a));
                        aWMean(iInd,a) = wmean(aTemp(:,a),aW);
                        aMin(iInd,a)   = min(aTemp(:,a));
                        aMax(iInd,a)   = max(aTemp(:,a));
                    end % for
                end % if
        
                fprintf('\b\b\b\b\b\b%5.1f%%',100.0*(i-iStart)/(iStop-iStart));
                
            end % for
            fprintf('\n');
            
            stReturn.Data  = stTags;
            stReturn.Mean  = aMean;
            stReturn.WMean = aWMean;
            stReturn.Min   = aMin;
            stReturn.Max   = aMax;
            stReturn.TAxis = aTAxis(iStart+1:iStop+1);
            
        end % function
        
    end % methods
    
end % classdef

