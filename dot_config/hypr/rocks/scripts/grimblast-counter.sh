#!/bin/bash

# --- AYARLAR ---
DIR="$HOME/Pictures/Screenshots"
STATE="$HOME/.cache/grimblast_counter"

# Hedef argümanı al (area, output, active, window) - Varsayılan: output (Tüm ekran)
TARGET="${1:-output}" 

# Türkçe Tarih ve Saat (Sistem dili İngilizce olsa bile Türkçe ay ismi almaya zorlar)
# Eğer Türkçe locale yüklü değilse İngilizce yazar.
TODAY=$(LC_TIME=tr_TR.UTF-8 date +%d%B) 
TIME=$(date +%H:%M)

# Klasörleri oluştur
mkdir -p "$DIR"
mkdir -p "$(dirname "$STATE")"

# --- SAYAÇ MANTIĞI ---
if [[ -f "$STATE" ]]; then
    read LASTDAY COUNT < "$STATE"
    # Eğer gün değiştiyse sayacı sıfırla
    if [[ "$LASTDAY" != "$TODAY" ]]; then
        COUNT=0
    else
        # Gün aynıysa artır
        COUNT=$((COUNT + 1))
    fi
else
    # Dosya yoksa sıfırdan başla
    COUNT=0
fi

# Yeni durumu kaydet (Sonraki sefer için)
echo "$TODAY $COUNT" > "$STATE"

# Dosya adını oluştur (Örn: 18Aralık_04:30_001.png)
FILENAME="${TODAY}_${TIME}_$(printf '%03d' "$COUNT").png"
FILEPATH="$DIR/$FILENAME"

# --- EKRAN GÖRÜNTÜSÜ ALMA ---
# --notify: Bildirim gönder
# copysave: Hem panoya kopyala hem dosyaya kaydet
# $TARGET: area (seçim) veya output (ekran)
# $FILEPATH: Kaydedilecek yer

grimblast --notify copysave "$TARGET" "$FILEPATH"

  
