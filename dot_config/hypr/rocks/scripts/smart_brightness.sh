#!/bin/bash

# Log dosyası (Hata ayıklamak için, çalışmazsa buraya bakacağız)
LOG_FILE="/tmp/brightness_debug.log"

# Argüman kontrolü
if [ -z "$1" ]; then
    echo "Usage: $0 {up|down}"
    exit 1
fi

DIRECTION=$1
STEP_LAPTOP=5   # Laptop %5 artış
STEP_EXT=10     # Harici %10 artış

# 1. Farenin X koordinatını al
# hyprctl cursorpos çıktısı "350, 540" şeklindedir. Biz virgülden öncesini alacağız.
MOUSE_POS=$(hyprctl cursorpos)
MOUSE_X=${MOUSE_POS%,*}

# 2. Koordinata göre monitörü belirle
# Senin düzenine göre: HDMI (0-1919 arası), Laptop (1920 ve sonrası)
if [ "$MOUSE_X" -lt 1920 ]; then
    CURRENT_MONITOR="HDMI-A-1"
else
    CURRENT_MONITOR="eDP-1"
fi

# Debug için loga yaz (İstersen bu satırı silebilirsin)
echo "$(date): Mouse X=$MOUSE_X Monitor=$CURRENT_MONITOR Direction=$DIRECTION" >> $LOG_FILE

# 3. İşlemi Uygula
case "$CURRENT_MONITOR" in
    "eDP-1")
        # LAPTOP EKRANI
        if [ "$DIRECTION" == "up" ]; then
            brightnessctl s +${STEP_LAPTOP}%
        else
            brightnessctl s ${STEP_LAPTOP}%-
        fi

  CURRENT_PERC=$(brightnessctl -m | cut -d, -f4)
        notify-send -h string:x-canonical-private-synchronous:brightness_notify -t 1000 "Laptop Parlaklık: $CURRENT_PERC"
        ;;

    "HDMI-A-1")
        # HARİCİ EKRAN (ddcutil)
        # Mevcut parlaklığı al
        CURRENT_VAL=$(ddcutil getvcp 10 --bus 23 --terse | awk '{print $4}')
        
        # Eğer ddcutil okuyamazsa (izin hatası vs) çık
        if [ -z "$CURRENT_VAL" ]; then
            echo "HATA: ddcutil değer okuyamadı. İzinleri kontrol et." >> $LOG_FILE
            exit 1
        fi

        if [ "$DIRECTION" == "up" ]; then
            NEW_VAL=$(($CURRENT_VAL + $STEP_EXT))
            if [ $NEW_VAL -gt 100 ]; then NEW_VAL=100; fi
        else
            NEW_VAL=$(($CURRENT_VAL - $STEP_EXT))
            if [ $NEW_VAL -lt 0 ]; then NEW_VAL=0; fi
        fi
        
        # Yeni değeri uygula
        ddcutil setvcp 10 $NEW_VAL --bus 23 &

		notify-send -h string:x-canonical-private-synchronous:brightness_notify -t 1000 "Harici Ekran: %$NEW_VAL"
        ;;
esac
