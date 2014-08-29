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

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = EField(oData)
            
            obj.Data = oData;
            
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
        
        function SigmaEToEMean(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            fprintf('Test: %d\n', fStringToDump(obj.Data, 'End'));

        end % function

        function FieldEvolution(obj, sStart, sStop)

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
        
        end % function
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
    
    end % methods

end % classdef
