
%
%  Full-Width at Half-Maximum (FWHM)
% ***********************************
%
%  Based on Rev 1.2, April 2006 (Patrick Egan)
%

function [dW, iCenter, tLead, tTrail] = fwhm(aX, aY)

    aY = aY/max(aY);
    nY = length(aY);
    dH = 0.5;

    % Find index of center (max or min) of pulse
    if aY(1) < dH
        [~,iCenter] = max(aY);
        iPol = +1;
        %disp('Pulse Polarity = Positive')
    else
        [~,iCenter] = min(aY);
        iPol = -1;
        %disp('Pulse Polarity = Negative')
    end
    
    % First crossing is between v(i-1) & v(i)
    i = 2;
    while sign(aY(i)-dH) == sign(aY(i-1)-dH)
        i = i+1;
    end
    
    dInterp = (dH-aY(i-1)) / (aY(i)-aY(i-1));
    tLead   = aX(i-1) + dInterp*(aX(i)-aX(i-1));
    
    % Start search for next crossing at center
    i = iCenter+1;
    while ((sign(aY(i)-dH) == sign(aY(i-1)-dH)) & (i <= nY-1))
        i = i+1;
    end
    
    if i ~= nY
        iPType  = 1;
        dInterp = (dH-aY(i-1)) / (aY(i)-aY(i-1));
        tTrail  = aX(i-1) + dInterp*(aX(i)-aX(i-1));
        dW      = tTrail - tLead;
        %disp('Pulse is Impulse or Rectangular with 2 edges')
    else
        iPType = 2; 
        tTrail = NaN;
        dW     = NaN;
        %disp('Step-Like Pulse, no second edge')
    end

end % function

