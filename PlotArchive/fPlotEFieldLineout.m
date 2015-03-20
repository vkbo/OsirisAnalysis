%
%  Function: fPlotEFieldLineout
% *******************************
%  Plots the e-field for a given t and r
%
%  Inputs:
% =========
%  oData     :: OsirisData object
%  iTime     :: Dump number
%  iR        :: R-value
%  sField    :: Which e-field (e1, e2 or e3)
%  sSpecies1 :: Which species
%  sSpecies2 :: Which species (optional)
%  iTrack    :: Which species to track (optional)
%  aRange    :: +/- lambda_p to include (optional)
%  iDensity  :: Show beam density 1 = on, 0 = off (default)
%

function fPlotDensityLineout(oData, iTime, iR, sField, sSpecies1, sSpecies2, iTrack, aRange, iDensity)


    %
    %  Function Init
    % ***************
    %

    if nargin == 0
       fprintf('\n');
       fprintf('  Function: fPlotEFieldLineout\n');
       fprintf(' *******************************\n');
       fprintf('  Plots the e-field for a given t and r\n');
       fprintf('\n');
       fprintf('  Inputs:\n');
       fprintf(' =========\n');
       fprintf('  oData     :: OsirisData object\n');
       fprintf('  iTime     :: Dump number\n');
       fprintf('  iR        :: R-value\n');
       fprintf('  sField    :: Which e-field (e1, e2 or e3)\n');
       fprintf('  sSpecies1 :: Which species\n');
       fprintf('  sSpecies2 :: Which species (optional)\n');
       fprintf('  iTrack    :: Which species to track (optional)\n');
       fprintf('  aRange    :: +/- lambda_p to include (optional)\n');
       fprintf('  iDensity  :: Show beam density 1 = on, 0 = off (default)\n');
       fprintf('\n');
       return;
    end % if
    
    if nargin < 9
        iDensity = 0;
    end % if

    if nargin < 8
        aRange = [];
    end % if

    if nargin < 7
        iTrack = 0;
    end % if

    if nargin < 6
        sSpecies2 = '';
    end % if


    % Check input variables
    sSpecies1 = fTranslateSpecies(sSpecies1);
    sSpecies2 = fTranslateSpecies(sSpecies2);
    iTMax     = oData.Elements.DENSITY.(sSpecies1).charge.Info.Files - 1;
    if iTime > iTMax
        if iTMax == -1
            fprintf('There is no data in this dataset.\n');
            return;
        else
            fprintf('Specified time step is too large. Changed to %d\n', iTMax);
            iTime = iTMax;
        end % if
    end % if
    
    switch(sField)
        case 'e1'
            sField = 'e1';
            sFName = '\mbox{E}_z';
        case 'e2'
            sField = 'e2';
            sFName = '\mbox{E}_r';
        case 'e3'
            sField = 'e3';
            sFName = '\mbox{E}_\theta';
        otherwise
            sField = 'e1';
            sFName = '\mbox{E}_z';
    end % switch

    % Plasma
    dPStart     = oData.Config.Variables.Plasma.PlasmaStart;
    %dPEnd       = oData.Config.Variables.Plasma.PlasmaEnd;
    dE0         = oData.Config.Variables.Convert.SI.E0;

    % Simulation
    dBoxLength  = oData.Config.Variables.Simulation.BoxX1Max;
    iBoxNZ      = oData.Config.Variables.Simulation.BoxNX1;
    %dBoxRadius  = oData.Config.Variables.Simulation.BoxX2Max;
    %iBoxNR      = oData.Config.Variables.Simulation.BoxNX2;

    % Factors
    dTFactor    = oData.Config.Variables.Convert.SI.TimeFac;
    dLFactor    = oData.Config.Variables.Convert.SI.LengthFac;
    
    % Prepare axes
    aXAxis      = 1e3*linspace(0,dBoxLength*dLFactor,iBoxNZ);
    iXMin       = 1;
    iXMax       = iBoxNZ;
    iXNStep     = 100;
    iXPStep     = 100;


    fig1 = figure(1);
    clf;
    hold on

    % Plot E-Field
    h5Data  = oData.Data(iTime, 'FLD', sField, '');
    aEField = mean(h5Data(:,iR-2:iR+2),2)*dE0*1e-6;
    clear h5Data;

    plot(aXAxis, aEField, 'color', 'green');
    stLegend{1} = sprintf('$$%s$$', sFName);

    % Load Beam Data
    h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies1);
    aBeam1 = abs(mean(h5Data(:,iR-2:iR+2),2));
    clear h5Data;
    
    if ~strcmp(sSpecies2, '')

        h5Data = oData.Data(iTime, 'DENSITY', 'charge', sSpecies2);
        aBeam2 = abs(mean(h5Data(:,iR-2:iR+2),2));
        clear h5Data;

        if iTrack == 1
            aB1Peak = fPeak(aBeam1);
            iXMin = aB1Peak-iXNStep;
            iXMax = aB1Peak+iXPStep;
            aB2Peak = fPeak(aBeam2(iXMin:iXMax))+iXMin-1;
        else
            aB2Peak = fPeak(aBeam2);
            iXMin = aB2Peak(1)-iXNStep;
            iXMax = aB2Peak(1)+iXPStep;
            aB1Peak = fPeak(aBeam1(iXMin:iXMax))+iXMin-1;
        end % if
        
        %if aBeam1(aB1Peak(1)) > aBeam2(aB2Peak(1))
        %    dScaleB1 = 1.0;
        %    dScaleB2 = aBeam1(aB1Peak(1))/aBeam2(aB2Peak(1));
        %else
        %    dScaleB1 = aBeam2(aB2Peak(1))/aBeam1(aB1Peak(1));
        %    dScaleB2 = 1.0;
        %end % if

    end % if

    aEPeak   = fPeak(abs(aEField(iXMin:iXMax)))+iXMin-1;

    % Plot Beam 1
    dScaleB1 = abs(aEField(aEPeak(1))/aBeam1(aB1Peak(1)));
    aBeam1   = dScaleB1*aBeam1;
    
    plot(aXAxis, aBeam1, 'color', 'blue');
    sSpecies1   = strrep(sSpecies1, '_', ' ');
    sSpecies1   = regexprep(sSpecies1,'(\<[a-z])','${upper($1)}');
    stLegend{2} = sprintf('$$\\mbox{%s}$$', sSpecies1);
    
    % Plot Beam 2
    if ~strcmp(sSpecies2, '')

        dScaleB2 = abs(aEField(aEPeak(1))/aBeam2(aB2Peak(1)));
        aBeam2   = dScaleB2*aBeam2;
        
        plot(aXAxis, aBeam2, 'color', 'red');
        sSpecies2   = strrep(sSpecies2, '_', ' ');
        sSpecies2   = regexprep(sSpecies2,'(\<[a-z])','${upper($1)}');
        stLegend{3} = sprintf('$$\\mbox{%s}$$', sSpecies2);
        
    end % if

    % Plot E-Field
    %aEPeak  = fPeak(abs(aEField(iXMin:iXMax)))+iXMin-1;
    %dEScale = aBeam1(aB1Peak(1))/aEField(aEPeak(1))
    %aEField = dEScale*aEField/2.0;

    %xlim([aXAxis(iXMin), aXAxis(iXMax)]);

    sTitle = sprintf('Beam Density and Ez at R = %d cells and S = %0.2f m', iR, (iTime*dTFactor - dPStart)*dLFactor);
    title(sTitle, 'FontSize', 16);
    xlabel('$$z \;\mbox{[mm]}$$', 'interpreter', 'LaTex', 'FontSize', 14);
    ylabel(sprintf('$$%s [\\mbox{MeV}]$$', sFName), 'interpreter', 'LaTex', 'FontSize', 14);
    legend(stLegend, 'interpreter', 'LaTex', 'Location', 'NE');
    
    %axis([0.0, dBoxLength*dLFactor*1e3, -0.05, 1.05]);
    
    
    %pbaspect([1.0,0.4,1.0]);
    hold off;

end

