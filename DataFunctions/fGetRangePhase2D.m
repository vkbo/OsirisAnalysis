%
%  Function: fGetRangePhase2D
% ****************************
%  Scans 2D Phase Data
%
%  Inputs:
% =========
%  oData    :: OsirisData object
%  sSpecies :: Which species to scan
%  sAxis1   :: Which axis to scan
%  sAxis2   :: Which axis to scan
%  aRange   :: Time range. Optional. Default is whole range.
%
%  Optional Inputs:
% ==================
%  sCAxis   :: Scale of CAxis: 'lin' or 'log'
%

function [ output_args ] = fGetRangePhase2D(oData, sSpecies, sAxis1, sAxis2, aRange)

    % Help output
    if nargin == 0
        fprintf('\n');
        fprintf('  Function: fGetRangePhase2D\n');
        fprintf(' ****************************\n');
        fprintf('  Scans 2D Phase Data\n');
        fprintf('  Inputs:\n');
        fprintf(' =========\n');
        fprintf('  oData    :: OsirisData object\n');
        fprintf('  sSpecies :: Which species to scan\n');
        fprintf('  sAxis1   :: Which axis to scan\n');
        fprintf('  sAxis2   :: Which axis to scan\n');
        fprintf('  aRange   :: Time range. Optional. Default is whole range.\n');
        fprintf('\n');
        fprintf('  Optional Inputs:\n');
        fprintf(' ==================\n');
        fprintf('  sCAxis   :: Scale of CAxis: ''lin'' or ''log''\n');
        fprintf('\n');
        return;
    end % if

    sAxis = sprintf('%s%s', sAxis1, sAxis2);


end

