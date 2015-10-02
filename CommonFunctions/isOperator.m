%
%  isOperator
% ************
%  Returns 1 if character is an operator, otherwise 0
%

function bReturn = isOperator(sChar)

    bReturn = ismember(sChar(1), {',','+','-','*','/','(',')','<','>','=','&','|','!','^'});

end

