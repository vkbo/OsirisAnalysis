%
%  Function: fGamma
% ******************
%  Returns gamma from RQM
%

function dGamma = fGamma(dEnergy, sParticle)
    
    dGamma = 0;
    
    if    strcmpi(sParticle, 'electron') ...
       || strcmpi(sParticle, 'positron') ...
       || strcmpi(sParticle, 'e')        ...
       || strcmpi(sParticle, 'e-')       ...
       || strcmpi(sParticle, 'e+')

        dGamma = dEnergy/0.51099891;
    end % if

    if    strcmpi(sParticle, 'protons') ...
       || strcmpi(sParticle, 'p')        ...

        dGamma = dEnergy/938.272046;
    end % if
    
end

