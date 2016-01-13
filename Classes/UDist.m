
%
%  Class Object :: Analyse UDist
% *******************************
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

classdef UDist < OsirisType

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
        
        function obj = UDist(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, sSpecies, varargin{:});

        end % function

    end % methods

    %
    % Public Methods
    %
    
    methods(Access = 'public')
        
        function stReturn = Density2D(obj, sUDist)
            
            % Input/Output
            stReturn = {};
            
            if nargin < 2
                sUDist = 'ufl1';
            end % if
            
            % Check that the object is initialised
            if obj.fError
                return;
            end % if
            
            % UDist Diag
            vUDist = obj.Translate.Lookup(sUDist);
            if ~vUDist.isValidUDistDiag
                fprintf(2,'Error: Not a valid udist diagnostics.\n');
                return;
            end % if
            
            % Get Data and Parse it
            aData = obj.Data.Data(obj.Time,'UDIST',vUDist.Name,obj.Species.Name);
            if isempty(aData)
                return;
            end % if

            stData = obj.fParseGridData2D(aData);

            if isempty(stData)
                return;
            end % if
            
            % Scale Dataset
            if strcmpi(obj.Units, 'SI')
                sUnit  = vUDist.Unit;
                dScale = obj.Data.Config.Constants.EV.ElectronMass;
                dScale = dScale*obj.Config.RQM;
            else
                sUnit  = 'N';
                dScale = 1.0;
            end % if
            
            % Return Data
            stReturn.Data   = stData.Data*dScale;
            stReturn.Unit  = sUnit;
            stReturn.Label = vUDist.Tex;
            stReturn.Axes  = stData.Axes;
            stReturn.HAxis = stData.HAxis;
            stReturn.VAxis = stData.VAxis;
            stReturn.ZPos  = obj.fGetZPos();
            
        end % function

        function stReturn = Lineout(obj, sUDist, iStart, iAverage)

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
            
            % UDist Diag
            vUDist = obj.Translate.Lookup(sUDist);
            if ~vUDist.isValidUDistDiag
                fprintf(2,'Error: Not a valid udist diagnostics.\n');
                return;
            end % if

            % Get Data and Parse it
            aData = obj.Data.Data(obj.Time,'UDIST',vUDist.Name,obj.Species.Name);
            if isempty(aData)
                return;
            end % if

            stData = fParseGridData1D(aData,iStart,iAverage);

            if isempty(stData)
                return;
            end % if

            % Scale Dataset
            if strcmpi(obj.Units, 'SI')
                sUnit  = vUDist.Unit;
                dScale = 1.0;
            else
                sUnit  = 'N';
                dScale = 1.0;
            end % if
            
            % Return data
            stReturn.Data   = stData.Data*dScale;
            stReturn.Unit   = sUnit;
            stReturn.Label  = vUDist.Tex;
            stReturn.HAxis  = stData.HAxis;
            stReturn.HRange = stData.HLim;
            stReturn.VRange = stData.VLim;
            stReturn.ZPos   = obj.fGetZPos();        
        
        end % function
        
    end % methods
    
end % classdef
