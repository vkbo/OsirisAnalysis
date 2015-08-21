
%
%  Function: fTimeStamp
% **********************
%  Returns the current timestamp as a string
%

function sTimeStamp = fTimeStamp()

    aTime      = clock;
    aTime(6)   = round(aTime(6));
    sTimeStamp = sprintf('%04.0f-%02.0f-%02.0f-%02.0f%02.0f%02.0f', aTime);

end

