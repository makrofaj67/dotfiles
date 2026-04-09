#!/usr/bin/env bash

# --- AYARLAR ---
DEFAULT_WIDTH=50      # Varsayılan genişlik (karakter)
DEFAULT_LINES=12      # Varsayılan satır sayısı
CHAR_PIXEL_SIZE=11    # Tahmini karakter genişliği (fontuna göre 10-12 arası değişir)
MIN_WIDTH=20          # İzin verilen en düşük genişlik
EDGE_PADDING=20       # Kenardan ne kadar boşluk kalsın

fi

[ -d "$thumbnail_dir" ] || mkdir -p "$thumbnail_dir"

# Thumbnail script (Değişmedi)
read -r -d '' thumbnail <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }
match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/, grp) {
  cliphist_item_id=grp[1]
  ext=grp[3]
  thumbnail_file=cliphist_item_id"."ext
  system("[ -f ${thumbnail_dir}/"thumbnail_file" ] || echo " cliphist_item_id "\\\\\t | cliphist decode >${thumbnail_dir}/"thumbnail_file)
  print \$0"\0icon\x1f${thumbnail_dir}/"thumbnail_file
  next
}
1
EOF

# Fuzzel'ı Dinamik Boyutlarla Çalıştır
item=$(echo "$cliphist_list" | gawk "$thumbnail" | fuzzel -d \
  --anchor top-left \
  --x-margin "$REL_X" \
  --y-margin "$REL_Y" \
  --width "$FINAL_WIDTH" \
  --lines "$FINAL_LINES" \
  --placeholder "Ara..." \
  --counter --no-sort --with-nth 2)

exit_code=$?

# İşlemler (Silme, Temizleme vs.)
if [ "$exit_code" -eq 19 ]; then
  confirmation=$(echo -e "No\nYes" | fuzzel -d --anchor top-left --x-margin "$REL_X" --y-margin "$REL_Y" --placeholder "Geçmiş silinsin mi?" --lines 2 --width 30)
  [ "$confirmation" == "Yes" ] && rm ~/.cache/cliphist/db && rm -rf "$thumbnail_dir"
elif [ "$exit_code" -eq 10 ]; then
  if [ -n "$item" ]; then
    item_id=$(echo "$item" | cut -f1)
    echo "$item_id" | cliphist delete
    find "$thumbnail_dir" -name "${item_id}.*" -delete
  fi
else
  [ -z "$item" ] || echo "$item" | cliphist decode | wl-copy
fi

# Cache temizliği
find "$thumbnail_dir" -type f | while IFS= read -r thumbnail_file; do
  cliphist_item_id=$(basename "${thumbnail_file%.*}")
  if ! grep -q "^${cliphist_item_id}\s\[\[ binary data" <<<"$cliphist_list"; then
    rm "$thumbnail_file"
  fi
done
