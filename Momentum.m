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
        
        function stReturn = SigmaEToEMean(obj, sStart, sStop)

            stReturn = {};

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            % Calculate range

            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);
            

            % Calculate axes
            
            aTAxis = obj.fGetTimeAxis;
            aTAxis = aTAxis(iStart+1:iStop+1);
            
            aMean  = zeros(1, length(aTAxis));
            aSigma = zeros(1, length(aTAxis));
            aData  = zeros(1, length(aTAxis));
            
            for i=iStart:iStop
                
                k = i-iStart+1;
                
                h5Data    = obj.Data.Data(i, 'RAW', '', obj.Beam);
                aMean(k)  = obj.MomentumToEnergy(wmean(h5Data(:,4), abs(h5Data(:,8))));
                aSigma(k) = obj.MomentumToEnergy(wstd(h5Data(:,4), abs(h5Data(:,8))));
                aData(k)  = aSigma(k)/aMean(k);
                
            end % for
            
            
            % Return data
            
            stReturn.TimeAxis = aTAxis;
            stReturn.Mean     = aMean;
            stReturn.Sigma    = aSigma;
            stReturn.Data     = aData;

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
                
                % Code
                
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
            aSAxis = obj.fGetDiagAxis(sSDim);
            
            aData  = zeros(length(aSAxis), length(aTAxis));
            
            for i=iStart:iStop
                
                h5Data       = obj.Data.Data(i, 'PHA', 'x1p1', obj.Beam);
                aData(:,i+1) = max(h5Data);
                
            end % for
            
            
            % Return data
            
            stReturn.TimeAxis  = aTAxis;
            stReturn.SpaceAxis = aSAxis;
            stReturn.Data      = aData;
        
        end % function
        
        function aReturn = MomentumToEnergy(obj, aMomentum)
            
            dRQM    = obj.Data.Config.Variables.Beam.(obj.Beam).RQM;
            dEMass  = obj.Data.Config.Variables.Constants.ElectronMassMeV;

            dPFac   = abs(dRQM)*dEMass;
            %dSign   = dRQM/abs(dRQM);
            aReturn = sqrt(abs(aMomentum).^2 + 1)*dPFac;
            
        end % function
        
        function stReturn = Evolution(obj, sAxis, sStart, sStop)

            stReturn = {};
            
            if nargin < 3
                sStart = 'Start';
            end % if

            if nargin < 4
                sStop = 'End';
            end % if
            
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);

            switch(fMomentumAxis(sAxis))
                case 'p1'
                    iAxis = 4;
                case 'p2'
                    iAxis = 5;
                case 'p3'
                    iAxis = 6;
            end % switch
            
            for i=iStart:iStop
                
                k = i-iStart+1;

                aRAW = obj.Data.Data(i, 'RAW', '', obj.Beam);

                stReturn.Average(k)       = wmean(aRAW(:,iAxis),aRAW(:,8));
                stReturn.Median(k)        = wprctile(aRAW(:,iAxis),50,abs(aRAW(:,8)));
                stReturn.Percentile10(k)  = wprctile(aRAW(:,iAxis),10,abs(aRAW(:,8)));
                stReturn.Percentile90(k)  = wprctile(aRAW(:,iAxis),90,abs(aRAW(:,8)));
                stReturn.FirstQuartile(k) = wprctile(aRAW(:,iAxis),25,abs(aRAW(:,8)));
                stReturn.ThirdQuartile(k) = wprctile(aRAW(:,iAxis),75,abs(aRAW(:,8)));

            end % for
            
    
        end % function

        function stReturn = BeamSlip(obj, sStart, sStop)

            stReturn = {};

            if nargin < 2
                sStart = 'Start';
            end % if

            if nargin < 3
                sStop = 'End';
            end % if
            
            iStart = fStringToDump(obj.Data, sStart);
            iStop  = fStringToDump(obj.Data, sStop);
            
            % Variables
            dLFac     = obj.Data.Config.Variables.Convert.SI.LengthFac;
            dTimeStep = obj.Data.Config.Variables.Simulation.TimeStep;
            iNDump    = obj.Data.Config.Variables.Simulation.NDump;
            dDeltaZ   = dTimeStep*iNDump;
            dLFac     = dLFac*1e3;
            
            for i=iStart:iStop
                
                k = i-iStart+1;

                aRAW = obj.Data.Data(i, 'RAW', '', obj.Beam);

                stReturn.Slip.Average(k)           = (dDeltaZ - dDeltaZ*sqrt(1-1/wmean(aRAW(:,4),aRAW(:,8))^2))*dLFac;
                stReturn.Slip.Median(k)            = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRAW(:,4),50,abs(aRAW(:,8)))^2))*dLFac;
                stReturn.Slip.Percentile10(k)      = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRAW(:,4),10,abs(aRAW(:,8)))^2))*dLFac;
                stReturn.Slip.Percentile90(k)      = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRAW(:,4),90,abs(aRAW(:,8)))^2))*dLFac;
                stReturn.Slip.FirstQuartile(k)     = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRAW(:,4),25,abs(aRAW(:,8)))^2))*dLFac;
                stReturn.Slip.ThirdQuartile(k)     = (dDeltaZ - dDeltaZ*sqrt(1-1/wprctile(aRAW(:,4),75,abs(aRAW(:,8)))^2))*dLFac;

                stReturn.Position.Average(k)       = (wmean(aRAW(:,1),aRAW(:,8))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Median(k)        = (wprctile(aRAW(:,1),50,abs(aRAW(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Percentile10(k)  = (wprctile(aRAW(:,1),10,abs(aRAW(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.Percentile90(k)  = (wprctile(aRAW(:,1),90,abs(aRAW(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.FirstQuartile(k) = (wprctile(aRAW(:,1),25,abs(aRAW(:,8)))-(i*dDeltaZ))*dLFac;
                stReturn.Position.ThirdQuartile(k) = (wprctile(aRAW(:,1),75,abs(aRAW(:,8)))-(i*dDeltaZ))*dLFac;
                
                if k > 1
                    stReturn.ExpectedPos.Average(k)       = stReturn.Position.Average(1)       - sum(stReturn.Slip.Average(1:k-1));
                    stReturn.ExpectedPos.Median(k)        = stReturn.Position.Median(1)        - sum(stReturn.Slip.Median(1:k-1));
                    stReturn.ExpectedPos.Percentile10(k)  = stReturn.Position.Percentile10(1)  - sum(stReturn.Slip.Percentile10(1:k-1));
                    stReturn.ExpectedPos.Percentile90(k)  = stReturn.Position.Percentile90(1)  - sum(stReturn.Slip.Percentile90(1:k-1));
                    stReturn.ExpectedPos.FirstQuartile(k) = stReturn.Position.FirstQuartile(1) - sum(stReturn.Slip.FirstQuartile(1:k-1));
                    stReturn.ExpectedPos.ThirdQuartile(k) = stReturn.Position.ThirdQuartile(1) - sum(stReturn.Slip.ThirdQuartile(1:k-1));
                else
                    stReturn.ExpectedPos.Average(1)       = stReturn.Position.Average(1);
                    stReturn.ExpectedPos.Median(1)        = stReturn.Position.Median(1);
                    stReturn.ExpectedPos.Percentile10(1)  = stReturn.Position.Percentile10(1);
                    stReturn.ExpectedPos.Percentile90(1)  = stReturn.Position.Percentile90(1);
                    stReturn.ExpectedPos.FirstQuartile(1) = stReturn.Position.FirstQuartile(1);
                    stReturn.ExpectedPos.ThirdQuartile(1) = stReturn.Position.ThirdQuartile(1);
                end % if
                
            end % for
            
            aTAxis = obj.fGetTimeAxis;
            
            stReturn.DeltaZ = dDeltaZ;
            stReturn.TAxis  = aTAxis(iStart+1:iStop+1);
    
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

        function aReturn = fGetDiagAxis(obj, sAxis)
            
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
