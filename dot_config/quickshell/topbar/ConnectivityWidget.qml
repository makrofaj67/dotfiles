import ".."
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

Rectangle {
    id: connectivityWidget

    property bool isWifiOn: false
    property bool isBtOn: false
    property bool isMuted: false

    color: Theme.base
    border.color: Theme.border
    height: 31
    width: connRow.width + 16
    radius: 4

    Row {
        id: connRow
        anchors.centerIn: parent
        spacing: 8

        // 1. WiFi Button
        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: wifiMouse.pressed ? (connectivityWidget.isWifiOn ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) : (connectivityWidget.isWifiOn ? Theme.activeButtonBackground : Theme.passiveButtonBackground)
            border.color: wifiMouse.pressed ? (connectivityWidget.isWifiOn ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) : (connectivityWidget.isWifiOn ? Theme.activeButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: connectivityWidget.isWifiOn ? "󰖩" : "󰖪"
                color: wifiMouse.pressed ? (connectivityWidget.isWifiOn ? Theme.activePressedButtonText : Theme.passivePressedButtonText) : (connectivityWidget.isWifiOn ? Theme.activeButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    connectivityWidget.isWifiOn = !connectivityWidget.isWifiOn;
                    toggleWifi.running = false;
                    toggleWifi.running = true;
                }
            }

            // WiFi Tooltip
            Rectangle {
                visible: wifiMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: wifiTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: wifiTipText
                    anchors.centerIn: parent
                    text: connectivityWidget.isWifiOn ? "Wi-Fi: On" : "Wi-Fi: Off"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: getWifiStatus
                command: ["sh", "-c", "nmcli radio wifi"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.trim() === "enabled") {
                            connectivityWidget.isWifiOn = true;
                        } else {
                            connectivityWidget.isWifiOn = false;
                        }
                    }
                }
            }

            Process {
                id: toggleWifi
                command: ["sh", "-c", "nmcli radio wifi " + (connectivityWidget.isWifiOn ? "on" : "off")]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        getWifiStatus.running = false;
                        getWifiStatus.running = true;
                    }
                }
            }
        }

        // 2. Bluetooth Button
        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: btMouse.pressed ? (connectivityWidget.isBtOn ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) : (connectivityWidget.isBtOn ? Theme.activeButtonBackground : Theme.passiveButtonBackground)
            border.color: btMouse.pressed ? (connectivityWidget.isBtOn ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) : (connectivityWidget.isBtOn ? Theme.activeButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: connectivityWidget.isBtOn ? "󰂯" : "󰂲"
                color: btMouse.pressed ? (connectivityWidget.isBtOn ? Theme.activePressedButtonText : Theme.passivePressedButtonText) : (connectivityWidget.isBtOn ? Theme.activeButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: btMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    connectivityWidget.isBtOn = !connectivityWidget.isBtOn;
                    toggleBt.running = false;
                    toggleBt.running = true;
                }
            }

            // Bluetooth Tooltip
            Rectangle {
                visible: btMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: btTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: btTipText
                    anchors.centerIn: parent
                    text: connectivityWidget.isBtOn ? "Bluetooth: On" : "Bluetooth: Off"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: getBtStatus
                command: ["sh", "-c", "bluetoothctl show | grep -qi 'Powered: yes' && echo 'enabled' || echo 'disabled'"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        if (text.trim() === "enabled") {
                            connectivityWidget.isBtOn = true;
                        } else {
                            connectivityWidget.isBtOn = false;
                        }
                    }
                }
            }

            Process {
                id: toggleBt
                command: ["sh", "-c", "bluetoothctl power " + (connectivityWidget.isBtOn ? "on" : "off")]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        getBtStatus.running = false;
                        getBtStatus.running = true;
                    }
                }
            }
        }

        // 3. Mute Toggle Button (Global Killswitch)
        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: muteMouse.pressed ? (!connectivityWidget.isMuted ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) : (!connectivityWidget.isMuted ? Theme.activeButtonBackground : Theme.passiveButtonBackground)
            border.color: muteMouse.pressed ? (!connectivityWidget.isMuted ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) : (!connectivityWidget.isMuted ? Theme.activeButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: connectivityWidget.isMuted ? "󰝟" : "󰕾"
                color: muteMouse.pressed ? (!connectivityWidget.isMuted ? Theme.activePressedButtonText : Theme.passivePressedButtonText) : (!connectivityWidget.isMuted ? Theme.activeButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    connectivityWidget.isMuted = !connectivityWidget.isMuted;
                    toggleMute.running = false;
                    toggleMute.running = true;
                }
            }

            // Mute Tooltip
            Rectangle {
                visible: muteMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: muteTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: muteTipText
                    anchors.centerIn: parent
                    text: connectivityWidget.isMuted ? "Audio: Muted" : "Audio: Active"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: getMuteStatus
                command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            var res = text.trim();
                            if (res !== "") {
                                connectivityWidget.isMuted = (res.indexOf("[MUTED]") !== -1);
                            }
                        } catch (e) {}
                    }
                }
            }

            Process {
                id: toggleMute
                // Mutes or unmutes ALL sinks based on connectivityWidget.isMuted
                command: ["sh", "-c", "MUTE_STATE=" + (connectivityWidget.isMuted ? "1" : "0") + "; wpctl status | awk '/Sinks:/,/Sources:/' | grep -oP '\\d+(?=\\.)' | xargs -I {} wpctl set-mute {} $MUTE_STATE"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        getMuteStatus.running = false;
                        getMuteStatus.running = true;
                    }
                }
            }
        }
    }
}
