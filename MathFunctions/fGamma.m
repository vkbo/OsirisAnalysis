%
%  Function: fGamma
% ******************
%  Returns gamma from RQM
%

function dGamma = fGamma(dEnergy, sParticle)

    sConstants;

    dGamma = 0;
    
    if    strcmpi(sParticle, 'electron') ...
       || strcmpi(sParticle, 'positron') ...
       || strcmpi(sParticle, 'e')        ...
       || strcmpi(sParticle, 'e-')       ...
       || strcmpi(sParticle, 'e+')

        dGamma = dEnergy/Constants.Particles.Electron.MassMeV;
    end % if

    if    strcmpi(sParticle, 'proton') ...
       || strcmpi(sParticle, 'p')

        dGamma = dEnergy/Constants.Particles.Proton.MassMeV;
    end % if
    
    if    strcmpi(sParticle, 'muon') ...
       || strcmpi(sParticle, 'm')    ...
       || strcmpi(sParticle, 'm-')   ...
       || strcmpi(sParticle, 'm+')

        dGamma = dEnergy/Constants.Particles.Muon.MassMeV;
    end % if

end

