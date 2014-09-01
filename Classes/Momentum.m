%
%  Class Object :: Analyse Beam Momentum
% ***************************************
%

classdef Momentum

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data = []; % OsirisData dataset
        Beam = ''; % What beam to ananlyse
        
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
        
        function obj = Momentum(oData, sBeam)
            
            if nargin < 2
                sBeam = 'EB';
            end % if
            
            obj.Data = oData;
            obj.Beam = fTranslateSpecies(sBeam);
            
        end % function
        
    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function obj = set.Data(obj, oData)

            obj.Data = oData;
            
        end % function
        
        function obj = set.Beam(obj, sBeam)
            
            obj.Beam = fTranslateSpecies(sBeam);
            
        end % function

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function SigmaEToEMean(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            fprintf('Test: %d\n', fStringToDump(obj.Data, 'End'));

        end % function

        function TimeEvolution(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);
            
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iStop+1);
            
            for i=iStart:iStop
                
                
                
            end % for
        
        end % function

        function stReturn = TimeSpaceEvolution(obj, sPDim, sSDim, sStart, sStop)

            % Set default values
            
            stReturn = {};
            
            if nargin < 2
                sPDim = 'p1';
            end % if

            if nargin < 3
                sSDim = 'x1';
            end % if
            
            if nargin < 4
                sStart = 'Start';
            end % if

            if nargin < 5
                sStop = 'End';
            end % if
            

            % Check for legal values

            if ~ismember(sPDim, {'p1', 'p2', 'p3'})
                fprintf('Error: Unknown momentum axis\n');
                return;
            end % if

            if ~ismember(sSDim, {'x1', 'x2', 'x3'})
                fprintf('Error: Unknown spatial axis\n');
                return;
            end % if
            
            
            % Calculate range

            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);
            

            % Calculate axes
            
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iStop+1);
            aSAxis = obj.fGetSpaceAxis(sSDim);
            
            for i=iStart:iStop
                
                
                
            end % for
            
            
            stReturn.TimeAxis  = aTAxis;
            stReturn.SpaceAxis = aSAxis;
        
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

        function aReturn = fGetSpaceAxis(obj, sAxis)
            
            switch sAxis
                case 'x1'
                    dXMin = obj.Data.Config.Variables.Beam.(obj.Beam).DiagX1Min;
                    dXMax = obj.Data.Config.Variables.Beam.(obj.Beam).DiagX1Max;
                    iNX   = obj.Data.Config.Variables.Beam.(obj.Beam).DiagNX1;
                case 'x2'
                    dXMin = obj.Data.Config.Variables.Beam.(obj.Beam).DiagX2Min;
                    dXMax = obj.Data.Config.Variables.Beam.(obj.Beam).DiagX2Max;
                    iNX   = obj.Data.Config.Variables.Beam.(obj.Beam).DiagNX2;
                case 'x3'
                    dXMin = obj.Data.Config.Variables.Beam.(obj.Beam).DiagX3Min;
                    dXMax = obj.Data.Config.Variables.Beam.(obj.Beam).DiagX3Max;
                    iNX   = obj.Data.Config.Variables.Beam.(obj.Beam).DiagNX3;
            end % switch

            dLFac   = obj.Data.Config.Variables.Convert.SI.LengthFac;
            aReturn = linspace(dXMin, dXMax, iNX)*dLFac;
            
        end % function

    end % methods

end % classdef
