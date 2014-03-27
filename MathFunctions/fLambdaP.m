%
%  Function: fLambdaP
% ********************
%  Returns \lambda_p for given \omega_p
%

function dLambdaP = fLambdaP(dOmegaP)

    sConstants;
    
    dC = Constants.Nature.SpeedOfLight;
    
    dLambdaP = 2*pi*dC / dOmegaP;

end

