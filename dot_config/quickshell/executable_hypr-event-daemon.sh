#!/bin/sh
# Forwards Hyprland socket events to localhost TCP port 23456
SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
if [ -z "$XDG_RUNTIME_DIR" ] || [ ! -S "$SOCK" ]; then
    echo "Hypr socket not found: $SOCK" >&2
    exit 1
fi
exec socat -u "UNIX-CONNECT:$SOCK" TCP-LISTEN:23456,reuseaddr,bind=127.0.0.1
