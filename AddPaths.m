
%
%  Add OsirisAnalysis Paths
% **************************
%

sPath = mfilename('fullpath');
sDir  = sPath(1:end-8);

addpath(sDir);
addpath([sDir 'AnimFunctions']);
addpath([sDir 'Classes']);
addpath([sDir 'CommonFunctions']);
addpath([sDir 'GUIFunctions']);
addpath([sDir 'OtherFunctions']);
addpath([sDir 'PlotFunctions']);
