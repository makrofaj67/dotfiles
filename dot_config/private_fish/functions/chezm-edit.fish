function chezm-edit
    if test -z "$argv"
        echo ":: Error: Target missing. Usage: chezm-edit ~/.config/kitty/kitty.conf"
        return 1
    end
    
    echo ":: Opening '$argv' in chezmoi source..."
    echo ":: Changes will be applied automatically upon exit."
    
    EDITOR=nvim chezmoi edit --apply "$argv"
end
