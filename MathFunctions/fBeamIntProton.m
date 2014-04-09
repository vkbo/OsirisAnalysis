%
%  Function: fBeamIntProton
% **************************
%  Returns the volume of the beam in normalised units
%

function dBeamInt = fBeamIntProton(dX1Min, dX1Max, dN0, dDensity)

    %fFunction = @(x,y,z) pi*0.5.*(1.0+cos(5.5e-3.*(x-dX1Max))).*exp(-(y.^2.+z.^2)/0.284);
    %dBeamInt  = integral3(fFunction, dX1Min, dX1Max, -8, 8, -8, 8);
    
    fFunction = @(x,r) 2*pi*0.5.*(1.0+cos(5.5e-3.*(x-dX1Max))).*exp(-(r.^2)/0.284).*r;
    dBeamInt  = integral2(fFunction, dX1Min, dX1Max, 0, 8);
    
    if nargin < 3
        return;
    end % if
    
    sConstants;
    
    dC      = Constants.Nature.SpeedOfLight;
    dE      = Constants.Nature.ElementaryCharge;
    dOmegaP = fOmegaP(dN0);
    
    dBeamVol    = dBeamInt * dC^3/dOmegaP^3;
    dBeamNum    = dBeamVol * dDensity * dN0;
    dBeamCharge = dBeamNum * dE*1e9;

    fprintf('Beam Integral: %0.3e c^3/omega_p^3\n', dBeamInt);
    fprintf('Beam Volume:   %0.3e m^3\n',           dBeamVol);
    fprintf('Beam Charge:   %0.3e nC\n',            dBeamCharge);
    fprintf('Particles:     %0.3e \n',              dBeamNum);

end

