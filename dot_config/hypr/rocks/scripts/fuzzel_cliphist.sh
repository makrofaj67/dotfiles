#!/usr/bin/env bash
if pgrep -x "fuzzel" > /dev/null; then
    killall fuzzel
    exit 0
fi

POS=$(hyprctl cursorpos)
X=$(echo "$POS" | cut -d, -f1 | tr -d ' ')
Y=$(echo "$POS" | cut -d, -f2 | tr -d ' ')

thumbnail_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/thumbnails"
[ -d "$thumbnail_dir" ] || mkdir -p "$thumbnail_dir"

cliphist_list=$(cliphist list)

if [ -z "$cliphist_list" ]; then
  fuzzel -d \
    --anchor top-left \
    --x-margin "$X" \
    --y-margin "$Y" \
    --prompt-only "cliphist: please store something first "
  rm -rf "$thumbnail_dir"
  exit
fi

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

item=$(echo "$cliphist_list" | gawk "$thumbnail" | fuzzel -d \
  --anchor top-left \
  --x-margin "$X" \
  --y-margin "$Y" \
  --placeholder "Search clipboard..." \
  --counter --no-sort --with-nth 2)

exit_code=$?

if [ "$exit_code" -eq 19 ]; then
  confirmation=$(echo -e "No\nYes" | fuzzel -d \
    --anchor top-left \
    --x-margin "$X" \
    --y-margin "$Y" \
    --placeholder "Delete history?" \
    --lines 2)
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


find "$thumbnail_dir" -type f | while IFS= read -r thumbnail_file; do
  cliphist_item_id=$(basename "${thumbnail_file%.*}")
  if ! grep -q "^${cliphist_item_id}\s\[\[ binary data" <<<"$cliphist_list"; then
    rm "$thumbnail_file"
  fi
done
