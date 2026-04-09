#!/bin/bash
# Notepad handler - read/write notes

NOTE_FILE="$HOME/.config/quickshell/data/notes.txt"
mkdir -p "$(dirname "$NOTE_FILE")"

case "$1" in
    read)
        if [ -f "$NOTE_FILE" ]; then
            cat "$NOTE_FILE"
        fi
        ;;
    write)
        shift
        echo "$*" > "$NOTE_FILE"
        ;;
esac
