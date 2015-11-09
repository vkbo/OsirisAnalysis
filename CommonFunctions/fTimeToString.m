
%
%  Function: fTimeToString
% *************************
%  Returns a readable version of a time in seconds
%

function sTime = fTimeToString(dSeconds, iDigits)

    if nargin < 2
        iDigits = 0;
    end % if

    iH = floor(dSeconds/3600);
    dSeconds = mod(dSeconds,3600);
    iM = floor(dSeconds/60);
    dSeconds = mod(dSeconds,60);
    iS = floor(dSeconds);
    dSeconds = mod(dSeconds,1);

    sTime = sprintf('%02d:%02d:%02d',iH,iM,iS);

    if iDigits > 0
        sMS   = ['0000000000000000' num2str(round(dSeconds*10^iDigits))];
        sTime = [sTime '.' sMS(end-iDigits+1:end)];
    end % if

end

