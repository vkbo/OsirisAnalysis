
%
%  Class Object :: Analyse Phase
% *******************************
%  SubClass of OsirisType
%
%  Description:
%    A class to analyse and handle Osiris data related to the phase data
%    outputs for particles.
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
%    Phase1D   : Returns a dataset with the distribution of a phase-type
%                variable in one dimension
%    Phase2D   : Returns a dataset with the density of two phase type
%                variables in two dimensions.
%    Scatter2D : Same as Phase2D, but creates the plot from macroparticles
%                instead.
%

classdef Phase < OsirisType

    %
    % Properties
    %

    properties(GetAccess = 'public', SetAccess = 'public')
        
        Species = ''; % Species to analyse

    end % properties
    
    %
    % Constructor
    %

    methods
        
        function obj = Phase(oData, sSpecies, varargin)
            
            % Call OsirisType constructor
            obj@OsirisType(oData, varargin{:});
            
            % Set species
            stSpecies = obj.Translate.Lookup(sSpecies);
            if stSpecies.isSpecies
                obj.Species = stSpecies;
            else
                sDefault = obj.Data.Config.Variables.Species.WitnessBeam{1};
                fprintf(2, 'Error: ''%s'' is not a recognised species name. Using ''%s'' instead.\n', sSpecies, sDefault);
                obj.Species = obj.Translate.Lookup(sDefault);
            end % if
            
        end % function
        
    end % methods

    %
    % Public Methods
    %
    
    methods(Access = 'public')

        function stReturn = Phase1D(obj, sAxis, varargin)
            
            % Input/Output
            stReturn = {};
            
            % Check Axis input
            cAxis = obj.CheckVariable(sAxis, 1);
            if isempty(cAxis.Input)
                if ~obj.Data.Silent
                    fprintf(2,'Error: PhaseSpace variable ''%s'' not found.\n', sAxis);
                end % if
                return;
            end % if

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'Lim', []);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            % Get data
            aData     = transpose(obj.Data.Data(obj.Time,'PHA',cAxis.Input,obj.Species.Name));
            aAxis     = obj.fGetDiagAxis(sAxis);
            stAxis    = obj.fConvertAxis(cAxis.Input);
            stDeposit = obj.fConvertDeposit(cAxis.Deposit);
            
            if obj.Cylindrical && strcmpi(cAxis.Input, 'x2')
                aData = [fliplr(aData), aData];
                aAxis = [-fliplr(aAxis), aAxis];
            end % if

            % Prepare data
            aData = aData * stDeposit.Fac;
            aAxis = aAxis * stAxis.Fac;
            dSum  = sum(aData(:));
            
            % Crop
            if ~isempty(stOpt.Lim)
                iMin  = fGetIndex(aAxis, stOpt.Lim(1));
                iMax  = fGetIndex(aAxis, stOpt.Lim(2));
                aData = aData(iMin:iMax);
                aAxis = aAxis(iMin:iMax);
            end % if
            
            % Return
            stReturn.Data        = aData/dSum;
            stReturn.Axis        = aAxis;
            stReturn.AxisName    = cAxis.Var1;
            stReturn.AxisRange   = [aAxis(1) aAxis(end)];
            stReturn.AxisFac     = stAxis.Fac;
            stReturn.AxisUnit    = stAxis.Unit;
            stReturn.Deposit     = cAxis.Deposit;
            stReturn.DepositFac  = stDeposit.Fac;
            stReturn.DepositUnit = stDeposit.Unit;
            stReturn.DataSet     = cAxis.Input;
            stReturn.Ratio       = sum(aData(:))/dSum;
            
        end % function

        function stReturn = Phase2D(obj, sAxis, varargin)
            
            % Input/Output
            stReturn = {};
            
            % Check Axis input
            cAxis = obj.CheckVariable(sAxis, 2);
            if isempty(cAxis.Input)
                if ~obj.Data.Silent
                    fprintf(2,'Error: PhaseSpace variable ''%s'' not found.\n', sAxis);
                end % if
                return;
            end % if

            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'HLim', []);
            addParameter(oOpt, 'VLim', []);
            addParameter(oOpt, 'Flip', 'No');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            if strcmpi(stOpt.Flip, 'Yes')
                sAxis1 = cAxis.Var2;
                sAxis2 = cAxis.Var1;
            else
                sAxis1 = cAxis.Var1;
                sAxis2 = cAxis.Var2;
            end % if
            
            % Get data
            aData     = obj.Data.Data(obj.Time,'PHA',cAxis.Input,obj.Species.Name);
            aHAxis    = obj.fGetDiagAxis(sAxis1);
            aVAxis    = obj.fGetDiagAxis(sAxis2);
            stHAxis   = obj.fConvertAxis(sAxis1);
            stVAxis   = obj.fConvertAxis(sAxis2);
            stDeposit = obj.fConvertDeposit(cAxis.Deposit);
            
            if strcmpi(stOpt.Flip, 'Yes')
                aData = transpose(aData);
            end % if
            
            % Prepare data
            aData  = aData * stDeposit.Fac;
            aHAxis = aHAxis * stHAxis.Fac;
            aVAxis = aVAxis * stVAxis.Fac;
            dSum   = sum(aData(:));

            % Crop data and axes
            if ~isempty(stOpt.HLim)
                iMin   = fGetIndex(aHAxis, stOpt.HLim(1));
                iMax   = fGetIndex(aHAxis, stOpt.HLim(2));
                aData  = aData(:,iMin:iMax);
                aHAxis = aHAxis(iMin:iMax);
            end % if

            if ~isempty(stOpt.VLim)
                iMin   = fGetIndex(aVAxis, stOpt.VLim(1));
                iMax   = fGetIndex(aVAxis, stOpt.VLim(2));
                aData  = aData(iMin:iMax,:);
                aVAxis = aVAxis(iMin:iMax);
            end % if

            % Return
            stReturn.Data        = aData/dSum;
            stReturn.HAxis       = aHAxis;
            stReturn.VAxis       = aVAxis;
            stReturn.AxisName    = {sAxis1, sAxis2};
            stReturn.AxisRange   = [aHAxis(1) aHAxis(end) aVAxis(1) aVAxis(end)];
            stReturn.AxisFac     = [stHAxis.Fac, stVAxis.Fac];
            stReturn.AxisUnit    = {stHAxis.Unit, stVAxis.Unit};
            stReturn.Deposit     = cAxis.Deposit;
            stReturn.DepositFac  = stDeposit.Fac;
            stReturn.DepositUnit = stDeposit.Unit;
            stReturn.DataSet     = cAxis.Input;
            stReturn.Ratio       = sum(aData(:))/dSum;
            
        end % function
        
        function stReturn = Scatter2D(obj, sAxis1, sAxis2, varargin)
            
            % Input/Output
            stReturn = {};
            
            vAxis1 = obj.Data.Translate.Lookup(sAxis1);
            vAxis2 = obj.Data.Translate.Lookup(sAxis2);
            
            if ~vAxis1.isValidPhaseSpaceDiag
                fprintf(2, '%s is not a valid axis.\n',sAxis1);
                return;
            end % if

            if ~vAxis2.isValidPhaseSpaceDiag
                fprintf(2, '%s is not a valid axis.\n',sAxis2);
                return;
            end % if
            
            sAxis = '';
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',vAxis1.Name,vAxis2.Name),obj.Species.Name)
                sAxis   = sprintf('%s%s',vAxis1.Name,vAxis2.Name);
                bRotate = false;
            end % if
            if obj.Data.DataSetExists('PHA',sprintf('%s%s',vAxis2.Name,vAxis1.Name),obj.Species.Name)
                sAxis   = sprintf('%s%s',vAxis2.Name,vAxis1.Name);
                bRotate = true;
            end % if
            if isempty(sAxis)
                fprintf(2, 'There is no combined phase data for %s and %s.\n',sAxis1,sAxis2);
                return;
            end % if
            
            % Read input parameters
            oOpt = inputParser;
            addParameter(oOpt, 'HLim',   []);
            addParameter(oOpt, 'VLim',   []);
            addParameter(oOpt, 'Sample', 10000);
            addParameter(oOpt, 'Grid1',  100);
            addParameter(oOpt, 'Grid2',  100);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            % Get dataset values
            dEMass = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
            dTFac  = obj.Data.Config.Variables.Convert.SI.TimeFac;
            dQFac  = obj.Data.Config.Variables.Convert.SI.ChargeFac;
            
            % Retrieve data
            aRaw = obj.Data.Data(obj.Time,'RAW','',obj.Species.Name);
            
            % Move x1 to box start
            aRaw(:,1) = aRaw(:,1) - dTFac*obj.Time;

            % Removing elements outside box on horizontal axis
            dHFac  = 1.0;
            sHUnit = 'm';
            switch(sAxis1(1))
                case 'x'
                    stOpt.HLim = stOpt.HLim/obj.AxisFac(obj.Data.RawToIndex(sAxis1));
                    dHFac      = obj.AxisFac(obj.Data.RawToIndex(sAxis1));
                case 'p'
                    stOpt.HLim = stOpt.HLim/dEMass;
                    dHFac      = dEMass;
                    sHUnit     = 'eV';
            end % switch
            if ~isempty(stOpt.HLim)
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,1) >= stOpt.HLim(1) & aRaw(:,1) <= stOpt.HLim(2));
            end % if

            % Removing elements outside box on vertical axis
            dVFac  = 1.0;
            sVUnit = 'm';
            switch(sAxis2(1))
                case 'x'
                    stOpt.VLim = stOpt.VLim/obj.AxisFac(obj.Data.RawToIndex(sAxis2));
                    dVFac      = obj.AxisFac(obj.Data.RawToIndex(sAxis2));
                case 'p'
                    stOpt.VLim = stOpt.VLim/dEMass;
                    dVFac      = dEMass;
                    sVUnit     = 'eV';
            end % switch
            if ~isempty(stOpt.VLim)
                aRaw(:,8) = aRaw(:,8).*(aRaw(:,2) >= stOpt.VLim(1) & aRaw(:,2) <= stOpt.VLim(2));
            end % if
            
            % Cut zero data
            aRaw = aRaw(find(aRaw(:,8)),:);
            
            % Sample data
            iCount = length(aRaw(:,1));
            if iCount > stOpt.Sample
                aRand = randperm(iCount);
                aRaw  = aRaw(aRand(1:stOpt.Sample),:);
            end % if
            
            % Scale axes
            if strcmpi(obj.Units, 'SI')
                aRaw(:,1) = aRaw(:,1)*obj.AxisFac(1);
                aRaw(:,2) = aRaw(:,2)*obj.AxisFac(2);
                aRaw(:,3) = aRaw(:,3)*obj.AxisFac(3);
                aRaw(:,4) = aRaw(:,4)*dEMass;
                aRaw(:,5) = aRaw(:,5)*dEMass;
                aRaw(:,6) = aRaw(:,6)*dEMass;
                stReturn.AxisUnit = {sHUnit, sVUnit};
            else
                stReturn.AxisUnit = {'N', 'N'};
            end % if
            
            % Select wanted axes
            [aQ,aI] = sort(abs(aRaw(:,8)));
            aHData  = aRaw(aI,obj.Data.RawToIndex(sAxis1));
            aVData  = aRaw(aI,obj.Data.RawToIndex(sAxis2));
            
            stReturn.Raw   = aRaw;
            stReturn.HData = aHData;
            stReturn.VData = aVData;
            stReturn.Count = length(aHData);

            % Grid data
            iNH = stOpt.Grid1;
            iNV = stOpt.Grid2;
            
            aQData = aQ*dQFac;
            aGrid  = zeros(iNV,iNH);
            
            if ~isempty(aHData) && ~isempty(aVData)

                dHMin  = min(aHData);
                aHData = aHData-dHMin;
                dHMax  = max(aHData);
                aHData = int16(round(aHData/dHMax*(iNH-1)))+1;

                dVMin  = min(aVData);
                aVData = aVData-dVMin;
                dVMax  = max(aVData);
                aVData = int16(round(aVData/dVMax*(iNV-1)))+1;

                for i=1:length(aHData)
                    aGrid(aVData(i),aHData(i)) = aGrid(aVData(i),aHData(i))+abs(aQData(i));
                end % for
                
                aHAxis = linspace(dHMin, dHMin+dHMax, iNH);
                aVAxis = linspace(dVMin, dVMin+dVMax, iNV);
                aRange = [dHMin dHMin+dHMax dVMin dVMin+dVMax];

            else
                
                aHAxis = [];
                aVAxis = [];
                aRange = [0 0 0 0];

            end % if

            stReturn.Data      = aGrid*iCount/length(aHData);
            stReturn.HAxis     = aHAxis;
            stReturn.VAxis     = aVAxis;
            stReturn.DataSet   = sAxis;
            stReturn.AxisRange = aRange;
            stReturn.AxisFac   = [dHFac dVFac];
            
        end % function
        
        function stReturn = RawHist1D(obj, sAxis, varargin)

            % Input/Output
            stReturn = {};

            oOpt = inputParser;
            addParameter(oOpt, 'Grid',  100);
            addParameter(oOpt, 'Count', 'charge');
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;
            
            iAxis = obj.Data.RawToIndex(lower(sAxis));
            if iAxis == 0
                fprintf(2,'Error: Unrecognised axis ''%s'' in Phase.RawHist1D.\n',sAxis);
                return;
            end % if
            
            % Get data
            
            aRaw = obj.Data.Data(obj.Time, 'RAW', '', obj.Species.Name);

            [aData, aAxis] = fAccu1D(aRaw(:,iAxis), aRaw(:,8), 1000);
            
            stReturn.Raw  = aRaw;
            stReturn.Data = aData;
            stReturn.Axis = aAxis;

        end % function

        function stReturn = RawHist2D(obj, sAxis1, sAxis2, varargin)

            % Input/Output
            stReturn = {};
        
            oOpt = inputParser;
            addParameter(oOpt, 'Grid', [1000 1000]);
            parse(oOpt, varargin{:});
            stOpt = oOpt.Results;

        end % function
        
        function stReturn = CheckVariable(obj, sCheck, iDim)
            
            stReturn.Input   = '';
            stReturn.Name    = '';
            stReturn.Dim     = 0;
            stReturn.Var1    = '';
            stReturn.Var2    = '';
            stReturn.Var3    = '';
            stReturn.Deposit = '';
            
            if nargin < 3
                iDim = obj.Dim;
            end % if
            
            if obj.Species.isBeam
                stMap = obj.Data.Config.Variables.Beam.(obj.Species.Name).PhaseSpaces.Details;
            elseif obj.Species.isPlasma
                stMap = obj.Data.Config.Variables.Plasma.(obj.Species.Name).PhaseSpaces.Details;
            else
                fprintf(2,'Error: Only beam or plasma currently supported.\n');
                return;
            end % if
            
            [~,iN] = size(stMap);
            
            for i=1:iN
                if stMap(i).Dim == iDim && (strcmpi(stMap(i).Input, sCheck) || strcmpi(stMap(i).Name, sCheck))
                    stReturn.Input   = stMap(i).Input;
                    stReturn.Name    = stMap(i).Name;
                    stReturn.Dim     = stMap(i).Dim;
                    stReturn.Var1    = stMap(i).Var1;
                    stReturn.Var2    = stMap(i).Var2;
                    stReturn.Var3    = stMap(i).Var3;
                    stReturn.Deposit = stMap(i).Deposit;
                end % if
            end % for
            
        end % function
    
    end % methods
    
    %
    % Private Methods
    %
    
    methods(Access = 'private')
        
        function aReturn = fGetDiagAxis(obj, sAxis)
            
            if obj.Species.isBeam
                sSPType = 'Beam';
            elseif obj.Species.isPlasma
                sSPType = 'Plasma';
            else
                fprintf(2,'Error: Unknown species type.\n');
                return;
            end % if
            
            switch sAxis
                case 'x1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNX1;
                case 'x2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNX2;
                case 'x3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagX3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNX3;
                case 'p1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNP1;
                case 'p2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNP2;
                case 'p3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagP3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNP3;
                case 'l1'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagL1Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagL1Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNL1;
                case 'l2'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagL2Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagL2Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNL2;
                case 'l3'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagL3Min;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagL3Max;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNL3;
                case 'g'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagGammaMin;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagGammaMax;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNGamma;
                case 'gl'
                    dMin = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagGammaMin;
                    dMax = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagGammaMax;
                    iN   = obj.Data.Config.Variables.(sSPType).(obj.Species.Name).DiagNGamma;
            end % switch
            
            aReturn = linspace(dMin, dMax, iN);
            
        end % function
        
        function stReturn = fConvertAxis(obj, sAxis)

            % Return Defualts
            stReturn.Fac  = 1.0;
            stReturn.Unit = 'N';

            vAxis = obj.Data.Translate.Lookup(sAxis);

            if strcmpi(obj.Units, 'SI')
                
                % Spatial Axis
                if vAxis.isAxis
                    if strcmpi(sAxis, 'x1')
                        stReturn.Fac = obj.AxisFac(1);
                    end % if
                    if strcmpi(sAxis, 'x2')
                        stReturn.Fac = obj.AxisFac(2);
                    end % if
                    if strcmpi(sAxis, 'x3')
                        stReturn.Fac = obj.AxisFac(3);
                    end % if
                    stReturn.Unit = 'm';
                end % if

                % Momentum
                if vAxis.isMomentum || vAxis.isAngular
                    stReturn.Fac  = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
                    stReturn.Unit = 'eV/c';
                end % if
                
                % Gamma
                if strcmpi(vAxis.Name, 'g')
                    stReturn.Fac  = 1.0;
                    stReturn.Unit = '\gamma';
                end % if
                
                % Log Gamma
                if strcmpi(vAxis.Name, 'gl')
                    stReturn.Fac  = 1.0;
                    stReturn.Unit = '\log(\gamma)';
                end % if
                
            end % if

        end % function

        function stReturn = fConvertDeposit(obj, sDeposit)

            % Return Defualts
            stReturn.Fac  = 1.0;
            stReturn.Unit = 'N';

            vDeposit = obj.Data.Translate.Lookup(sDeposit);

            if strcmpi(obj.Units, 'SI')
                
                % Charge Deposit
                if strcmpi(vDeposit.Name, 'charge') || strcmpi(vDeposit.Name, '|charge|')
                    stReturn.Fac  = obj.Data.Config.Variables.Convert.SI.ChargeFac;
                    stReturn.Unit = 'C';
                end % if

                % Mass Deposit
                % Not checked for sanity
                if strcmpi(vDeposit.Name, 'm')
                    stReturn.Fac  = obj.Data.Config.Variables.Convert.SI.ChargeFac;
                    stReturn.Unit = 'm_e';
                end % if

                % Energy Deposit
                % Not checked for sanity
                if strcmpi(vDeposit.Name, 'ene')
                    stReturn.Fac  = obj.Data.Config.Variables.Constants.ElectronMassMeV*1e6;
                    stReturn.Unit = 'eV/c^2';
                end % if

                % Current Deposit
                if vDeposit.isFlux
                    if strcmpi(vDeposit, 'j1')
                        stReturn.Fac = obj.Data.Config.Variables.Convert.SI.J1Fac;
                    end % if
                    if strcmpi(vDeposit, 'j2')
                        stReturn.Fac = obj.Data.Config.Variables.Convert.SI.J2Fac;
                    end % if
                    if strcmpi(vDeposit, 'j2')
                        stReturn.Fac = obj.Data.Config.Variables.Convert.SI.J2Fac;
                    end % if
                    stReturn.Unit = 'A';
                end % if

                % Heat Flux
                if vDeposit.isFlux
                    fprintf('Warning: Heat flux conversion factor not implemented.\n');
                    stReturn.Fac  = 1.0;
                    stReturn.Unit = 'W/m^2';
                end % if
                
            end % if

        end % function
        
    end % methods

end % classdef
