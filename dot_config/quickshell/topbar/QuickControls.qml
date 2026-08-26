import ".."
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

Rectangle {
    id: quickControlsWidget

    color: Theme.base
    border.color: Theme.border
    height: 31
    width: mainRow.width + 16
    radius: 4

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 8

        // 1. Color Picker Button (󰈊)
        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: colorMouse.pressed ? Theme.pressedButtonBackground : Theme.passiveButtonBackground
            border.color: colorMouse.pressed ? Theme.pressedButtonBorder : Theme.passiveButtonBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰈊"
                color: colorMouse.pressed ? Theme.pressedButtonText : Theme.passiveButtonText
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: colorMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    pickColorProcess.running = false
                    pickColorProcess.running = true
                }
            }

            // Color Picker Tooltip
            Rectangle {
                visible: colorMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: colorTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: colorTipText
                    anchors.centerIn: parent
                    text: "Color Picker (hyprpicker)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: pickColorProcess
                command: ["sh", "-c", "hyprpicker -a"]
                running: false
            }
        }

        // 2. Wallpaper Picker Button (󰸉)
        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: wallpaperMouse.pressed ? Theme.pressedButtonBackground : Theme.passiveButtonBackground
            border.color: wallpaperMouse.pressed ? Theme.pressedButtonBorder : Theme.passiveButtonBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰸉"
                color: wallpaperMouse.pressed ? Theme.pressedButtonText : Theme.passiveButtonText
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: wallpaperMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    selectWallpaperProcess.running = false
                    selectWallpaperProcess.running = true
                }
            }

            // Wallpaper Picker Tooltip
            Rectangle {
                visible: wallpaperMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: wpTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: wpTipText
                    anchors.centerIn: parent
                    text: "Select Wallpaper (zenity)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: selectWallpaperProcess
                command: ["sh", "-c", "WP=$(zenity --file-selection --title='Select Wallpaper' --file-filter='Images | *.jpg *.jpeg *.png *.webp *.gif'); if [ -n \"$WP\" ]; then hyprpaper_config=\"$HOME/.config/hypr/hyprpaper.conf\"; hyprctl hyprpaper unload all; hyprctl hyprpaper preload \"$WP\"; hyprctl hyprpaper wallpaper \", $WP\"; echo -e \"preload = $WP\\nwallpaper = , $WP\" > \"$hyprpaper_config\"; fi"]
                running: false
            }
        }
    }
}
