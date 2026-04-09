function chezm-status
    echo ":: 🔍 Checking dotfiles status..."
    echo ""
    
    echo ":: --- 1. System Modifications (Need chezm-add or chezm-track) ---"
    # Sistemde değişen ama henüz re-add yapılmayan dosyalar
    chezmoi status
    echo ""
    
    echo ":: --- 2. Git Repository State (Need chezm-com or chezm-push) ---"
    # Git sahnesinde bekleyen veya commitlenmiş durumlar
    chezmoi git -- status
end
