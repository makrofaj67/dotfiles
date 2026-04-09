#!/bin/bash
# Toggle hypridle - returns "on" or "off"

if pgrep -x hypridle > /dev/null; then
    pkill hypridle
    echo "off"
else
    hypridle &
    echo "on"
fi
