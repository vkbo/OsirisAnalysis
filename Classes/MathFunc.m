
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

            [mX1,mX2,mX3] = meshgrid(aX1,aX2,aX3);

            stFunc = obj.FuncStruct;
            [~,nF] = size(stFunc);

            stF(nF).X = [];

            for f=nF:-1:1

                aCh = stFunc(f).Children; % Array of children functions
                sFn = stFunc(f).Clean;    % Parsed function to evaluate
                sMa = stFunc(f).Func;     % Math function for curren5 paranthesis
                nCh = length(aCh);        % Number of children

                % Insert variables for children functions
                if ~isempty(aCh)
                    for c=1:nCh
                        sFi = sprintf('%s(#%d)',stFunc(aCh(c)).Func,aCh(c));
                        sFn = strrep(sFn,sFi,sprintf('stF(%d).X',aCh(c)));
                    end % for
                end % if

                stFn     = strsplit(sFn,','); % Struct of function variables
                nFn      = length(stFn);      % Number of function variables
                stR(3).X = [];                % Storage struct for function variables

                % Parse all variable functions
                for n=1:nFn
                    if n > 3; continue; end;
                    fFn      = str2func(sprintf('@(x1,x2,x3,stF)%s',stFn{n}));
                    stR(n).X = fFn(mX1,mX2,mX3,stF);
                end % for

                % Clear data for inserted function results to save memory
                if ~isempty(aCh)
                    for c=1:nCh
                        stF(aCh(c)).X = [];
                    end % for
                end % if

                % Apply math function call
                stF(f).X = obj.fFunc(sMa,stR(1).X,stR(2).X,stR(3).X);
                if isempty(stF(f).X)
                    fprintf(2,'MathFunc Error: Cannot parse math function.\n');
                    mReturn = [];
                    return;
                end % if

            end % for

            % Return matrix for root function result
            mReturn = stF(1).X;

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
            iC    = iC+1;
            iInd  = 1;
            aTree = [1];

            % Set up struct
            stFunc(iC).Children = [];
            stFunc(iC).Start    = [];
            stFunc(iC).End      = [];
            stFunc(iC).String   = [];
            stFunc(iC).Clean    = [];
            stFunc(iC).Func     = [];

            % Root values
            stFunc(1).Start  = 1;
            stFunc(1).End    = length(obj.Func);
            stFunc(1).String = obj.Func;

            % Build paranteses tree
            for c=1:stFunc(1).End
                sC = obj.Func(c);
                if sC == '('
                    iInd = iInd + 1;
                    aTree(end+1) = iInd;
                    stFunc(iInd).Start = c+1;
                    stFunc(aTree(end-1)).Children(end+1) = iInd;
                end % if
                if sC == ')'
                    stFunc(aTree(end)).End = c-1;
                    stFunc(aTree(end)).String = obj.Func(stFunc(aTree(end)).Start:stFunc(aTree(end)).End);
                    aTree(end) = [];
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
                stFunc(i).Clean = obj.fFormat(sClean);

                % Extract function
                for c=stFunc(i).Start-2:-1:1
                    sC = obj.Func(c);
                    if c == 1
                        stFunc(i).Func = obj.Func(c:stFunc(i).Start-2);
                        break;
                    end % if
                    if ismember(sC, {',','+','-','*','/','(',')','<','>','=','&','|','!','^'})
                        stFunc(i).Func = obj.Func(c+1:stFunc(i).Start-2);
                        break;
                    end % if
                end % for
            end % for

            obj.FuncStruct = stFunc;

        end % function

        function sReturn = fFormat(~, sReturn)

            sReturn = strrep(sReturn,'&&', '&');
            sReturn = strrep(sReturn,'||', '|');
            sReturn = strrep(sReturn,'*', '.*');
            sReturn = strrep(sReturn,'/', './');
            sReturn = strrep(sReturn,'^', '.^');

        end % function

        function mReturn = fFunc(~, sFunc, vX, vY, vZ)

            mReturn = [];

            if nargin < 4
                vY = [];
            end % if

            if nargin < 5
                vZ = [];
            end % if

            if isempty(sFunc)
                mReturn = vX;
                return;
            end % if

            switch(sFunc)

                % if(x,y,z) - If statement with condition, true, false
                case 'if'
                    mReturn = vX.*vY + not(vX).*vZ;
                    return;

                % abs(x) - Absolute value of x.
                case 'abs'
                    mReturn = abs(vX);
                    return;

                % sin(x) - Sine of x.
                case 'sin'
                    mReturn = sin(vX);
                    return;

                % cos(x) - Cosine of x.
                case 'cos'
                    mReturn = cos(vX);
                    return;

                % tan(x) - Tangent of x.
                case 'tan'
                    mReturn = tan(vX);
                    return;

                % exp(x) - Exponential function i.e. e^x.
                case 'exp'
                    mReturn = exp(vX);
                    return;

                % log10(x) - Base 10 logarithm of x.
                case 'log10'
                    mReturn = log10(vX);
                    return;

                % log(x) - Natural (Base e) logarithm of x.
                case 'log'
                    mReturn = log(vX);
                    return;

                % asin(x) - Arc Sine of x.
                case 'asin'
                    mReturn = asin(vX);
                    return;

                % acos(x) - Arc Cosine of x.
                case 'acos'
                    mReturn = acos(vX);
                    return;

                % atan2(x,y) - Arc Tangent of y/x, taking into account which quadrant the point (x,y) is in.
                case 'atan2'
                    mReturn = atan2(vX,vY);
                    return;

                % atan(x) - Arc Tangent of x.
                case 'atan'
                    mReturn = atan(vX);
                    return;

                % sqrt(x) - Square root of x.
                case 'sqrt'
                    mReturn = sqrt(vX);
                    return;

                % not(x) - Logical not. x is evaluated as a logical expression and the complement is returned.
                case 'not'
                    mReturn = not(vX);
                    return;

                % pow(x,y) - Power, returns x^y.
                case 'pow'
                    mReturn = vX.^fix(vY);
                    return;

                % int(x) - Integer, converts x to integer truncating towards 0.
                case 'int'
                    mReturn = fix(vX);
                    return;

                % nint(x) - Nearest integer, converts x to the nearest integer.
                case 'nint'
                    mReturn = fix(round(vX,0));
                    return;

                % ceiling(x) - Ceiling, converts x to the least integer that is >= x.
                case 'ceiling'
                    mReturn = ceil(vX);
                    return;

                % floor(x) - Floor, converts x to the greatest integer that is <= x.
                case 'floor'
                    mReturn = floor(vX);
                    return;

                % modulo(x,y) - Modulo, returns the remainder of the integer division, i.e., x - floor(x/y)*y%
                case 'modulo'
                    mReturn = mod(vX,vY);
                    return;

                % rect(x) - Rect function, returns 1.0 for -0.5 <= x <= 0.5 and 0.0 otherwise.
                case 'rect'
                    mReturn = (abs(vX) <= 0.5);
                    return;

                % step(x) - Step function, returns 1.0 for x >= 0 and 0.0 otherwise
                case 'step'
                    mReturn = (vX >= 0.0);
                    return;

                % min3(x,y,z) - Minimum function, returns the minimum value between x, y and z
                case 'min3'
                    mReturn = min([vX, vY, vZ]);
                    return;

                % min(x,y) - Minimum function, returns the minimum value between x and y
                case 'min'
                    mReturn = min([vX, vY]);
                    return;

                % max3(x,y,z) - Maximum function, returns the minimum value between x, y and z
                case 'max3'
                    mReturn = max([vX, vY, vZ]);
                    return;

                % max(x,y) - Maximum function, returns the minimum value between x and y
                case 'max'
                    mReturn = max([vX, vY]);
                    return;

                % This should not be reached
                otherwise
                    fprintf(2,'MathFunc Error: Unknown math function "%s" in equation.\n',sFunc);
                    return;

            end % switch

        end % function

    end % methods

end % classdef
