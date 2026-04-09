function chezm-fire
    if test -z "$argv"
        echo ":: Error: Commit message required."
        return 1
    end
    # Adım 2: Commit (Sadece değişiklik varsa yapacaktır)
    echo ":: Committing..."
    chezmoi git -- commit -m "$argv"
    
    # Adım 3: Push
    echo ":: Pushing..."
    chezm-push
end
