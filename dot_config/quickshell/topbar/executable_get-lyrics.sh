#!/usr/bin/env bash
ARTIST="$1"
TITLE="$2"
ALBUM="$3"
DURATION="$4"

if [ -z "$TITLE" ]; then
    echo '{"notFound":true}'
    exit 0
fi

# Cache dir
CACHE_DIR="/tmp/quickshell-lyrics"
mkdir -p "$CACHE_DIR"

# Clean cache key
CACHE_KEY=$(echo "${ARTIST}_${TITLE}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_]/_/g')
CACHE_FILE="$CACHE_DIR/${CACHE_KEY}.json"

if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Clean title and artist for search
CLEAN_TITLE=$(echo "$TITLE" | sed -E 's/\s*-\s*Remaster(ed)?(\s*[0-9]+)?//gi; s/\s*\(feat\..*\)//gi; s/\s*\[feat\..*\]//gi; s/\s*\(.*version.*\)//gi; s/\s*\(.*mix.*\)//gi')
CLEAN_ARTIST=$(echo "$ARTIST" | sed -E 's/,.*//g; s/\s*feat\..*//gi')
QUERY="${CLEAN_ARTIST} ${CLEAN_TITLE}"

# 1. Primary Server: LRCLIB (Exact Match)
RES=$(curl -s -f -G "https://lrclib.net/api/get" \
    --connect-timeout 2 \
    --max-time 4 \
    --data-urlencode "track_name=$CLEAN_TITLE" \
    --data-urlencode "artist_name=$CLEAN_ARTIST" 2>/dev/null)

if [ -n "$RES" ] && echo "$RES" | grep -q "syncedLyrics" && [ "$(echo "$RES" | jq -r '.syncedLyrics // empty')" != "" ]; then
    echo "$RES" > "$CACHE_FILE"
    echo "$RES"
    exit 0
fi

# 2. Primary Server: LRCLIB (Search Match)
RES=$(curl -s -f -G "https://lrclib.net/api/search" \
    --connect-timeout 2 \
    --max-time 4 \
    --data-urlencode "q=$QUERY" 2>/dev/null)

if [ -n "$RES" ] && [ "$RES" != "[]" ]; then
    # Find first item with non-empty syncedLyrics
    ITEM=$(echo "$RES" | jq -c '.[] | select(.syncedLyrics != null and .syncedLyrics != "")' 2>/dev/null | head -n 1)
    if [ -n "$ITEM" ] && [ "$ITEM" != "null" ]; then
        echo "$ITEM" > "$CACHE_FILE"
        echo "$ITEM"
        exit 0
    fi
fi

# 3. Fallback Server: Try LRCLIB search with just title if artist failed
RES=$(curl -s -f -G "https://lrclib.net/api/search" \
    --connect-timeout 2 \
    --max-time 4 \
    --data-urlencode "q=$CLEAN_TITLE" 2>/dev/null)

if [ -n "$RES" ] && [ "$RES" != "[]" ]; then
    ITEM=$(echo "$RES" | jq -c '.[] | select(.syncedLyrics != null and .syncedLyrics != "")' 2>/dev/null | head -n 1)
    if [ -n "$ITEM" ] && [ "$ITEM" != "null" ]; then
        echo "$ITEM" > "$CACHE_FILE"
        echo "$ITEM"
        exit 0
    fi
fi

# Synced Lyrics Not Found
echo '{"notFound":true}' > "$CACHE_FILE"
echo '{"notFound":true}'
