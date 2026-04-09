function chezm-add
    if test -z "$argv"
        echo ":: Syncing all tracked files..."
        # Takip edilen her şeyi (dosya/klasör) güncelle ve git'e ekle
        chezmoi add --changed 2>/dev/null
        chezmoi git -- add .
    else
        echo ":: Syncing and staging '$argv'..."
        chezmoi add "$argv"
        chezmoi git -- add (chezmoi source-path "$argv" 2>/dev/null; or echo ".")
    end
end
