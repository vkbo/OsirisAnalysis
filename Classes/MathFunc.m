
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
        IFArray    = {};

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
        
        function aReturn = Eval(obj, aX1, aX2, aX3)
            
            iX1 = length(aX1);
            iX2 = length(aX2);
            iX3 = length(aX3);
            
            aReturn = zeros(iX1,iX2,iX3);
            
            for a=1:iX1
                for b=1:iX2
                    for c=1:iX3
                        aReturn(a,b,c) = obj.fEvalPoint([aX1(a) aX2(b) aX3(c)]);
                    end % for
                end % for
            end % for
            
        end % function
        
    end % methods
    
    %
    % Private Methods
    %
    
    methods (Access = 'private')
        
        function obj = fParse(obj)
            
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
            %   :: atan2(x,y)  - Arc Tangent of y/x, taking into account which quadrant the point (x,y) is in.
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
            stFunc(iC).Parent   = [];
            stFunc(iC).Children = [];
            stFunc(iC).Start    = [];
            stFunc(iC).End      = [];
            stFunc(iC).String   = [];
            stFunc(iC).Clean    = [];
            stFunc(iC).Func     = [];
            stFunc(iC).Cond     = [];
            stFunc(iC).True     = [];
            stFunc(iC).False    = [];
            
            % Root values
            stFunc(1).Level  = 0;
            stFunc(1).Start  = 1;
            stFunc(1).End    = length(obj.Func);
            stFunc(1).String = obj.Func(stFunc(1).Start:stFunc(1).End);

            % Build paranteses tree
            for c=1:stFunc(1).End
                
                sC = obj.Func(c);
                
                if sC == '('
                    iLevel  = iLevel + 1;
                    iMaxInd = iMaxInd + 1;
                    aTree(end+1) = iMaxInd;

                    stFunc(iMaxInd).Level  = iLevel;
                    stFunc(iMaxInd).Parent = aTree(end-1);
                    stFunc(iMaxInd).Start  = c+1;

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
                sClean = strrep(sClean,'x1','x(1)');
                sClean = strrep(sClean,'x2','x(2)');
                sClean = strrep(sClean,'x3','x(3)');
                stFunc(i).Clean = sClean;

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
                
                % Extract if statements
                if strcmpi(stFunc(i).Func,'if')

                    stSplit = strsplit(stFunc(i).Clean,',');
                    if length(stSplit) ~= 3
                        fprintf(2,'Error: If statement is not formatted correctly.\n');
                    end % if
                    stFunc(i).Cond  = stSplit{1};
                    stFunc(i).True  = stSplit{2};
                    stFunc(i).False = stSplit{3};
                    iIfs = iIfs + 1;
                    
                end % if
                
            end % for

            stFuncMap(iC).Func = [];
            stFuncMap(iC).Eval = [];
            
            for i=iC:-1:1
                
                sEval = stFunc(i).Clean;

                if ~isempty(stFunc(i).Children)
                    
                    aCh = stFunc(i).Children;
                    
                    for j=1:length(aCh)
                        sEval = strrep(sEval,stFuncMap(aCh(j)).Func,stFuncMap(aCh(j)).Eval);
                    end % for
                    
                end % if
                
                sKW = '';
                if ~isempty(stFunc(i).Func)

                    switch(stFunc(i).Func)
                        
                        case 'int'
                            sKW = 'fix';

                        case 'ceiling'
                            sKW = 'ceil';

                        otherwise
                            sKW = stFunc(i).Func;

                    end % switch

                end % if

                stFuncMap(i).Func = sprintf('%s(#%d)',sKW,i);
                stFuncMap(i).Eval = sprintf('%s(%s)',sKW,sEval);
                
            end % if
            
            % Return values

            stReturn = {};
            if iIfs == 0
                stReturn(1).Cond   = '';
                stReturn(1).True   = stFuncMap(1).Eval;
                stReturn(1).False  = [];
                
                return;
            end % if
            
            % Set up if struct
            aIfMap = zeros(iIfs,2);
            stReturn(iIfs).Cond   = [];
            stReturn(iIfs).True   = [];
            stReturn(iIfs).False  = [];
            
            iIfInd = 1;
            
            for i=2:iC
                
                if strcmpi(stFunc(i).Func,'if')
                    
                    aIfMap(iIfInd,1) = i;
                    aIfMap(iIfInd,2) = iIfInd;
                    
                    sTrue  = stFunc(i).True;
                    sFalse = stFunc(i).False;
                    for j=2:iC
                        if strcmpi(stFunc(j).Func,'if')
                            continue;
                        end % if
                        sTrue  = strrep(sTrue,stFuncMap(j).Func,stFuncMap(j).Eval);
                        sFalse = strrep(sFalse,stFuncMap(j).Func,stFuncMap(j).Eval);
                    end % for
                    
                    stReturn(iIfInd).Cond   = stFunc(i).Cond;
                    stReturn(iIfInd).True   = sTrue;
                    stReturn(iIfInd).False  = sFalse;
                    
                    iIfInd = iIfInd + 1;
                end % if
                
            end % for
            
            % Add pointers between if statements
            for i=1:iIfs
                for j=1:iIfs
                    stReturn(i).True  = strrep(stReturn(i).True, sprintf('if(#%d)',aIfMap(j,1)),sprintf('f(%d)',aIfMap(j,2)));
                    stReturn(i).False = strrep(stReturn(i).False,sprintf('if(#%d)',aIfMap(j,1)),sprintf('f(%d)',aIfMap(j,2)));
                end % for
            end % for
            
            % Convert to function handles
            for i=1:iIfs
                stReturn(i).Cond  = str2func(sprintf('@(x)%s',   stReturn(i).Cond));
                stReturn(i).True  = str2func(sprintf('@(x,f)%s', stReturn(i).True));
                stReturn(i).False = str2func(sprintf('@(x,f)%s', stReturn(i).False));
            end % for

            obj.FuncStruct = stReturn;
            
        end % function
        
        function dReturn = fEvalPoint(obj, aValue)
            
            fFunc  = obj.FuncStruct;
            [~,iC] = size(fFunc);
            aFunc  = zeros(1,iC);
            
            for i=iC:-1:1
                
                if fFunc(i).Cond(aValue)
                    aFunc(i) = fFunc(i).True(aValue,aFunc);
                else
                    aFunc(i) = fFunc(i).False(aValue,aFunc);
                end % if
                
            end % for            
            
            dReturn = aFunc(1);
            
        end % function
        
        %
        % Check Functions
        %
        
        function bReturn = isOperator(obj, sChar)
            bReturn = ismember(sChar(1), {',','+','-','*','/','(',')','<','>','=','&','|','!','^'});
        end

        function bReturn = isLower(obj, sChar)
            bReturn = ismember(sChar(1), {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'});
        end
        
        function bReturn = isUpper(obj, sChar)
            bReturn = ismember(sChar(1), {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'});
        end

        function bReturn = isDigit(obj, sChar)
            bReturn = ismember(sChar(1), {'0','1','2','3','4','5','6','7','8','9'});
        end

        function bReturn = isChar(obj, sChar)
            bReturn = isLower(sChar) || isUpper(sChar);
        end

    end % methods

end % classdef

