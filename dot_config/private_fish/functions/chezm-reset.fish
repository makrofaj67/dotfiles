function chezm-reset
    if test -z "$argv"
        echo ":: Error: Reset parameter missing. Usage: chezm-reset --hard HEAD~1"
        return 1
    end
    
    echo ":: Resetting chezmoi git repo..."
    chezmoi git -- reset $argv
    echo ":: System tip: Run 'chezm-restore' or 'chezmoi apply --force' to reflect these changes on your actual files."
end
