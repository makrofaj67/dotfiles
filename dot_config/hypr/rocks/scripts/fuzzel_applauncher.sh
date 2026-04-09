# Eğer fuzzel çalışıyorsa (işlem listesinde varsa)
if pgrep -x "fuzzel" > /dev/null; then
    killall fuzzel
else
    fuzzel
fi
