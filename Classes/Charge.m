%
%  Class Object :: Analyse Beam Charge
% *************************************
%

classdef Charge

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
        
        function obj = Charge(oData, sBeam)
            
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
        
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function aReturn = fGetTimeAxis(obj)
            
            iDumps  = obj.Data.Elements.DENSITY.(obj.Beam).charge.Info.Files-1;
            
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

