%
%  Function: fOmegaP
% *******************
%  Returns \omega_p for a give n_0

function dOmegaP = fOmegaP(dN0)

    sConstants;
    
    dE   = Constants.Nature.ElementaryCharge;
    dMe  = Constants.Particles.Electron.Mass;
    dEp0 = Constants.Nature.VacuumPermitivity;
    
    dOmegaP = sqrt((dN0 * dE^2) / (dMe * dEp0));

end

