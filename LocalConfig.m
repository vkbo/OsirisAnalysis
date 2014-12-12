%
%  Local Settings
%

%  List of data folders to scan
% *******************************
%  Depth indicates at which sub level the data folders are stored.
%  If the same dataset exists in several locations, the last entry in the
%  list takes priority.

stFolders.USBDrive = struct('Path', '/scratch/DataDrive/OsirisData', 'Depth', 1, 'Name', 'Local: USB Drive');
stFolders.Scratch  = struct('Path', '/scratch/OsirisData',           'Depth', 1, 'Name', 'Local: Scratch');
stFolders.Archive  = struct('Path', '/data/OsirisArchive',           'Depth', 2, 'Name', 'Local: Archive');
stFolders.Data     = struct('Path', '/data/OsirisData',              'Depth', 2, 'Name', 'Local: Data');
