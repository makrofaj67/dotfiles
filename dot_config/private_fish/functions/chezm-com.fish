function chezm-com
    if test -z "$argv"
        echo ":: Error: Commit message required. Usage: chezm-com 'message'"
        return 1
    end
    chezmoi git -- commit -m "$argv"
end
