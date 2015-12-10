
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

stFolders.USBDrive = struct('Path', '/scratch/DataDrive/OsirisData', 'Depth', 1, 'Name', 'Local: USB Drive');
stFolders.Scratch  = struct('Path', '/scratch/OsirisData',           'Depth', 1, 'Name', 'Local: Scratch');
stFolders.Archive  = struct('Path', '/data/OsirisArchive',           'Depth', 2, 'Name', 'Local: Archive');
stFolders.Data     = struct('Path', '/data/OsirisData',              'Depth', 2, 'Name', 'Local: Data');

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
