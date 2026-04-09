function chezm-rewind
    set -l steps 1
    if test -n "$argv[1]"
        set steps $argv[1]
    end
    
    echo ":: Rewinding chezmoi repository by $steps commit(s)..."
    chezmoi git -- reset --hard HEAD~$steps
    
    echo ":: Re-applying configuration to system..."
    chezmoi apply --force
    
    echo ":: Rewind complete. System state is now matched to HEAD."
    echo ":: Note: To push this new state, you may need 'chezm-push --force'."
end
