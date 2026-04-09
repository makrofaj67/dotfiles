#!/bin/bash
# Clipboard manager - get recent items from cliphist

cliphist list | head -10 | while read -r line; do
    # Her satırı JSON formatına çevir
    content=$(echo "$line" | sed 's/"/\\"/g' | cut -c1-50)
    echo "{\"content\": \"$content\"}"
done | jq -s '.'
