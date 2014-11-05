%
%  fFigureSize
% *************
%  Resize a figure without moving it
%

function fFigureSize(figIn, aSize)

    if strcmpi(get(figIn, 'WindowStyle'), 'Docked')
        return;
    end % if
    
    aPosition      = get(figIn, 'Position');
    aPosition(3:4) = aSize;
    set(figIn, 'Position', aPosition);

end
