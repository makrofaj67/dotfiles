#!/bin/sh
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

if [ ! -d "build" ]; then
    meson setup build
fi

ninja -C build
echo "Build successful: $DIR/build/libhypr-qswitcher-plugin.so"

hyprctl plugin load "$DIR/build/libhypr-qswitcher-plugin.so" || true
echo "Plugin loaded into Hyprland!"
