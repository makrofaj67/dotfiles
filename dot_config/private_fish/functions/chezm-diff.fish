function chezm-diff
    if test -z "$argv"
        echo ":: Showing all uncommitted changes across the system..."
        chezmoi diff
    else
        echo ":: Showing uncommitted changes for '$argv'..."
        chezmoi diff "$argv"
    end
end
