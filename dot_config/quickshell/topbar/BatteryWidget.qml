import ".."
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

Rectangle {
    id: batteryWidget

    property string profile: "power-saver" // "power-saver", "balanced", "performance"
    property int batteryPercent: 100
    property bool isCharging: false
    property bool isHypridleActive: true

    color: Theme.base
    border.color: Theme.border
    height: 31
    width: mainRow.width + 16
    radius: 4

    function getProfileLetter() {
        if (profile === "performance") return "P";
        if (profile === "balanced") return "B";
        return "S";
    }

    function getNextProfile() {
        if (profile === "power-saver") return "balanced";
        if (profile === "balanced") return "performance";
        return "power-saver";
    }

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 6

        // 1. Power Profile Button
        Rectangle {
            id: profileBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: profileMouse.pressed ? Theme.passivePressedButtonBackground : Theme.passiveButtonBackground
            border.color: profileMouse.pressed ? Theme.passivePressedButtonBorder : Theme.passiveButtonBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: batteryWidget.getProfileLetter()
                color: profileMouse.pressed ? Theme.passivePressedButtonText : Theme.passiveButtonText
                font.pixelSize: 11
                font.bold: true
                font.family: "Hack"
            }

            MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    var next = batteryWidget.getNextProfile();
                    batteryWidget.profile = next;
                    setProfileProcess.command = ["sh", "-c", "powerprofilesctl set " + next];
                    setProfileProcess.running = false;
                    setProfileProcess.running = true;
                }
            }

            // Power Profile Tooltip
            Rectangle {
                visible: profileMouse.containsMouse
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
                    text: "Power Profile: " + batteryWidget.profile
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }

        // 2. Hypridle Inhibit / Pause / Resume Button
        Rectangle {
            id: idleBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: idleMouse.pressed ? (batteryWidget.isHypridleActive ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) : (batteryWidget.isHypridleActive ? Theme.activeButtonBackground : Theme.passiveButtonBackground)
            border.color: idleMouse.pressed ? (batteryWidget.isHypridleActive ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) : (batteryWidget.isHypridleActive ? Theme.activeButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: batteryWidget.isHypridleActive ? "󰈈" : "󰈉"
                color: idleMouse.pressed ? (batteryWidget.isHypridleActive ? Theme.activePressedButtonText : Theme.passivePressedButtonText) : (batteryWidget.isHypridleActive ? Theme.activeButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: idleMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (batteryWidget.isHypridleActive) {
                        pauseIdleProcess.running = false;
                        pauseIdleProcess.running = true;
                    } else {
                        resumeIdleProcess.running = false;
                        resumeIdleProcess.running = true;
                    }
                }
            }

            // Hypridle Tooltip
            Rectangle {
                visible: idleMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: idleTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: idleTipText
                    anchors.centerIn: parent
                    text: batteryWidget.isHypridleActive 
                          ? "Hypridle: Aktif (5 dk: Kilit | 30 dk: Uyku)" 
                          : "Hypridle: Duraklatıldı (Ekran & Uyku Devre Dışı)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }

        // 3. Battery Percentage Text
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (batteryWidget.isCharging ? "+" : "") + batteryWidget.batteryPercent + "%"
            color: (batteryWidget.batteryPercent <= 20 && !batteryWidget.isCharging) ? Theme.error : Theme.text
            font.pixelSize: 13
            font.bold: true
            font.family: "Hack"
        }
    }

    // Hypridle Processes
    Process {
        id: checkIdleProcess
        command: ["sh", "-c", "ps -o stat= -C hypridle 2>/dev/null | grep -q 'T' && echo 'paused' || (pgrep -x hypridle >/dev/null && echo 'running' || echo 'none')"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var res = text.trim();
                batteryWidget.isHypridleActive = (res === "running");
            }
        }
    }

    Process {
        id: pauseIdleProcess
        command: ["sh", "-c", "killall -STOP hypridle 2>/dev/null || killall hypridle 2>/dev/null"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                batteryWidget.isHypridleActive = false;
            }
        }
    }

    Process {
        id: resumeIdleProcess
        command: ["sh", "-c", "killall -CONT hypridle 2>/dev/null || (pgrep -x hypridle >/dev/null || hypridle &)"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                batteryWidget.isHypridleActive = true;
            }
        }
    }

    // Process to get active power profile
    Process {
        id: getProfileProcess
        command: ["sh", "-c", "powerprofilesctl get"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var p = text.trim();
                if (p === "performance" || p === "balanced" || p === "power-saver") {
                    batteryWidget.profile = p;
                }
            }
        }
    }

    // Process to set power profile
    Process {
        id: setProfileProcess
        command: ["sh", "-c", "powerprofilesctl set " + batteryWidget.profile]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                getProfileProcess.running = false;
                getProfileProcess.running = true;
            }
        }
    }

    // Process to read battery capacity & charging status
    Process {
        id: getBatteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT1/capacity /sys/class/power_supply/BAT1/status 2>/dev/null || cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var lines = text.trim().split("\n");
                    if (lines.length >= 1 && lines[0] !== "") {
                        batteryWidget.batteryPercent = parseInt(lines[0]);
                    }
                    if (lines.length >= 2) {
                        batteryWidget.isCharging = (lines[1].trim() === "Charging");
                    }
                } catch(e) {}
            }
        }
    }

    // Update battery and idle status periodically
    Timer {
        interval: 15000
        repeat: true
        running: true
        onTriggered: {
            getBatteryProcess.running = false;
            getBatteryProcess.running = true;
            getProfileProcess.running = false;
            getProfileProcess.running = true;
            checkIdleProcess.running = false;
            checkIdleProcess.running = true;
        }
    }
}
