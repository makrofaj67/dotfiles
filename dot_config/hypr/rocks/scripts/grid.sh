#!/bin/bash
#---------------------------------------------------------------------------
# Grid Navigation Script
# 3×3 virtual desktop grid navigasyonu
# hyprland-virtual-desktops plugin kullanır
#---------------------------------------------------------------------------

COLS=3
ROWS=3
MAX_VDESK=9

# Argüman kontrolü
[[ -z "$1" || -z "$2" || -z "$3" ]] && exit 1

# Mevcut vdesk'i al (plugin'in printdesk komutunu kullan)
# Format: "Virtual desk X: name" şeklinde döner
current=$(hyprctl printdesk 2>/dev/null | grep -oP 'desk \K\d+' | head -1)

# Eğer printdesk çalışmazsa, fallback olarak 1 kullan
if [[ -z "$current" || "$current" -lt 1 || "$current" -gt $MAX_VDESK ]]; then
    current=1
fi

# Satır ve sütun hesapla (0-indexed)
row=$(( (current - 1) / COLS ))
col=$(( (current - 1) % COLS ))

case "$1" in
    move)
        # Virtual desktop değiştir
        new_col=$((col + $2))
        new_row=$((row + $3))
        
        # Sınır kontrolü (wrap etmeden)
        [[ $new_col -lt 0 || $new_col -ge $COLS ]] && exit 0
        [[ $new_row -lt 0 || $new_row -ge $ROWS ]] && exit 0
        
        new_vdesk=$((new_row * COLS + new_col + 1))
        hyprctl dispatch vdesk "$new_vdesk"
        ;;
    throw)
        # Pencereyi fırlat ve takip et
        new_col=$((col + $2))
        new_row=$((row + $3))
        
        # Sınır kontrolü
        [[ $new_col -lt 0 || $new_col -ge $COLS ]] && exit 0
        [[ $new_row -lt 0 || $new_row -ge $ROWS ]] && exit 0
        
        new_vdesk=$((new_row * COLS + new_col + 1))
        hyprctl dispatch movetodesk "$new_vdesk"
        ;;
    send)
        # Pencereyi fırlat ama takip etme
        new_col=$((col + $2))
        new_row=$((row + $3))
        
        # Sınır kontrolü
        [[ $new_col -lt 0 || $new_col -ge $COLS ]] && exit 0
        [[ $new_row -lt 0 || $new_row -ge $ROWS ]] && exit 0
        
        new_vdesk=$((new_row * COLS + new_col + 1))
        hyprctl dispatch movetodesksilent "$new_vdesk"
        ;;
esac
