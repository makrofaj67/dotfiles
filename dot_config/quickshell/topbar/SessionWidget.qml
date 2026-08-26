import ".."
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

Rectangle {
    id: sessionWidget

    color: Theme.base
    border.color: Theme.border
    height: 26
    width: sessionRow.width + 16
    radius: 4

    Row {
        id: sessionRow
        anchors.centerIn: parent
        spacing: 8

        // 1. Lock Screen Button (L)
        Rectangle {
            width: 16
            height: 16
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: lockMouse.pressed ? Theme.text : Theme.border
            border.color: Theme.background
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "L"
                color: Theme.background
                font.pixelSize: 10
                font.bold: true
                font.family: "Hack"
            }

            MouseArea {
                id: lockMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    lockProcess.running = false
                    lockProcess.running = true
                }
            }

            // Lock Tooltip
            Rectangle {
                visible: lockMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: lockTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: lockTipText
                    anchors.centerIn: parent
                    text: "Lock Screen (hyprlock)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: lockProcess
                command: ["sh", "-c", "hyprlock || loginctl lock-session"]
                running: false
            }
        }

        // 2. Power Off / Shutdown Button (X)
        Rectangle {
            width: 16
            height: 16
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: powerMouse.pressed ? Theme.error : Theme.border
            border.color: Theme.background
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "X"
                color: Theme.background
                font.pixelSize: 10
                font.bold: true
                font.family: "Hack"
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        rebootProcess.running = false
                        rebootProcess.running = true
                    } else {
                        shutdownProcess.running = false
                        shutdownProcess.running = true
                    }
                }
            }

            // Power Tooltip
            Rectangle {
                visible: powerMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: powerTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: powerTipText
                    anchors.centerIn: parent
                    text: "Shutdown (Right-click: Reboot)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: shutdownProcess
                command: ["sh", "-c", "systemctl poweroff"]
                running: false
            }

            Process {
                id: rebootProcess
                command: ["sh", "-c", "systemctl reboot"]
                running: false
            }
        }
    }
}
