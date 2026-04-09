function chezm-restore
    if test -z "$argv"
        echo ":: Error: Target missing. Usage: chezm-restore ~/.config/nvim"
        echo ":: Tip: To reset the entire system, run 'chezmoi apply --force'"
        return 1
    end
    
    echo ":: Restoring '$argv' to its last committed state..."
    chezmoi apply --force "$argv"
    
    if test $status -eq 0
        echo ":: Success: '$argv' has been restored."
    else
        echo ":: Failed: Could not restore '$argv'. Is it managed by chezmoi?"
    end
end
