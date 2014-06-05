%
%  Function: fSmoothVector
% *************************
%  Smooths a vector
%
%  Inputs:
% =========
%  aVec    :: Input vector
%  iCells  :: Cells to average over
%
%  Outputs:
% ==========
%  aSmooth :: Output vector
%

function aSmooth = fSmoothVector(aVec, iCells)

    if nargin < 2
        iCells = 5;
    end % if
    
    iDiff = floor(iCells/2.0);
    aSmooth = zeros(1,length(aVec));
    
    for i=1:length(aVec)
        
        iMin = i-iDiff;
        iMax = i+iDiff;
        
        if iMin < 1
            iMin = 1;
        end % if

        if iMax > length(aVec)
            iMax = length(aVec);
        end % if
        
        aSmooth(i) = mean(aVec(iMin:iMax));
        
    end % for
    
end

