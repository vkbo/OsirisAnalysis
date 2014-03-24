%
%  Class Object to plot Osiris data
% **********************************
%

classdef OsirisPlot
    
    %
    % Public Properties
    %
    
    properties (GetAccess = 'public', SetAccess = 'public')

        Data    = [];
        Units   = 'norm';
        DataSet = {};
        Time    = 0;
        Crop    = [100,100];

    end % properties

    %
    % Constructor
    %
    
    methods
        
        function obj = OsirisPlot(oData)
            obj.Data = oData;
        end % function
        
    end % methods
    
    %
    % Setters an Getters
    %

    methods

        function obj = set.Data(obj, oData)
            obj.Data = oData;
        end % function
        
        function obj = set.Units(obj, sUnits)
            sUnits = lower(sUnits);
            switch(sUnits)
                case 'norm'
                    obj.Units = 'norm';
                case 'normalized'
                    obj.Units = 'norm';
                case 'normalised'
                    obj.Units = 'norm';
                case 'si'
                    obj.Units = 'si';
                case 'cgs'
                    obj.Units = 'cgs';
                otherwise
                    obj.Units = 'norm';
            end % switch
        end % function

        function obj = set.DataSet(obj, stDataSet)
            obj.DataSet = stDataSet;
        end % function
        
        function obj = set.Crop(obj, aCrop)
        
            if ~length(aCrop) == 2 || ~length(aCrop) == 4
                return;
            end % if
            
            

            switch (length(aCrop))
                
                case 2
                    if    aCrop(1) > 0 && aCrop(1) <= 100 ...
                       && aCrop(2) > 0 && aCrop(2) <= 100
                        obj.Crop = aCrop;
                    else
                        frpint('Error in Crop input\n');
                    end % if
                    
                case 4
                    if    aCrop(1) > 0 && aCrop(1) <= 100 ...
                       && aCrop(2) > 0 && aCrop(2) <= 100 ...
                       && aCrop(3) > 0 && aCrop(3) <= 100 ...
                       && aCrop(4) > 0 && aCrop(4) <= 100 ...
                       && aCrop(2) > aCrop(1) ...
                       && aCrop(4) > aCrop(3)
                        obj.Crop = aCrop;
                    else
                        frpint('Error in Crop input\n');
                    end % if

                otherwise
                    fprintf('Wrong crop dimensions. Must be either [xSpan, ySpan] or [xMin, xMax, yMin, yMax].\n');

            end % switch        

        end % function
        
    end % methods
    
    %
    % Public Methods
    %
    
    methods

        function Plot(obj, iTime)
            
            if nargin == 1
                iTime = obj.Time;
            end % if

            % Constants
            dC          = obj.Data.Config.Variables.Constants.SpeedOfLight;

            % Time
            dTimeStep   = obj.Data.Config.Variables.Simulation.TimeStep;
            iNDump      = obj.Data.Config.Variables.Simulation.NDump;
            dTimeFactor = dTimeStep*iNDump;
            dSimTime    = iTime*dTimeFactor;

            % Plasma
            dE0         = obj.Data.Config.Variables.Convert.SI.E0;
            dOmegaP     = obj.Data.Config.Variables.Plasma.OmegaP;
            dLFactor    = dC / dOmegaP;
            dSimLength  = dSimTime*dLFactor;
            
            % Simulation
            dBoxLength  = obj.Data.Config.Variables.Simulation.BoxX1Max;
            iBoxNZ      = obj.Data.Config.Variables.Simulation.BoxNX1;
            dBoxRadius  = obj.Data.Config.Variables.Simulation.BoxX2Max;
            iBoxNR      = obj.Data.Config.Variables.Simulation.BoxNX2;
            
            % Prepare axes
            aXAxis      = linspace(0,dBoxLength*dLFactor,iBoxNZ);
            aYAxis      = linspace(-dBoxRadius*dLFactor,dBoxRadius*dLFactor,2*iBoxNR);
            
            % Get data
            h5Data      = obj.Data.Data(iTime, obj.DataSet);

            % Calculate crop/zoom
            xDim        =  dBoxLength*dLFactor;
            yDim        =  dBoxRadius*dLFactor*2;
            xMin        =  0;
            xMax        =  dBoxLength*dLFactor;
            yMin        = -dBoxRadius*dLFactor;
            yMax        =  dBoxRadius*dLFactor;

            switch (length(obj.Crop))
                
                case 2
                    xSpan = obj.Crop(1)*xDim/100;
                    ySpan = obj.Crop(2)*yDim/100;

                    xMin  = xMin+(xDim-xSpan)/2;
                    xMax  = xMin+xSpan;
                    yMin  = yMin+(yDim-ySpan)/2;
                    yMax  = yMin+ySpan;
                    
                case 4
                    xMax = xMin+obj.Crop(2)*xDim/100;
                    xMin = xMin+obj.Crop(1)*xDim/100;
                    yMax = yMin+obj.Crop(4)*yDim/100;
                    yMin = yMin+obj.Crop(3)*yDim/100;
                    
            end % switch
            
            % Plot
            imagesc(aXAxis, aYAxis, dE0*transpose([fliplr(h5Data),h5Data]));
            axis([xMin xMax yMin yMax]);
            colorbar();
            
            sTitle = sprintf('%s - Dump %d - t=%0.1f - l=%0.4g m', ...
                obj.DataSet.Path, iTime, dSimTime, dSimLength);
            title(sTitle);
            xlabel('m');
            ylabel('m');
            
        end % function
        
        function obj = Next(obj)
            
            iFiles = obj.DataSet.Files;
            iTime  = obj.Time;
            
            iTime = iTime + 1;
            if iTime > iFiles - 1
                iTime = iFiles -1;
                fprintf('End of dataset\n');
            end % if
            
            obj.Time = iTime;
            obj.Plot(iTime);
            
        end % function

        function obj = Prev(obj)
            
            iTime = obj.Time;
            
            iTime = iTime - 1;
            if iTime < 0
                iTime = 0;
                fprintf('Beginning of dataset\n');
            end % if
            
            obj.Time = iTime;
            obj.Plot(iTime);
            
        end % function

        function obj = Loop(obj, iPause)
            
            if nargin == 1
                iPause = 1;
            end % if

            for i = 0:obj.DataSet.Files - 1
                %fprintf('Plotting t=%d\n', i);
                obj.Plot(i);
                pause(iPause);
            end % for
            
        end % function
        
    end % methods

end % classdef

