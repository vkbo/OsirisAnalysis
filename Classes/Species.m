
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
        
        Tags      = [];    % Array of Tags
        TMin      = 0;     % Select time from
        TMax      = 0;     % Select time to
        Tracking  = false; % Track particles in obj.Tags from TMin to TMax
        Progress  = false; % Set to true to display tracking progress

    end % properties

    properties(GetAccess='public', SetAccess='private')
        
        Particles = {};    % Struct of particles
        Count     = 0;     % Number of particles

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Species(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, sSpecies, varargin{:});
            
            obj.TMin = 'Start';
            obj.TMax = 'End';

        end % function
        
    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function obj = set.Tags(obj, aTags)
            
            if ~ismatrix(aTags)
                fprintf(2,'Error: Tags must be a n x 2 size matrix.\n');
                return;
            end % if
            
            [iR,iC] = size(aTags);
            if iC ~= 2
                fprintf(2,'Error: Tags must be a n x 2 size matrix.\n');
                return;
            end % if
            
            obj.Tags  = aTags;
            obj.Count = iR;
            
        end % function
        
        function obj = set.TMin(obj, sTMin)
            
            obj.TMin = obj.Data.StringToDump(sTMin);
            
        end % function

        function obj = set.TMax(obj, sTMax)
            
            obj.TMax = obj.Data.StringToDump(sTMax);
            
        end % function
        
        function obj = set.Tracking(obj, bTracking)
            
            if ~bTracking
                obj.Tracking = false;
                return;
            end % if
                
            if isempty(obj.Tags)
                obj.Tracking = false;
                return;
            end % if
            
            obj.Particles = obj.TrackParticles();
            obj.Tracking  = true;
            
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
        
        function stReturn = TrackParticles(obj)
            
            % Output
            stReturn = {};
            
            nTags = size(obj.Tags,1);
            nTime = obj.TMax-obj.TMin+1;

            if strcmpi(obj.Units,'SI')
                dTFac = obj.Data.Config.Convert.SI.TimeFac;
            else
                dTFac = obj.Data.Config.Simulation.TimeStep*obj.Data.Config.Simulation.NDump;
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
                
                iTime = obj.TMin + t - 1;
                aRaw  = obj.Data.Data(iTime,'RAW','',obj.Species.Name);
                
                for n=1:nTags
                    
                    aPart = aRaw(aRaw(:,9) == obj.Tags(n,1) & aRaw(:,10) == obj.Tags(n,2),:);
                    stReturn(n).Tag(1:2)   = [aPart(9) aPart(10)];
                    stReturn(n).X(t,1:3)   = [aPart(1)-iTime*dTFac aPart(2) aPart(3)];
                    stReturn(n).P(t,1:3)   = [aPart(4) aPart(5) aPart(6)];
                    stReturn(n).Energy(t)  = aPart(7);
                    stReturn(n).Kinetic(t) = aPart(7)*dRQM*aPart(8);
                    stReturn(n).Charge(t)  = aPart(8);
                    stReturn(n).Gamma(t)   = sqrt(aPart(4)^2 + aPart(5)^2 + aPart(6)^2 +1);
                    
                end % for
                
            end % for
            
        end % function
    
    end % methods

end % classdef
