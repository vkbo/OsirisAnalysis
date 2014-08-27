%
%  Class Object to analyse E-fields
% **********************************
%

classdef EField

    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Data = []; % OsirisData dataset
        
    end % properties

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')

        PlotTools = []; % Plot Toolbox

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = EField(oData)
            
            obj.Data      = oData;
            obj.PlotTools = PlotTools();
            
        end % function
        
    end % methods

    %
    % Setters and Getters
    %

    methods

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function PlotSigmaEToEMean(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            fprintf('Test: %d\n', obj.PlotTools.StringToDump(obj.Data, 'PEnd'));
         
        end % function
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
    
    end % methods

end % classdef
