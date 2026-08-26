import ".."
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

Rectangle {
    id: brightnessWidget

    property bool isHDMI: false
    property bool isNightLightOn: false
    property bool isTempMode: false
    property int nightTemperature: 4000
    property real laptopBrightness: 0
    property real hdmiBrightness: 0
    property real maxLaptopBrightness: 64764

    color: Theme.base
    border.color: Theme.border
    height: 31
    width: mainRow.width + 20
    radius: 4

    Process {
        id: getMaxBrightness
        command: ["sh", "-c", "brightnessctl max"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var m = parseInt(text.trim());
                    if (!isNaN(m) && m > 0) {
                        brightnessWidget.maxLaptopBrightness = m;
                    }
                } catch(e) {}
            }
        }
    }

    Timer {
        id: setBrightnessDebounce
        interval: 100
        repeat: false
        onTriggered: {
            setBrightness.running = false;
            setBrightness.running = true;
        }
    }

    Timer {
        id: setTempDebounce
        interval: 50
        repeat: false
        onTriggered: {
            setTempProcess.running = false;
            setTempProcess.running = true;
        }
    }

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 6

        // Night Light Button (Left-click: Toggle On/Off, Right-click: Temperature Slider Mode)
        Rectangle {
            id: nightBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: nightMouse.pressed ? (brightnessWidget.isNightLightOn ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) : (brightnessWidget.isNightLightOn ? Theme.activeButtonBackground : Theme.passiveButtonBackground)
            border.color: nightMouse.pressed ? (brightnessWidget.isNightLightOn ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) : (brightnessWidget.isNightLightOn ? Theme.activeButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰃛"
                color: nightMouse.pressed ? (brightnessWidget.isNightLightOn ? Theme.activePressedButtonText : Theme.passivePressedButtonText) : (brightnessWidget.isNightLightOn ? Theme.activeButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: nightMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        // Right-click: Toggle Temperature slider mode
                        brightnessWidget.isTempMode = !brightnessWidget.isTempMode;
                        if (!brightnessWidget.isTempMode) {
                            getBrightness.running = false;
                            getBrightness.running = true;
                        }
                    } else {
                        // Left-click: Toggle Night Light On / Off
                        if (brightnessWidget.isNightLightOn) {
                            stopNightProcess.running = false;
                            stopNightProcess.running = true;
                        } else {
                            startNightProcess.running = false;
                            startNightProcess.running = true;
                        }
                    }
                }
            }

            // Night Light Tooltip
            Rectangle {
                visible: nightMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: nightTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: nightTipText
                    anchors.centerIn: parent
                    text: brightnessWidget.isNightLightOn 
                          ? ("Night Light: " + brightnessWidget.nightTemperature + "K (Right-click: Temp Slider)") 
                          : "Night Light: Off (Right-click: Temp Slider)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: startNightProcess
                command: ["sh", "-c", "SOCK=$(find \"$XDG_RUNTIME_DIR/hypr\" -name \".hyprsunset.sock\" 2>/dev/null | head -n 1); if [ -n \"$SOCK\" ] && [ -S \"$SOCK\" ]; then echo \"temperature " + brightnessWidget.nightTemperature + "\" | socat - UNIX-CONNECT:\"$SOCK\" 2>/dev/null; else killall hyprsunset 2>/dev/null; hyprsunset -t " + brightnessWidget.nightTemperature + " & fi"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        brightnessWidget.isNightLightOn = true;
                    }
                }
            }

            Process {
                id: stopNightProcess
                command: ["sh", "-c", "SOCK=$(find \"$XDG_RUNTIME_DIR/hypr\" -name \".hyprsunset.sock\" 2>/dev/null | head -n 1); if [ -n \"$SOCK\" ] && [ -S \"$SOCK\" ]; then echo \"identity\" | socat - UNIX-CONNECT:\"$SOCK\" 2>/dev/null; else killall hyprsunset 2>/dev/null; fi"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        brightnessWidget.isNightLightOn = false;
                    }
                }
            }

            Process {
                id: setTempProcess
                command: ["sh", "-c", "SOCK=$(find \"$XDG_RUNTIME_DIR/hypr\" -name \".hyprsunset.sock\" 2>/dev/null | head -n 1); if [ -n \"$SOCK\" ] && [ -S \"$SOCK\" ]; then echo \"temperature " + brightnessWidget.nightTemperature + "\" | socat - UNIX-CONNECT:\"$SOCK\" 2>/dev/null; else killall hyprsunset 2>/dev/null; hyprsunset -t " + brightnessWidget.nightTemperature + " & fi"]
                running: false
            }

            Process {
                id: checkNightProcess
                command: ["sh", "-c", "pgrep -x hyprsunset >/dev/null && echo 'running' || echo 'none'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        // Keep initial detection
                        if (text.trim() === "running" && !brightnessWidget.isNightLightOn) {
                            brightnessWidget.isNightLightOn = true;
                        }
                    }
                }
            }
        }

        // Mode Indicator & Display Switcher (L: Laptop, H: HDMI, K: Kelvin Temperature)
        Rectangle {
            id: toggleBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: toggleMouse.pressed ? (brightnessWidget.isTempMode ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) : (brightnessWidget.isTempMode ? "#ffaa44" : Theme.passiveButtonBackground)
            border.color: toggleMouse.pressed ? (brightnessWidget.isTempMode ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) : (brightnessWidget.isTempMode ? "#ffaa44" : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: brightnessWidget.isTempMode ? "K" : (brightnessWidget.isHDMI ? "H" : "L")
                color: toggleMouse.pressed ? (brightnessWidget.isTempMode ? Theme.activePressedButtonText : Theme.passivePressedButtonText) : (brightnessWidget.isTempMode ? Theme.background : Theme.passiveButtonText)
                font.pixelSize: 11
                font.bold: true
                font.family: "Hack"
            }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (brightnessWidget.isTempMode) {
                        // Switch out of temp mode back to brightness
                        brightnessWidget.isTempMode = false;
                        getBrightness.running = false;
                        getBrightness.running = true;
                        return;
                    }

                    // Save current before switching
                    if (brightnessWidget.isHDMI)
                        brightnessWidget.hdmiBrightness = brightnessSlider.value;
                    else
                        brightnessWidget.laptopBrightness = brightnessSlider.value;

                    brightnessWidget.isHDMI = !brightnessWidget.isHDMI;

                    // Instantly set to the stored value to prevent max jump
                    brightnessSlider.value = brightnessWidget.isHDMI ? brightnessWidget.hdmiBrightness : brightnessWidget.laptopBrightness;

                    // Trigger a fetch when switching modes
                    getBrightness.running = false;
                    getBrightness.running = true;
                }
            }

            // Brightness / Temp Mode Tooltip
            Rectangle {
                visible: toggleMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: brightTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: brightTipText
                    anchors.centerIn: parent
                    text: brightnessWidget.isTempMode 
                          ? ("Temperature Mode: " + brightnessWidget.nightTemperature + "K (Click to Exit)")
                          : (brightnessWidget.isHDMI ? "Display: HDMI (ddcutil)" : "Display: Laptop (Internal)")
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }

        // Dual-Purpose Slider (Brightness or Color Temperature)
        Slider {
            id: brightnessSlider

            anchors.verticalCenter: parent.verticalCenter
            width: 120
            height: 22
            padding: 0

            from: brightnessWidget.isTempMode ? 2000 : 0
            to: brightnessWidget.isTempMode ? 6500 : (brightnessWidget.isHDMI ? 100 : brightnessWidget.maxLaptopBrightness)
            stepSize: brightnessWidget.isTempMode ? 50 : (brightnessWidget.isHDMI ? 1 : Math.max(1, Math.round(brightnessWidget.maxLaptopBrightness / 100)))

            value: brightnessWidget.isTempMode 
                   ? brightnessWidget.nightTemperature 
                   : (brightnessWidget.isHDMI ? brightnessWidget.hdmiBrightness : brightnessWidget.laptopBrightness)

            onMoved: {
                if (brightnessWidget.isTempMode) {
                    brightnessWidget.nightTemperature = Math.round(brightnessSlider.value);
                    brightnessWidget.isNightLightOn = true;
                    setTempDebounce.restart();
                } else {
                    // Update local storage
                    if (brightnessWidget.isHDMI)
                        brightnessWidget.hdmiBrightness = brightnessSlider.value;
                    else
                        brightnessWidget.laptopBrightness = brightnessSlider.value;

                    setBrightnessDebounce.restart();
                }
            }

            Process {
                id: getBrightness

                command: brightnessWidget.isHDMI 
                         ? ["sh", "-c", "ddcutil getvcp 10 --display 1 | grep -oP 'current value = \\s*\\K[0-9]+'"]
                         : ["sh", "-c", "brightnessctl get"]
                running: !brightnessWidget.isTempMode

                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            if (text.trim() !== "") {
                                var val = parseInt(text.trim());
                                if (!brightnessWidget.isTempMode) {
                                    brightnessSlider.value = val;
                                }
                                if (brightnessWidget.isHDMI)
                                    brightnessWidget.hdmiBrightness = val;
                                else
                                    brightnessWidget.laptopBrightness = val;
                            }
                        } catch (e) {
                        }
                    }
                }
            }

            Process {
                id: setBrightness

                command: brightnessWidget.isHDMI 
                         ? ["sh", "-c", "ddcutil setvcp 10 " + Math.round(brightnessSlider.value) + " --display 1"]
                         : ["sh", "-c", "brightnessctl set " + Math.round(brightnessSlider.value)]
                running: false
            }

            background: Rectangle {
                x: brightnessSlider.leftPadding
                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                width: brightnessSlider.availableWidth
                height: 4
                radius: 2
                color: Theme.background

                Rectangle {
                    width: brightnessSlider.visualPosition * parent.width
                    height: parent.height
                    color: brightnessWidget.isTempMode ? "#ffaa44" : Theme.border
                    radius: 2
                }
            }

            handle: Rectangle {
                x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
                y: brightnessSlider.topPadding + brightnessSlider.availableHeight / 2 - height / 2
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: brightnessSlider.pressed ? (brightnessWidget.isTempMode ? "#ffaa44" : Theme.border) : Theme.base
                border.color: brightnessWidget.isTempMode ? "#ffaa44" : Theme.border
                border.width: 1
            }
        }
    }
}
