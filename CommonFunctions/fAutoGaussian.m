
%
%  Function: fAutoGaussian
% *************************
%  Finds best Gaussian fit
%
%  Inputs:
% =========
%  aAxis :: Axis values
%  aData :: Data to fit
%  iMax  :: Max number of Gaussians to fit. Between 1 and 8. Default is 8.
%

function stReturn = fAutoGaussian(aAxis, aData, iMax)

    % Input/Output
    stReturn = {};
    
    if nargin < 3
        iMax = 8;
    end % if
    if iMax < 1
        iMax = 1;
    end % if
    if iMax > 8
        iMax = 8;
    end % if

    %aData = smooth(aData,0.1,'loess').';
    
    % Loop through Gaussian fits
    aBest = zeros(1,iMax);
    stFit = {};
    for g=1:iMax
        [oFit, oGof] = fit(aAxis.',aData.',sprintf('gauss%d',g));
        aBest(g) = oGof.rsquare;
        %oGof.adjrsquare
        stFit{g} = coeffvalues(oFit);
    end % for

    % Extract best fit based on RSquare
    [~, iG] = min(1-abs(aBest));
    aCoeff  = stFit{iG};

    % Save values for best model
    aAmp   = zeros(1,iG);
    aMean  = zeros(1,iG);
    aSigma = zeros(1,iG);
    aFit   = zeros(1,length(aAxis));
    for i=1:iG
        aAmp(i)   = aCoeff(3*(i-1)+1);
        aMean(i)  = aCoeff(3*(i-1)+2);
        aSigma(i) = aCoeff(3*(i-1)+3);
        aFit      = aFit + aAmp(i)*exp(-((aAxis-aMean(i))./aSigma(i)).^2);
    end % for

    % Return data
    stReturn.BestFit = sprintf('Gauss%d',iG);
    stReturn.Fit     = aFit;
    %stReturn.Smooth  = aData;
    stReturn.RSquare = aBest(iG);
    stReturn.Amp     = aAmp;
    stReturn.Mean    = aMean;
    stReturn.Sigma   = aSigma/sqrt(2);

end % function
