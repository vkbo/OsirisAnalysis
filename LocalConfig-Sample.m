
%
%  Local Settings
% ****************
%  Copy this file as LocalConfig.m and change the settings below
%

% Local temp directory
sLocalTemp = '/home/vkbo/Temp';

% Output directory for animated plots
sAnimPath = '/scratch/Code/Osiris/Matlab/Movies';

%  List of data folders to scan
% *******************************
%  Depth indicates at which sub level the data folders are stored.
%  If the same dataset exists in several locations, the last entry in the
%  list takes priority.

stFolders.USBDrive = struct('Path', '/scratch/DataDrive/OsirisData', 'Depth', 1, 'Name', 'USB Drive');
stFolders.Scratch  = struct('Path', '/scratch/OsirisData',           'Depth', 1, 'Name', 'Scratch');
stFolders.RSeries  = struct('Path', '/data/OsirisArchive/R-Series',  'Depth', 1, 'Name', 'R-Series');
stFolders.SSeries  = struct('Path', '/data/OsirisArchive/S-Series',  'Depth', 1, 'Name', 'S-Series');
stFolders.TSeries  = struct('Path', '/data/OsirisData/T-Series',     'Depth', 1, 'Name', 'T-Series');
stFolders.USeries  = struct('Path', '/data/OsirisData/U-Series',     'Depth', 1, 'Name', 'U-Series');
stFolders.VSeries  = struct('Path', '/data/OsirisData/V-Series',     'Depth', 1, 'Name', 'V-Series');
stFolders.WSeries  = struct('Path', '/data/OsirisData/W-Series',     'Depth', 1, 'Name', 'W-Series');

%
%  Translation Matrix for Species Names
% **************************************
%  This is a lookup struct do determine what type of species the particles
%  in the input deck are. OsirisAnalysis uses the fieldnames after stInput
%  internally, and all other names used must be specified in the corresponding
%  cell array.
%

stInput.ElectronBeam    = {'eb','e-b','electron_beam'};
stInput.PositronBeam    = {'e+b','positron_beam'};
stInput.ProtonBeam      = {'pb','proton_beam'};
stInput.IonBeam         = {'ib','ion_beam'};
stInput.PlasmaElectrons = {'pe','electrons','plasma_electrons'};
stInput.PlasmaProtons   = {'pp','protons','plasma_protons'};
stInput.PlasmaIons      = {'pi','ions','plasma_ions'};
