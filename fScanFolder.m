%
% A function that processes a directory struct and returns an array of
% folders.
%

function aFolders = fScanFolder(sPath)

    stDir    = dir(sPath);
    aFolders = {};
    iIndex   = 1;

    for i = 1:length(stDir)
        if stDir(i).isdir && ~strcmp(stDir(i).name, '.') && ~strcmp(stDir(i).name, '..')
            aFolders(iIndex) = {sprintf('%s/%s', sPath, stDir(i).name)};
            fprintf('(%d) %s\n', iIndex, stDir(i).name);
            iIndex = iIndex + 1;
        end % if
    end % for
    
end

