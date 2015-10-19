
%
%  Weighted Covariance Matrix
% ****************************
%
%  REFERENCE: mathematical formulas in matrix notation are available in
%  F. Pozzi, T. Di Matteo, T. Aste,
%  "Exponential smoothing weighted correlations",
%  The European Physical Journal B, Volume 85, Issue 6, 2012.
%  DOI:10.1140/epjb/e2012-20697-x. 
%
%  Modiefied from WEIGHTEDCOV by
%  Liber Eleutherios
%  15 June 2012
%

function aCov = wcov(aA, aW)

    % Check input
    if ~isvector(aW) && ~isreal(aW) && any(isnan(aW)) && any(isinf(aW)) && ~all(aW > 0);
        error('Error in wcov: weights needs to be a vector of real positive numbers with no infinite or nan values.');
    end % if
    if ~isreal(aA) && any(isnan(aA)) && any(isinf(aA)) && ~(size(size(aA), 2) == 2)
        error('Error in wcov: input needs to be a 2D matrix of real numbers with no infinite or nan values.');
    end % if
    if ~(length(aW) == size(aA, 1))
        error('Error in wcov: dimensions of input and weights must agree.')
    end

    aW       = aW(:)/sum(aW);
    [iC, iN] = size(aA);                      % T: number of observations; N: number of variables
    aCov     = aA - repmat(aW'*aA,iC,1);      % Remove mean (which is, also, weighted)
    aCov     = aCov'*(aCov.*repmat(aW,1,iN)); % Weighted Covariance Matrix
    aCov     = 0.5*(aCov + aCov');            % Must be exactly symmetric

end % function
