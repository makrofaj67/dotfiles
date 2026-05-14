#!/bin/bash

TRIGGERED=0
# Wait a bit for hyprland to fully start if this is run at startup
sleep 2

# Get the width of the first monitor
WIDTH=$(hyprctl monitors -j | grep -m1 '"width":' | grep -o '[0-9]*')
if [ -z "$WIDTH" ]; then
    WIDTH=1920
fi

EDGE=$((WIDTH - 1))

while true; do
    pos=$(hyprctl cursorpos 2>/dev/null)
    x=$(echo "$pos" | cut -d',' -f1)
    
    # Check if x is a valid number
    if [[ "$x" =~ ^[0-9]+$ ]]; then
        if [ "$x" -ge "$EDGE" ]; then
            if [ "$TRIGGERED" -eq 0 ]; then
                swaync-client -op
                TRIGGERED=1
            fi
        else
            if [ "$x" -lt $((EDGE - 50)) ]; then
                TRIGGERED=0
            fi
        fi
    fi
    
    sleep 0.2
done
