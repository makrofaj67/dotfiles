function chezm-track
    if test -z "$argv"
        echo ":: Error: Missing target. Usage: chezm-track ~/.config/newapp/config.conf"
        return 1
    end
    
    echo ":: Tracking new target '$argv' with chezmoi..."
    chezmoi add "$argv"
    
    if test $status -eq 0
        echo ":: Success: '$argv' is now tracked by chezmoi."
        echo ":: Tip: Run 'chezm-add' to stage it, then 'chezm-com' to commit."
    else
        echo ":: Failed: Could not track '$argv'."
    end
end
