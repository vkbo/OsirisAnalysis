
%
%  Class Object :: Species
% *************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to (macro) particles
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

classdef Species < OsirisType

    %
    % Properties
    %

    properties(GetAccess='public', SetAccess='public')
        
        Progress = false; % Print progress for loops over many time steps

    end % properties

    %
    % Constructor, Set and Get
    %

    methods
        
        function obj = Species(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, sSpecies, varargin{:});

        end % function
        
        function obj = set.Progress(obj, bProgress)
            
            if bProgress
                obj.Progress = true;
            else
                obj.Progress = false;
            end % if
            
        end % function
        
    end % methods

    %
    % Public Methods
    %
    
    methods(Access='public')
        
        function stReturn = EnergyChange(obj, varargin)
        
            % Input/Output
            stReturn = {};
            
            oOpt = inputParser;
            addParameter(oOpt, 'Start',   obj.Time-1);
            addParameter(oOpt, 'End',     obj.Time);
            addParameter(oOpt, 'Unit',    'Joule');
            addParameter(oOpt, 'ZLim',    []);
            addParameter(oOpt, 'CutPrev', 'No');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            iStart = obj.Data.StringToDump(stOpt.Start);
            iEnd   = obj.Data.StringToDump(stOpt.End);
            nTime  = iEnd-iStart;
            
            % This does not work for datadump 0
            if iStart < 0
                fprintf(2,'Error: Cannot calculate energy difference for data dump 0.\n');
                return;
            end % if
            
            % Simulation data and conversion factors
            if strcmpi(obj.Units, 'SI')
                if strcmpi(stOpt.Unit, 'Joule')
                    dEFac = obj.Data.Config.Constants.EV.ElectronMass*obj.Data.Config.Constants.SI.ElementaryCharge;
                    sUnit = 'J';
                else
                    dEFac = obj.Data.Config.Constants.EV.ElectronMass;
                    sUnit = 'eV';
                end % if
            else
                dEFac = 1.0;
                sUnit = 'N';
            end % if
            
            if obj.Cylindrical
                dEFac = dEFac*2*pi;
            end % if
            
            % Prepare data arrays
            aTotal   = zeros(nTime,1);
            aDelta   = zeros(nTime,1);
            aMissing = zeros(nTime,1);
            aCount   = zeros(nTime,3);

            if obj.Progress
                fprintf('Progress   0.0%%');
            end % if
            
            for t=1:nTime

                % Load RAW data
                aRawC = obj.Data.Data(iStart+t,  'RAW','',obj.Species.Name);
                aRawP = obj.Data.Data(iStart+t-1,'RAW','',obj.Species.Name);
                
                % Remove particles outside Z limits
                if ~isempty(stOpt.ZLim)
                    aRawC((aRawC(:,1) < stOpt.ZLim(1) & aRawC(:,1) > stOpt.ZLim(2)),:) = [];
                    if strcmpi(stOpt.CutPrev, 'Yes')
                        aRawP((aRawP(:,1) < stOpt.ZLim(1) & aRawP(:,1) > stOpt.ZLim(2)),:) = [];
                    end % if
                end % if
                
                % Remove particles outsie box limits
                dTDump = obj.Data.Config.Simulation.TimeStep*obj.Data.Config.Simulation.NDump;
                
                aRawC(:,1) = aRawC(:,1) - dTDump*(iStart+t);
                aRawC((aRawC(:,1) < obj.X1Lim(1) & aRawC(:,1) > obj.X1Lim(2)),:) = [];
                aRawC((aRawC(:,2) < obj.X2Lim(1) & aRawC(:,2) > obj.X2Lim(2)),:) = [];
                if obj.Dim == 3
                    aRawC((aRawC(:,3) >= obj.X3Lim(1) & aRawC(:,3) <= obj.X3Lim(2)),:) = [];
                end % if

                if strcmpi(stOpt.CutPrev, 'Yes')
                    aRawP(:,1) = aRawP(:,1) - dTDump*(iStart+t-1);
                    aRawP((aRawP(:,1) < obj.X1Lim(1) & aRawP(:,1) > obj.X1Lim(2)),:) = [];
                    aRawP((aRawP(:,2) < obj.X2Lim(1) & aRawP(:,2) > obj.X2Lim(2)),:) = [];
                    if obj.Dim == 3
                        aRawP((aRawP(:,3) >= obj.X3Lim(1) & aRawP(:,3) <= obj.X3Lim(2)),:) = [];
                    end % if
                end % if

                % Create unique single column tag arrays
                iTMax = max([max(aRawC(:,10)) max(aRawP(:,10))]);
                aTagC = aRawC(:,9)*iTMax+aRawC(:,10);
                aTagP = aRawP(:,9)*iTMax+aRawP(:,10);

                % Find indices with same particles in each dataset
                [~,aIndC,aIndP] = intersect(aTagC,aTagP);

                % Calculate delta and missing energy
                aTotal(t)      = sum(aRawC(:,7).*aRawC(:,8));
                aDelta(t)      = sum(aRawC(aIndC,7).*aRawC(aIndC,8)-aRawP(aIndP,7).*aRawP(aIndP,8));
                aRawP(aIndP,7) = 0;
                aMissing(t)    = sum(aRawP(:,7).*aRawP(:,8));
                aCount(t,1:3)  = [size(aRawC,1) size(aRawP,1) size(aRawP,1)-size(aIndP,1)];
                
                % Print progress
                if obj.Progress
                    fprintf('\b\b\b\b\b\b%5.1f%%',100*t/nTime);
                end % if

            end % for

            if obj.Progress
                fprintf('\n');
            end % if
            
            % Get time axis
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+2:iEnd+1);
            
            % Return results
            stReturn.Total     = aTotal*obj.Config.RQM*dEFac;
            stReturn.Delta     = aDelta*obj.Config.RQM*dEFac;
            stReturn.Missing   = aMissing*obj.Config.RQM*dEFac;
            stReturn.Unit      = sUnit;
            stReturn.TAxis     = aTAxis;
            stReturn.CountCurr = aCount(:,1);
            stReturn.CountPrev = aCount(:,2);
            stReturn.CountLost = aCount(:,3);
            
            % Debug
            stReturn.RawC = aRawC;
            stReturn.RawP = aRawP;

        end % function
        
        function stReturn = TrackParticles(obj, aTags, varargin)
            
            % Input/Output
            stReturn = {};
            
            oOpt = inputParser;
            addParameter(oOpt, 'Start', obj.Time);
            addParameter(oOpt, 'End',   obj.Time);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

            nTags  = size(aTags,1);
            iStart = obj.Data.StringToDump(stOpt.Start);
            iEnd   = obj.Data.StringToDump(stOpt.End);
            nTime  = iEnd-iStart+1;

            if ~ismatrix(aTags) || size(aTags,2) ~= 2
                fprintf(2,'Error: Tags must be a n x 2 size matrix.\n');
                return;
            end % if

            % Get Conversion Factors
            if strcmpi(obj.Units,'SI')
                dTFac = obj.Data.Config.Convert.SI.TimeFac;
                dLFac = obj.Data.Config.Convert.SI.LengthFac;
                dMFac = obj.Data.Config.Constants.EV.ElectronMass;
            else
                dTFac = obj.Data.Config.Simulation.TimeStep*obj.Data.Config.Simulation.NDump;
                dLFac = 1.0;
                dMFac = 1.0;
            end % if
            dRQM = obj.Config.RQM;
            
            stReturn(nTags).Tag     = [];
            stReturn(nTags).X       = [];
            stReturn(nTags).P       = [];
            stReturn(nTags).Energy  = [];
            stReturn(nTags).Kinetic = [];
            stReturn(nTags).Charge  = [];
            stReturn(nTags).Gamma   = [];

            for t=1:nTime
                
                iTime = iStart + t - 1;
                aRaw  = obj.Data.Data(iTime,'RAW','',obj.Species.Name);
                
                for n=1:nTags
                    
                    aPart = aRaw(aRaw(:,9) == aTags(n,1) & aRaw(:,10) == aTags(n,2),:);
                    stReturn(n).Tag(1:2)   = [aPart(9) aPart(10)];
                    stReturn(n).X(t,1:3)   = [aPart(1)-iTime*dTFac aPart(2) aPart(3)]*dLFac;
                    stReturn(n).P(t,1:3)   = [aPart(4) aPart(5) aPart(6)];
                    stReturn(n).Energy(t)  = aPart(7);
                    stReturn(n).Kinetic(t) = aPart(7)*dRQM*aPart(8)*dMFac;
                    stReturn(n).Charge(t)  = aPart(8);
                    stReturn(n).Gamma(t)   = sqrt(aPart(4)^2 + aPart(5)^2 + aPart(6)^2 +1);
                    
                end % for
                
            end % for
            
        end % function
    
    end % methods

end % classdef
