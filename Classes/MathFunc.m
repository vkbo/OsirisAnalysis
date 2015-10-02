
%
%  Class Object to interpret Osiris math functions
% *************************************************
%

classdef MathFunc
    
    %
    % Public Properties
    %

    properties (GetAccess = 'public', SetAccess = 'public')
        
        Func       = '';
        FuncStruct = {};

    end % properites

    %
    % Private Properties
    %
    
    properties (GetAccess = 'private', SetAccess = 'private')

    end % properties

    %
    % Constructor
    %

    methods
        
        function obj = MathFunc(sFunction)
            
            obj.Func = sFunction;
            obj = obj.fParse();
            
        end % function
    
    end % methods

    %
    % Setters and Getters
    %

    methods
        
        function stReturn = get.FuncStruct(obj)
            
            stReturn = obj.FuncStruct;
            
        end % function

    end % methods
    
    %
    % Public Methods
    %
    
    methods (Access = 'public')
        
        function mReturn = Eval(obj, aX1, aX2, aX3)
            
            nX1 = length(aX1);
            nX2 = length(aX2);
            nX3 = length(aX3);
            
            mReturn = zeros(nX1,nX2,nX3);
            
            [mX1,mX2,mX3] = meshgrid(aX1,aX2,aX3);
            
            stFunc = obj.FuncStruct;
            [~,nF] = size(stFunc);
            
            nC = 0;
            for f=2:nF
                nCC = length(stFunc(f).Children);
                if nCC > nC
                    nC = nCC;
                end % if
            end % for
            
            mF = zeros(nX2,nX1,nX3,nC);
            aF = zeros(1,nC);

            for f=nF:-1:2
                aCh = stFunc(f).Children;
                sFn = stFunc(f).Clean;
                nCh = length(aCh);
                
                if ~strcmpi(stFunc(f).Func,'if')
                    if isempty(aCh)
                        fFn = str2func(sprintf('@(x1,x2,x3)%s',sFn));
                        iF  = obj.fFreeIndex(aF);
                        mF(:,:,:,iF) = fFn(mX1,mX2,mX3);
                        aF(iF) = f;
                    else
                        for c=1:nCh
                            sFind   = sprintf('%s(#%d)',stFunc(aCh(c)).Func,aCh(c));
                            iFC     = obj.fFindIndex(aF,aCh(c));
                            sFn     = strrep(sFn,sFind,sprintf('mF(:,:,:,%d)',iFC));
                            aF(iFC) = 0;
                        end % for
                        fFn = str2func(sprintf('@(x1,x2,x3,mF)%s',sFn));
                        iF  = obj.fFreeIndex(aF);
                        mF(:,:,:,iF) = fFn(mX1,mX2,mX3,mF);
                        aF(iF) = f;
                    end % if
                else
                    stFn = strsplit(sFn,',');
                    if length(stFn) ~= 3
                        fprintf(2,'Error: If statement is not formatted correctly.\n');
                        return;
                    end % if
                    sFnC = stFn{1};
                    sFnT = stFn{2};
                    sFnF = stFn{3};
                    sFnC = strrep(sFnC,'||','|');
                    sFnC = strrep(sFnC,'&&','&');
                    if isempty(aCh)
                        fFnC = str2func(sprintf('@(x1,x2,x3)%s',sFnC));
                        fFnT = str2func(sprintf('@(x1,x2,x3)%s',sFnT));
                        fFnF = str2func(sprintf('@(x1,x2,x3)%s',sFnF));
                        iF   = obj.fFreeIndex(aF);
                        mFnC = fFnC(mX1,mX2,mX3);
                        mFnT = fFnT(mX1,mX2,mX3);
                        mFnF = fFnF(mX1,mX2,mX3);
                        mF(:,:,:,iF) = mFnC.*mFnT + not(mFnC).*mFnF;
                        aF(iF) = f;
                    else
                        for c=1:nCh
                            sFind   = sprintf('%s(#%d)',stFunc(aCh(c)).Func,aCh(c));
                            iFC     = obj.fFindIndex(aF,aCh(c));
                            sFnC    = strrep(sFnC,sFind,sprintf('mF(:,:,:,%d)',iFC));
                            sFnT    = strrep(sFnT,sFind,sprintf('mF(:,:,:,%d)',iFC));
                            sFnF    = strrep(sFnF,sFind,sprintf('mF(:,:,:,%d)',iFC));
                            aF(iFC) = 0;
                        end % for
                        fFnC = str2func(sprintf('@(x1,x2,x3,mF)%s',sFnC));
                        fFnT = str2func(sprintf('@(x1,x2,x3,mF)%s',sFnT));
                        fFnF = str2func(sprintf('@(x1,x2,x3,mF)%s',sFnF));
                        iF   = obj.fFreeIndex(aF);
                        mFnC = fFnC(mX1,mX2,mX3,mF);
                        mFnT = fFnT(mX1,mX2,mX3,mF);
                        mFnF = fFnF(mX1,mX2,mX3,mF);
                        mF(:,:,:,iF) = mFnC.*mFnT + not(mFnC).*mFnF;
                        aF(iF) = f;
                    end % if
                end % if
                
                %
                % Osiris Math Func operators:
                %
                % M = Matlab already supports
                % T = Matlab already supports, but with different function call
                %
                % M :: abs(x)      - Absolute value of x.
                % M :: sin(x)      - Sine of x.
                % M :: cos(x)      - Cosine of x.
                % M :: tan(x)      - Tangent of x.
                % M :: exp(x)      - Exponential function i.e. e^x.
                % M :: log10(x)    - Base 10 logarithm of x.
                % M :: log(x)      - Natural (Base e) logarithm of x.
                % M :: asin(x)     - Arc Sine of x.
                % M :: acos(x)     - Arc Cosine of x.
                % M :: atan2(x,y)  - Arc Tangent of y/x, taking into account which quadrant the point (x,y) is in.
                % M :: atan(x)     - Arc Tangent of x.
                % M :: sqrt(x)     - Square root of x.
                % M :: not(x)      - Logical not. x is evaluated as a logical expression and the complement is returned.
                %   :: pow(x,y)    - Power, returns x^y.
                % T :: int(x)      - Integer, converts x to integer truncating towards 0.
                %   :: nint(x)     - Nearest integer, converts x to the nearest integer.
                % T :: ceiling(x)  - Ceiling, converts x to the least integer that is >= x.
                % M :: floor(x)    - Floor, converts x to the greatest integer that is <= x.
                %   :: modulo(x,y) - Modulo, returns the remainder of the integer division, i.e., x - floor(x/y)*y%   :: 
                %   :: rect(x)     - Rect function, returns 1.0 for 0.5<= x <= 0.5 and 0.0 otherwise.
                %   :: step(x)     - Step function, returns 1.0 for x >= 0 and 0.0 otherwise
                %   :: min3(x,y,z) - Minimum function, returns the minimum value between x, y and z
                %   :: min(x,y)    - Minimum function, returns the minimum value between x and y
                %   :: max3(x,y,z) - Maximum function, returns the minimum value between x, y and z
                %   :: max(x,y)    - Maximum function, returns the minimum value between x and y
                %
                switch(stFunc(f).Func)
                    case 'abs'
                        mF(:,:,:,iF) = abs(mF(:,:,:,iF));
                    case 'sin'
                        mF(:,:,:,iF) = sin(mF(:,:,:,iF));
                    case 'cos'
                        mF(:,:,:,iF) = cos(mF(:,:,:,iF));
                    case 'tan'
                        mF(:,:,:,iF) = tan(mF(:,:,:,iF));
                    case 'exp'
                        mF(:,:,:,iF) = exp(mF(:,:,:,iF));
                    case 'log10'
                        mF(:,:,:,iF) = log10(mF(:,:,:,iF));
                    case 'log'
                        mF(:,:,:,iF) = log(mF(:,:,:,iF));
                    case 'asin'
                        mF(:,:,:,iF) = asin(mF(:,:,:,iF));
                    case 'acos'
                        mF(:,:,:,iF) = acos(mF(:,:,:,iF));
                    case 'atan2'
                        mF(:,:,:,iF) = atan2(mF(:,:,:,iF));
                    case 'atan'
                        mF(:,:,:,iF) = atan(mF(:,:,:,iF));
                    case 'pow'
                        mF(:,:,:,iF) = atan(mF(:,:,:,iF));
                end % switch
            end % for
            
            mReturn = mF(:,:,:,1);
            
        end % function
        
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function obj = fParse(obj)
            
            % Detect parantheses
            
            iC = length(strfind(obj.Func,'('));
            if iC ~= length(strfind(obj.Func,')'))
                fprintf(2,'Error: Parentheses mismatch.\n');
                return;
            end % if
            iC = iC+1;
        
            iLevel  = 0;
            iMaxInd = 1;
            iParInd = 1;
            aTree   = [1];
            iIfs    = 0;
            
            % Set up struct
            stFunc(iC).Level    = [];
            stFunc(iC).Children = [];
            stFunc(iC).Start    = [];
            stFunc(iC).End      = [];
            stFunc(iC).String   = [];
            stFunc(iC).Clean    = [];
            stFunc(iC).Func     = [];
            
            % Root values
            stFunc(1).Level  = 0;
            stFunc(1).Start  = 1;
            stFunc(1).End    = length(obj.Func);
            stFunc(1).String = obj.Func(stFunc(1).Start:stFunc(1).End);

            % Build paranteses tree
            for c=1:stFunc(1).End
                sC = obj.Func(c);
                
                if sC == '('
                    iLevel       = iLevel + 1;
                    iMaxInd      = iMaxInd + 1;
                    aTree(end+1) = iMaxInd;
                    stFunc(iMaxInd).Level = iLevel;
                    stFunc(iMaxInd).Start = c+1;
                    stFunc(aTree(end-1)).Children(end+1) = iMaxInd;
                end % if
                
                if sC == ')'
                    stFunc(aTree(end)).End    = c-1;
                    stFunc(aTree(end)).String = obj.Func(stFunc(aTree(end)).Start:stFunc(aTree(end)).End);
                    aTree(end) = [];
                    iLevel     = iLevel - 1;
                end % if
            end % for

            % Loop over functions
            for i=1:iC

                % Cleanup functions
                sTemp  = stFunc(i).String;
                sClean = '';
                iPar   = 0;
                iChild = 1;
                for s=1:length(sTemp)
                    if sTemp(s) == '('
                        iPar = iPar + 1;
                        if iPar == 1
                            sClean = [sClean '(#' num2str(stFunc(i).Children(iChild))];
                            iChild = iChild + 1;
                        end % if
                    end % if
                    if sTemp(s) == ')'
                        iPar = iPar - 1;
                    end % if
                    if iPar == 0
                        sClean = [sClean sTemp(s)];
                    end % if
                end % for
                stFunc(i).Clean = obj.fVectorForm(sClean);

                % Extract function
                for c=stFunc(i).Start-2:-1:1
                    sC = obj.Func(c);
                    if c == 1
                        stFunc(i).Func = obj.Func(c:stFunc(i).Start-2);
                        break;
                    end % if
                    if obj.isOperator(sC)
                        stFunc(i).Func = obj.Func(c+1:stFunc(i).Start-2);
                        break;
                    end % if
                end % for
            end % for
            
            obj.FuncStruct = stFunc;
            
        end % function
        
        function sReturn = fVectorForm(~, sReturn)
            
            sReturn = strrep(sReturn,'*', '.*');
            sReturn = strrep(sReturn,'/', './');
            sReturn = strrep(sReturn,'^', '.^');
            
        end % function
        
        function iReturn = fFreeIndex(~, aSearch)
            for i=1:length(aSearch)
                if aSearch(i) == 0
                    iReturn = i;
                    return;
                end % if
            end % for
        end % function
        
        function iReturn = fFindIndex(~, aSearch, iFind)
            for i=1:length(aSearch)
                if aSearch(i) == iFind
                    iReturn = i;
                    return;
                end % if
            end % for
        end % function
        
        function bReturn = isOperator(~, sChar)
            bReturn = ismember(sChar(1), {',','+','-','*','/','(',')','<','>','=','&','|','!','^'});
        end

    end % methods

end % classdef

