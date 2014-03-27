%
%  Function: fPlotParticleTrack
% ******************************
%  Follow specific particle through simulation
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sSpecies :: Which species to look at
%  sAxis    :: Which axis to follow            Default: 'p1'
%  sOrder   :: Which axis to order based on    Default: 'p1'
%  sFilter  :: 'min','max','zero',oldest'      Default: 'max'
%  iSample  :: How many particles to sample    Default: 20
%  iReturn  :: How many particles to return    Default: 3
%
%  Outputs:
% ==========
%  aTrack   :: Particle track
%

function aTrack = fPlotParticleTrack(oData, sSpecies, sAxis, sOrder, sFilter, iSample, iReturn)

    % Input
    
    if nargin < 7
        iReturn = 3;
    end % if

    if nargin < 6
        iSample = 20;
    end % if
    
    if nargin < 5
        sFilter = 'max';
    end % if
    
    if nargin < 4
        sOrder = 'p1';
    end % if
    
    if nargin < 3
        sAxis = 'p1';
    end % if
    
    iAxis  = fRawAxisToIndex(sAxis);
    iOrder = fRawAxisToIndex(sOrder);

    % Constants
    dEMass      = oData.Config.Variables.Constants.ElectronMass;
    dEVolt      = oData.Config.Variables.Constants.ElectronVolt;
    dEMass      = dEMass/dEVolt;
    
    % Beam
    dRQM        = oData.Config.Variables.Beam.(sSpecies).RQM;

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    dPEnd       = oData.Config.Variables.Plasma.PlasmaEnd;

    % Factors
    dTFactor    = oData.Config.Variables.Convert.SI.TimeFac;
    dLFactor    = oData.Config.Variables.Convert.SI.LengthFac;
    iFiles      = oData.Elements.RAW.(sSpecies).Info.Files;
    
    % Dumps
    iDumpPS     = ceil(dPStart/dTFactor);
    iDumpPE     = floor(dPEnd/dTFactor);
    
    if iDumpPE >= iFiles
        iDumpPE = iFiles - 1;
    end % if

    iTSteps     = iDumpPE-iDumpPS+1;
    
    % Extract last dataset
    aData = oData.Data(iDumpPE, oData.Elements.RAW.(sSpecies));

    % Select particles to follow
    sTFilter = '';
    switch(sFilter)
        case 'min'
            [~,aIndex] = sort(squeeze(aData(:,iOrder)),'ascend');
            aFollow    = aData(aIndex(1:iSample),10);
            sTFilter   = 'lowest';
        case 'max'
            [~,aIndex] = sort(squeeze(aData(:,iOrder)),'descend');
            aFollow    = aData(aIndex(1:iSample),10);
            sTFilter   = 'highest';
        case 'zero'
            [~,aIndex] = sort(abs(squeeze(aData(:,iOrder))),'ascend');
            aFollow    = aData(aIndex(1:iSample),10);
            sTFilter   = 'lowest magnitude';
        case 'oldest'
            [~,aIndex] = sort(abs(squeeze(aData(:,10))),'ascend');
            aFollow    = aData(aIndex(1:iSample),10);
            sTFilter   = 'longest lived';
    end % switch

    % Extract data
    aTrack  = zeros(iReturn,iTSteps);  % Returned matrix
    aIndex  = zeros(iSample,iTSteps);  % Matrix of particle indices in aData
    aValues = zeros(iSample,iTSteps);  % Matrix of particle values in aData
    aFreq   = zeros(iSample,1);        % Number of datasets the particle occurs

    fprintf('Tracking particles: %5.1f%%',0);
    for s=1:iTSteps
        aData = oData.Data(iDumpPE-s+1, oData.Elements.RAW.(sSpecies));
        aTags = squeeze(aData(:,10));
        for i=1:iSample
            iIndex = find(aTags==aFollow(i));
            if ~isempty(iIndex)
                aIndex(i,s)  = iIndex;
                if iAxis == 1
                    aValues(i,s) = aData(iIndex,iAxis);
                    aValues(i,s) = aValues(i,s)-(i+iDumpPS-1)*dTFactor;
                    %fprintf('Time: %d, Offset %d\n', i+iDumpPS-1, (i+iDumpPS-1)*dTFactor);
                else
                    aValues(i,s) = aData(iIndex,iAxis);
                end % if
            else
                aValues(i,s) = NaN;
            end % if
        end % for
        fprintf('\b\b\b\b\b\b%5.1f%%',100.0*s/iTSteps);
    end % for
    fprintf('\n');

    for i=1:iSample
        aFreq(i) = nnz(aIndex(i,:));
    end % for
    
    [~, aFreqIndex] = sort(aFreq,'descend');
    
    for i=1:iReturn
        aTrack(i,:) = aValues(aFreqIndex(i),:);
    end % for
    
    aTrack = fliplr(aTrack);
    dTrMax = max(aTrack(:));
    
    sYLabel = '';
    dTrPFac = abs(dRQM)*dEMass;
    
    switch(iAxis)
        case 1
            sYLabel = '$z \;\mbox{[mm]}$';
            aTrack  = aTrack.*dLFactor.*1e3;
        case 2
            sYLabel = '$r \;\mbox{[}\mu\mbox{m]}$';
            aTrack = aTrack.*dLFactor.*1e6;
        case 3
            sYLabel = '$\theta \;\mbox{[}\mu\mbox{m]}$';
            aTrack = aTrack.*dLFactor.*1e6;
        case 4
            dTrMax = dTrMax*dTrPFac;
            if dTrMax > 1e9
                dTrPFac = dTrPFac*1e-9;
                sYLabel = '$p_z \;\mbox{[GeV]}$';
            else
                dTrPFac = dTrPFac*1e-6;
                sYLabel = '$p_z \;\mbox{[MeV]}$';
            end % if
            aTrack = sqrt(aTrack.^2 + 1).*dTrPFac;
        case 5
            dTrMax = dTrMax*dTrPFac;
            if dTrMax > 1e9
                dTrPFac = dTrPFac*1e-9;
                sYLabel = '$p_r \;\mbox{[GeV]}$';
            else
                dTrPFac = dTrPFac*1e-6;
                sYLabel = '$p_r \;\mbox{[MeV]}$';
            end % if
            aTrack = sqrt(aTrack.^2 + 1).*dTrPFac;
        case 6
            dTrMax = dTrMax*dTrPFac;
            if dTrMax > 1e9
                dTrPFac = dTrPFac*1e-9;
                sYLabel = '$p_{\theta} \;\mbox{[GeV]}$';
            else
                dTrPFac = dTrPFac*1e-6;
                sYLabel = '$p_{\theta} \;\mbox{[MeV]}$';
            end % if
            aTrack = sqrt(aTrack.^2 + 1).*dTrPFac;
    end % switch

    % Plot
    fig1 = figure(1);
    cMap = hsv(iReturn);

    clf;
    hold on;
    
    for p=1:iReturn
    
        aX    = linspace(iDumpPS*dTFactor*dLFactor,iDumpPE*dTFactor*dLFactor,iTSteps);
        dXMin = min(aX);
        dXMax = max(aX);

        aY    = aTrack(p,:);
        aX    = aX(~isnan(aY));
        aY    = aY(~isnan(aY));

        plot(aX,aY,'color',cMap(p,:));
        
    end % for

    xlim([dXMin,dXMax]);
    
    sTitle = sprintf('%s as a function of S for %s %s',sAxis,sTFilter,sOrder);
    
    title(sTitle,'FontSize',18);
    xlabel('$S \;\mbox{[m]}$','interpreter','LaTex','FontSize',16);
    ylabel(sYLabel,           'interpreter','LaTex','FontSize',16);
    
    hold off;
    
    % Save plot
    [sPath, ~, ~] = fileparts(mfilename('fullpath'));
    saveas(fig1, sprintf('%s/../Plots/PlotParticleTrackFigure1.eps',sPath),'epsc');
    
end

