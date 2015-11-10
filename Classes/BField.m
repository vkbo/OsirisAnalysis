
%
%  Class Object :: Analyse B-fields
% **********************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to magnetic fields.
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
%    Density  : Returns a dataset with a 2D matrix of the density of the field.
%

classdef BField < OsirisType

    %
    % Public Properties
    %

    properties(GetAccess = 'public', SetAccess = 'public')
        
        Field = ''; % Field to analyse
        
    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = BField(oData, sField, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, varargin{:});

            % Set field
            sField = fTranslateField(sField);
            if ismember(sField, {'b1','b2','b3'})
                obj.Field = sField;
            else
                obj.Field = 'b1';
                fprintf('Unknown field %s specified, using b1\n', sField);
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
            sCoords = obj.Data.Config.Variables.Simulation.Coordinates;
            dB0     = obj.Data.Config.Variables.Convert.SI.B0;
            
            % Get data and axes
            aData   = obj.Data.Data(obj.Time, 'FLD', obj.Field, '');
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
            aData   = aData(iX2Min:iX2Max,iX1Min:iX1Max)*dB0;
            aX1Axis = aX1Axis(iX1Min:iX1Max);
            aX2Axis = aX2Axis(iX2Min:iX2Max);
            
            % Return data
            stReturn.Data   = aData;
            stReturn.X1Axis = aX1Axis;
            stReturn.X2Axis = aX2Axis;
            stReturn.ZPos   = obj.fGetZPos();        
        
        end % function
    
    end % methods
    
end % classdef
