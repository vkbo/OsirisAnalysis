
%
%  Class Object :: Analyse Density
% *********************************
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
%      Scale   : Unit scale on all axes. 'Auto', or specify metric unit
%
%  Set Methods:
%    Time      : Set time dump for dataset. Default is 0.
%    X1Lim     : 2D array of limits for x1 axis. Default is full box.
%    X2Lim     : 2D array of limits for x2 axis. Default is full box.
%    X3Lim     : 2D array of limits for x3 axis. Default is full box.
%    SliceAxis : 2D slice axis for 3D data
%    Slice     : 2D slice coordinate for 3D data
%
%  Public Methods:
%

classdef Density < OsirisType

    %
    % Properties
    %

    properties(GetAccess = 'public', SetAccess = 'public')
        
        % None

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Density(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, sSpecies, varargin{:});

        end % function

    end % methods

    %
    % Public Methods
    %
    
    methods(Access = 'public')
        
        function stReturn = Density2D(obj, sDensity)
            
            % Input/Output
            stReturn = {};
            
            if nargin < 2
                sDensity = 'charge';
            end % if
            
            % Check that the object is initialised
            if obj.fError
                return;
            end % if
            
            % Density Diag
            vDensity = obj.Translate.Lookup(sDensity);
            if ~vDensity.isValidSpeciesDiag
                fprintf(2,'Error: Not a valid density diagnostics.\n');
                return;
            end % if
            
            % Get Data and Parse it
            aData = obj.Data.Data(obj.Time, 'DENSITY', vDensity.Name, obj.Species.Name);
            if isempty(aData)
                return;
            end % if

            stData = obj.fParseGridData2D(aData);

            if isempty(stData)
                return;
            end % if
            
            % Scale Dataset
            if strcmpi(obj.Units, 'SI')
                sUnit  = vDensity.Unit;
                sLabel = vDensity.Tex;
                switch(vDensity.Name)
                    case 'charge'
                        dScale = 1/obj.Data.Config.Simulation.MaxPlasmaFac;
                        sUnit  = 'n/n_0';
                        sLabel = '\rho';
                    case 'm'
                        dScale = 1/obj.Data.Config.Simulation.MaxPlasmaFac;
                        sUnit  = 'n/n_0';
                    case 'ene'
                        dScale = 1.0; % Not implemented
                    case 'q1'
                        dScale = 1.0; % Not implemented
                    case 'q2'
                        dScale = 1.0; % Not implemented
                    case 'q3'
                        dScale = 1.0; % Not implemented
                    case 'j1'
                        dScale = obj.Data.Config.Convert.SI.JFac(1);
                    case 'j2'
                        dScale = obj.Data.Config.Convert.SI.JFac(2);
                    case 'j3'
                        dScale = obj.Data.Config.Convert.SI.JFac(3);
                end % switch
            else
                dScale = 1.0;
                sUnit  = '';
            end % if
            
            % Return Data
            stReturn.Data  = stData.Data*dScale;
            stReturn.Unit  = sUnit;
            stReturn.Label = sLabel;
            stReturn.Axes  = stData.Axes;
            stReturn.HAxis = stData.HAxis;
            stReturn.VAxis = stData.VAxis;
            stReturn.ZPos  = obj.fGetZPos();
            
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

            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            % Get Data and Parse it
            aData = obj.Data.Data(obj.Time,'DENSITY','charge',obj.Species.Name);
            if isempty(aData)
                return;
            end % if

            stData = fParseGridData1D(aData,iStart,iAverage);

            if isempty(stData)
                return;
            end % if
            
            % Return data
            stReturn.Data   = stData.Data;
            stReturn.HAxis  = stData.HAxis;
            stReturn.HRange = stData.HLim;
            stReturn.VRange = stData.VLim;
            stReturn.ZPos   = obj.fGetZPos();        
        
        end % function
        
        function stReturn = EvolveRaw(obj, varargin)
        
            % Input/Output
            stReturn = {};
            
            oOpt = inputParser;
            addParameter(oOpt, 'Start',  'Start');
            addParameter(oOpt, 'End',    'End');
            addParameter(oOpt, 'Value',  'Charge');
            addParameter(oOpt, 'Method', 'Sum');
            addParameter(oOpt, 'Save',   'No');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            iStart  = obj.Data.StringToDump(stOpt.Start);
            iEnd    = obj.Data.StringToDump(stOpt.End);
            iValue  = obj.Data.RawToIndex(stOpt.Value);
            sMethod = lower(stOpt.Method);
            
            % Read variables
            dTFac  = obj.Data.Config.Convert.SI.TimeFac;
            dRFrac = obj.Data.Config.Particles.Species.(obj.Species.Name).RawFraction;
            
            aX1Lim = obj.X1Lim;
            aX2Lim = obj.X2Lim;
            if obj.Cylindrical
                aX2Lim(1) = 0.0;
            end % if
            
            aData = zeros(1,iEnd-iStart+1);
            aStd  = zeros(1,iEnd-iStart+1);
            aNumA = zeros(1,iEnd-iStart+1);
            aNumB = zeros(1,iEnd-iStart+1);

            % Time Loop
            for t=iStart:iEnd
                
                i = t-iStart+1;
                
                aRaw = obj.Data.Data(t,'RAW','',obj.Species.Name);
                if isempty(aRaw)
                    return;
                end % if

                aRaw(:,1) = aRaw(:,1) - t*dTFac;
                aNumA(i)  = size(aRaw,1);
                
                % Removing elements outside box
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= aX1Lim(1) & aRaw(:,1) <= aX1Lim(2));
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= aX2Lim(1) & aRaw(:,2) <= aX2Lim(2));
                aRaw      = aRaw(aRaw(:,8)~=0,:);
                aNumB(i)  = size(aRaw,1);
                
                switch(sMethod)
                    case 'sum'
                        aData(i) = sum(aRaw(:,iValue))/dRFrac;
                    case 'mean'
                        aData(i) = wmean(aRaw(:,iValue),aRaw(:,8));
                    case 'max'
                        aData(i) = max(abs(aRaw(:,iValue)));
                    case 'min'
                        aData(i) = min(abs(aRaw(:,iValue)));
                end % switch
                
                aStd(i) = wstd(aRaw(:,iValue),aRaw(:,8));

            end % for
            
            sUnit = 'N';
            if strcmpi(obj.Units,'SI')
                if     iValue == 1 || iValue == 2 || iValue == 3
                    aData = aData*obj.AxisFac(iValue);
                    aStd  = aStd*obj.AxisFac(iValue);
                    sUnit = obj.AxisUnits{iValue};
                elseif iValue == 4 || iValue == 5 || iValue == 6
                    dFac  = obj.Data.Config.Constants.EV.ElectronMass;
                    dFac  = dFac*abs(obj.Config.RQM);
                    aData = aData*dFac;
                    aStd  = aStd*dFac;
                    sUnit = 'eV/c';
                elseif iValue == 7
                    dFac  = obj.Data.Config.Constants.EV.ElectronMass;
                    dFac  = dFac*abs(obj.Config.RQM);
                    aData = aData*dFac;
                    aStd  = aStd*dFac;
                    sUnit = 'eV/c^2';
                elseif iValue == 8
                    dFac  = obj.Data.Config.Convert.SI.ChargeFac;
                    aData = aData*dFac;
                    aStd  = aStd*dFac;
                    sUnit = 'C';
                end % if
            end % if
            
            aAxis = obj.fGetTimeAxis;
            aAxis = aAxis(iStart+1:iEnd+1);
            
            % Return Data
            stReturn.Data   = aData;
            stReturn.Sigma  = aStd;
            stReturn.Axis   = aAxis;
            stReturn.Unit   = sUnit;
            stReturn.Count  = aNumA;
            stReturn.Sample = aNumB;
            
            % Save Data
            if ~strcmpi(stOpt.Save, 'No')
                
                stSave.Data  = stReturn;
                stSave.Start = iStart;
                stSave.End   = iEnd;
                
                cData = {'x1','x2','x3','p1','p2','p3','ene','charge','tag1','tag2'};
                sData = sprintf('%s_%s',sMethod,cData{iValue});
                obj.Data.SaveAnalysis(stSave,'Density','EvolveRaw',obj.Species.Name,sData,-1,stOpt.Save);
                
            end % if

        end % function

        function stReturn = Fourier(obj, aRange)
            
            % Input/Output
            stReturn = {};
            
            if nargin < 2
                aRange = [];
            end % if
            
            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            dPlasmaFac = obj.Data.Config.Simulation.MaxPlasmaFac;
            dXMin      = obj.Data.Config.Simulation.XMin(1);
            dXMax      = obj.Data.Config.Simulation.XMax(1);
            dBoxSize   = dXMax-dXMin;
            
            aData = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);
            if isempty(aData)
                return;
            end % if

            if isempty(aRange)
                aProj = abs(sum(transpose(aData),1));
            else
                if length(aRange) == 1
                    aProj = abs(sum(transpose(aData(:,aRange(1))),1));
                else
                    aProj = abs(sum(transpose(aData(:,aRange(1):aRange(1))),1));
                end % if
            end % if

            iLen   = length(aProj);
            iN     = 2^nextpow2(iLen);
            aFFT   = fft(aProj,iN)/iLen;
            aXAxis = 2*pi*iLen/dBoxSize/2*linspace(0,1,iN/2+1)/sqrt(dPlasmaFac);
            
            stReturn.Proj  = aProj;
            stReturn.Data  = 2*abs(aFFT(1:iN/2+1));
            stReturn.HAxis = aXAxis;
            stReturn.ZPos  = obj.fGetZPos();
            
        end % function

        function stReturn = Wavelet(obj, aRange, varargin)
            
            % Input/Output
            stReturn = {};

            if nargin < 2
                aRange = [];
            end % if

            % Check that the object is initialised
            if obj.fError
                return;
            end % if

            oOpt = inputParser;
            addParameter(oOpt, 'Octaves', 7);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            % Simulation parameters
            dPlasmaFac = obj.Data.Config.Simulation.MaxPlasmaFac;
            dXMin      = obj.Data.Config.Simulation.XMin(1);
            dXMax      = obj.Data.Config.Simulation.XMax(1);
            iBoxNX     = obj.Data.Config.Simulation.Grid(1);
            dBoxSize   = dXMax-dXMin;

            % Get dataset
            aData = obj.Data.Data(obj.Time, 'DENSITY', 'charge', obj.Species.Name);
            if isempty(aData)
                return;
            end % if

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
            stReturn.HAxis     = obj.fGetBoxAxis('x1');
            stReturn.ZPos      = obj.fGetZPos();
            
        end % function
        
        function stReturn = BeamCharge(obj, varargin)
            
            % Input/Output
            stReturn = {};

            % Check that the object is initialised
            if obj.fError
                return;
            end % if

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
            
            dRawFrac  = obj.Data.Config.Particles.Species.(obj.Species.Name).RawFraction;
            dTFactor  = obj.Data.Config.Convert.SI.TimeFac;
            dRQM      = obj.Data.Config.Particles.Species.(obj.Species.Name).RQM;
            dSign     = dRQM/abs(dRQM);
            
            aRaw      = obj.Data.Data(obj.Time, 'RAW', '', obj.Species.Name);
            if isempty(aRaw)
                return;
            end % if

            iCount    = length(aRaw(:,1));
            aRaw(:,1) = aRaw(:,1) - dTFactor*obj.Time;
            
            % Eliminate charge outside box. In cylindrical X2Lim(1) < 0 is 0
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= obj.X1Lim(1) & aRaw(:,1) <= obj.X1Lim(2));
            aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= obj.X2Lim(1) & aRaw(:,2) <= obj.X2Lim(2));
            if obj.Dim == 3
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,3) >= obj.X3Lim(1) & aRaw(:,3) <= obj.X3Lim(2));
            end % if
            
            % Total charge
            
            dQ = sum(aRaw(:,8))/dRawFrac; % Sum of RAW field q
            dP = dQ*obj.ParticleFac;
            dQ = dQ*obj.ChargeFac;
            
            % Meta data
            
            iSCount  = nnz(aRaw(:,8));
            dExact   = dQ/sqrt(iCount/dRawFrac);
            dSErrorQ = abs(dQ/(dRawFrac*sqrt(iSCount))-dExact);
            dSErrorP = abs(dP/(dRawFrac*sqrt(iSCount))-dExact);
            
            % Return data
            
            stReturn.QTotal              = dQ;
            stReturn.Particles           = dP*dSign;
            stReturn.RAWFraction         = dRawFrac;
            stReturn.RAWCount            = iCount;
            stReturn.SampleCount         = iSCount;
            stReturn.ChargeSampleError   = dSErrorQ;
            stReturn.ParticleSampleError = dSErrorP;
            
        end % function

        function stReturn = ParticleSample(obj, varargin)
        
            % Input/Output
            stReturn = {};

            % Check that the object is initialised
            if obj.fError
                return;
            end % if

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
            dEMass = obj.Data.Config.Constants.EV.ElectronMass;
            dRQM   = obj.Data.Config.Particles.Species.(obj.Species.Name).RQM;
            dSign  = dRQM/abs(dRQM);
            
            aRaw = obj.Data.Data(stOpt.Time, 'RAW', '', obj.Species.Name);
            if isempty(aRaw)
                return;
            end % if

            aRaw(:,1) = aRaw(:,1) - obj.BoxOffset;
            if obj.Cylindrical
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
                if obj.Dim == 3
                    aRaw(:,8) = aRaw(:,8).*(aRaw(:,3) >= obj.X3Lim(1) & aRaw(:,3) <= obj.X3Lim(2));
                end % if
                aRaw      = aRaw(aRaw(:,8)~=0,:);

                iCount = stOpt.Sample;
                if iCount > length(aRaw(:,1))
                    iCount = length(aRaw(:,1));
                end % if

                if obj.Cylindrical && strcmpi(stOpt.Mirror, 'Yes')
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
            stReturn.P1      = aRaw(:,4)*dEMass*abs(dRQM);
            stReturn.P2      = aRaw(:,5)*dEMass*abs(dRQM);
            stReturn.P3      = aRaw(:,6)*dEMass*abs(dRQM);
            stReturn.Energy  = aRaw(:,7)*dEMass*abs(dRQM);
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

            % Check that the object is initialised
            if obj.fError
                return;
            end % if

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
