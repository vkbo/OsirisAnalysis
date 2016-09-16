
%
%  Class Object :: Analyse Fields
% ********************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to electric fields.
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
%    Density  : Returns a dataset with a 2D matrix of the density of the field.
%    Lineout  : Returns a dataset with a 1D lineout of the density of the field.
%    Integral : Returns a dataset with the integrated field over an interval
%               of time dumps.
%

classdef Field < OsirisType

    %
    % Properties
    %

    properties(GetAccess='public', SetAccess='private')
        
        FieldVar  = {};  % Holds field information
        FieldFac  = 1.0; % Field scale factor
        FieldUnit = 'N'; % Field base unit
        
    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = Field(oData, sField, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, 'None', varargin{:});

            % Set Field
            stField = obj.Translate.Lookup(sField);
            if stField.isValidEMFDiag
                obj.FieldVar = stField;
            else
                fprintf(2, 'Error: ''%s'' is not a recognised field. Using ''e1'' instead.\n', sField);
                obj.FieldVar = obj.Translate.Lookup('e1');
            end % if
            
            if strcmpi(obj.Units,'SI')
                if obj.FieldVar.isEField || obj.FieldVar.isEFieldExt || obj.FieldVar.isEFieldPart
                    obj.FieldFac  = obj.Data.Config.Convert.SI.E0;
                end % if
                if obj.FieldVar.isBField || obj.FieldVar.isBFieldExt || obj.FieldVar.isBFieldPart
                    obj.FieldFac  = obj.Data.Config.Convert.SI.B0;
                end % if
                obj.FieldUnit = obj.FieldVar.Unit;
            end % if
            
        end % function
        
    end % methods

    %
    % Public Methods
    %
    
    methods(Access = 'public')
        
        function stReturn = Density2D(obj)

            % Input/Output
            stReturn = {};
            
            % Get Data and Parse it
            aData = obj.Data.Data(obj.Time, 'FLD', obj.FieldVar.Name, '');
            if isempty(aData)
                return;
            end % if

            stData = obj.fParseGridData2D(aData,~(obj.FieldVar.Dim == 1));
            
            if isempty(stData)
                return;
            end % if

            % Scale Dataset
            if strcmpi(obj.Units, 'SI')
                dScale = obj.FieldFac;
                sUnit  = obj.FieldVar.Unit;
                sLabel = obj.FieldVar.Tex;
                switch(obj.FieldVar.Name)
                    case 'psi'
                        dScale = 1/max(abs(stData.Data(:)));
                end % switch
            else
                dScale = 1.0;
                sUnit  = '';
            end % if

            % Return Data
            stReturn.Data  = stData.Data*dScale;
            stReturn.HAxis = stData.HAxis;
            stReturn.VAxis = stData.VAxis;
            stReturn.Axes  = stData.Axes;
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
            
            % Get Data and Parse it
            aData = obj.Data.Data(obj.Time,'FLD',obj.FieldVar.Name,'');
            if isempty(aData)
                return;
            end % if

            stData = obj.fParseGridData1D(aData,iStart,iAverage);

            if isempty(stData)
                return;
            end % if

            % Return Data
            stReturn.Data   = stData.Data*obj.FieldFac;
            stReturn.HAxis  = stData.HAxis;
            stReturn.HRange = stData.HLim;
            stReturn.VRange = stData.VLim;
            stReturn.ZPos   = obj.fGetZPos();        
        
        end % function
        
        function stReturn = Potential2D(obj, sPotential)
            
            % Input/Output
            stReturn = {};
            
            stPot = obj.Translate.Lookup(sPotential,'Potential');
            if ~stPot.isPotential
                fprintf(2, 'Error: ''%s'' is not a recognised potential. Using ''w1'' instead.\n', sPotential);
                stPot = obj.Translate.Lookup('w1');
            end % if
            
            % Extract the beta values for the direction of simulation movement
            aMove = obj.Data.Config.Simulation.Moving;
            
            % Extract parallel e-field
            switch(stPot.Name)
                case 'w1'
                    aE    = obj.Data.Data(obj.Time, 'FLD', 'e1', '');
                    bSign = false;
                case 'w2'
                    aE    = obj.Data.Data(obj.Time, 'FLD', 'e2', '');
                    bSign = true;
                case 'w3'
                    aE    = obj.Data.Data(obj.Time, 'FLD', 'e3', '');
                    bSign = true;
            end % switch
            
            % If parallel e-field doesn't exist, return empty
            if isempty(aE)
                return;
            end % if
            
            aB1 = 0.0;
            aB2 = 0.0;

            % Extract ortogonal b-fields – partial derivatives
            switch(stPot.Name)
                case 'w1'
                    if aMove(2) ~= 0.0
                        aB1 = aMove(2) * obj.Data.Data(obj.Time, 'FLD', 'b3', '');
                    end % if
                    if aMove(3) ~= 0.0
                        aB2 = aMove(3) * obj.Data.Data(obj.Time, 'FLD', 'b2', '');
                    end % if
                case 'w2'
                    if aMove(3) ~= 0.0
                        aB1 = aMove(3) * obj.Data.Data(obj.Time, 'FLD', 'b1', '');
                    end % if
                    if aMove(1) ~= 0.0
                        aB2 = aMove(1) * obj.Data.Data(obj.Time, 'FLD', 'b3', '');
                    end % if
                case 'w3'
                    if aMove(1) ~= 0.0
                        aB1 = aMove(1) * obj.Data.Data(obj.Time, 'FLD', 'b2', '');
                    end % if
                    if aMove(2) ~= 0.o
                        aB2 = aMove(2) * obj.Data.Data(obj.Time, 'FLD', 'b1', '');
                    end % if
            end % switch
            
            aW = aE + aB1 - aB2;
            
            % Slice the data
            stData = obj.fParseGridData2D(aW,bSign);
            if isempty(stData)
                return;
            end % if
            
            dScale = obj.Data.Config.Convert.SI.E0;
            
            % Return Data
            stReturn.Data  = stData.Data*dScale;
            stReturn.HAxis = stData.HAxis;
            stReturn.VAxis = stData.VAxis;
            stReturn.Axes  = stData.Axes;
            stReturn.ZPos  = obj.fGetZPos();        
            
        end % function
        
        function stReturn = Integral(obj, sStart, sStop, aRange)

            % Input/Output
            stReturn = {};

            if nargin < 2
                sStart = 'PStart';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if

            if nargin < 4
                aRange = [];
            end % if

            iStart = obj.Data.StringToDump(sStart);
            iStop  = obj.Data.StringToDump(sStop);

            % Get simulation variables
            dTFac = obj.Data.Config.Convert.SI.TimeFac;
            dLFac = obj.Data.Config.Convert.SI.LengthFac;
            
            % Set axes
            aVAxis = [];
            aRAxis = [];
            aVLim  = [];
            sVUnit = 'N';
            sTUnit = 'm';

            switch(obj.FieldVar.Dim)

                case 1
                    dVFac  = obj.AxisFac(1);
                    sVUnit = obj.AxisUnits{1};
                    aVAxis = obj.fGetBoxAxis('x1');
                    aRAxis = obj.fGetBoxAxis('x2');
                    aVLim  = [fGetIndex(aVAxis, obj.X1Lim(1)*obj.AxisFac(1)) ...
                              fGetIndex(aVAxis, obj.X1Lim(2)*obj.AxisFac(1))];
                    
                    if isempty(aRange) || ~length(aRange) == 2
                        aRange = [3 3];
                    else
                        if aRange(1) < 1
                            aRange(1) = 1;
                        end % if
                        if aRange(2) > length(aRAxis)
                            aRange(2) = length(aRAxis);
                        end % if
                    end % if

                case 2
                    dVFac  = obj.AxisFac(2);
                    sVUnit = obj.AxisUnits{2};
                    aVAxis = obj.fGetBoxAxis('x2');
                    aRAxis = obj.fGetBoxAxis('x1');
                    aVLim  = [fGetIndex(aVAxis, obj.X2Lim(1)*obj.AxisFac(2)) ...
                              fGetIndex(aVAxis, obj.X2Lim(2)*obj.AxisFac(2))];

                    if isempty(aRange) || ~length(aRange) == 2
                        aRange = [1 10];
                    else
                        if aRange(1) < 1
                            aRange(1) = 1;
                        end % if
                        if aRange(2) > length(aRAxis)
                            aRange(2) = length(aRAxis);
                        end % if
                    end % if
                    
                case 3
                    return;

            end % switch
            
            aTAxis  = obj.fGetTimeAxis;
            aTAxis  = aTAxis(iStart+1:iStop+1);
            dTDiff  = aTAxis(end)-aTAxis(1);
            aVRange = [aVAxis(1) aVAxis(end)];
            aVAxis  = aVAxis(aVLim(1):aVLim(2));
            
            % Extract data
            aEnergy = zeros(length(aVAxis),length(aTAxis));
            for t=iStart:iStop
                
                aData = obj.Data.Data(t,'FLD',obj.FieldVar.Name,'');
                if isempty(aData)
                    return;
                end % if

                switch(obj.FieldVar.Name)
                    case 'e1'
                        aEnergy(:,t-iStart+1) = mean(aData(aVLim(1):aVLim(2),aRange(1):aRange(2)),2);
                    case 'e2'
                        aEnergy(:,t-iStart+1) = mean(aData(aRange(1):aRange(2),aVLim(1):aVLim(2)),1);
                end % switch
                
            end % for

            % Return data
            stReturn.Energy    = aEnergy*obj.FieldFac;
            stReturn.Integral  = cumtrapz(aEnergy,2)*obj.FieldFac*dTFac*dLFac;
            stReturn.GainFac   = 1/dTDiff;
            stReturn.VAxis     = aVAxis;
            stReturn.TAxis     = aTAxis;
            stReturn.VUnit     = sVUnit;
            stReturn.TUnit     = sTUnit;
            stReturn.AxisFac   = [1.0 dVFac];
            stReturn.AxisRange = [iStart iStop aVRange];
        
        end % function
        
    end % methods

end % classdef
