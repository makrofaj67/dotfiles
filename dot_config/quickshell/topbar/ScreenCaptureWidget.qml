import ".."
import QtQuick
import QtQuick.Controls.Basic
import Quickshell.Io

Rectangle {
    id: screenCaptureWidget

    property bool isAreaCapture: true
    property bool isRecArea: false
    property bool isRecording: false
    property bool showMonitorPicker: false

    color: Theme.base
    border.color: Theme.border
    height: 31
    width: capRow.width + 16
    radius: 4

    Row {
        id: capRow
        anchors.centerIn: parent
        spacing: 6

        // 1. Screenshot / Capture Button (Area vs Screen)
        Rectangle {
            id: shotBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: shotMouse.pressed ? Theme.passivePressedButtonBackground : Theme.passiveButtonBackground
            border.color: shotMouse.pressed ? Theme.passivePressedButtonBorder : Theme.passiveButtonBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: screenCaptureWidget.isAreaCapture ? "󰆞" : "󰍹"
                color: shotMouse.pressed ? Theme.passivePressedButtonText : Theme.passiveButtonText
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: shotMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    screenCaptureWidget.showMonitorPicker = false;
                    if (mouse.button === Qt.RightButton) {
                        // Right click toggles Area vs Full Screen mode
                        screenCaptureWidget.isAreaCapture = !screenCaptureWidget.isAreaCapture;
                    } else {
                        // Left click takes screenshot immediately
                        takeScreenshotProcess.running = false;
                        takeScreenshotProcess.running = true;
                    }
                }
            }

            // Screenshot Tooltip
            Rectangle {
                visible: shotMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: shotTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: shotTipText
                    anchors.centerIn: parent
                    text: screenCaptureWidget.isAreaCapture ? "Capture: Area (Right-click: Screen)" : "Capture: Full Screen (Right-click: Area)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }

            Process {
                id: takeScreenshotProcess
                command: ["sh", "-c", "sleep 0.1; if [ \"" + (screenCaptureWidget.isAreaCapture ? "1" : "0") + "\" = \"1\" ]; then grimblast --freeze copysave area && notify-send 'Ekran Görüntüsü' 'Alan görüntüsü panoya kopyalandı ve kaydedildi.' -i camera-photo; else grimblast --freeze copysave output && notify-send 'Ekran Görüntüsü' 'Ekran görüntüsü panoya kopyalandı ve kaydedildi.' -i camera-photo; fi"]
                running: false
            }
        }

        // 2. Screen Recording Button (Area vs Full Screen)
        Rectangle {
            id: recBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: screenCaptureWidget.isRecording ? Theme.error : (recMouse.pressed ? Theme.passivePressedButtonBackground : Theme.passiveButtonBackground)
            border.color: screenCaptureWidget.isRecording ? Theme.error : (recMouse.pressed ? Theme.passivePressedButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: screenCaptureWidget.isRecording ? "󰑋" : (screenCaptureWidget.isRecArea ? "󰕧" : "󰻃")
                color: screenCaptureWidget.isRecording ? Theme.text : (recMouse.pressed ? Theme.passivePressedButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: recMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        // Right click toggles Area vs Full Screen mode
                        if (!screenCaptureWidget.isRecording) {
                            screenCaptureWidget.isRecArea = !screenCaptureWidget.isRecArea
                            screenCaptureWidget.showMonitorPicker = false;
                        }
                    } else {
                        // Left click starts or stops recording
                        if (screenCaptureWidget.isRecording) {
                            screenCaptureWidget.showMonitorPicker = false;
                            stopRecProcess.running = false
                            stopRecProcess.running = true
                        } else {
                            if (screenCaptureWidget.isRecArea) {
                                screenCaptureWidget.showMonitorPicker = false;
                                startAreaRecProcess.running = false;
                                startAreaRecProcess.running = true;
                            } else {
                                // Full Screen Mode: Expand inline L / H buttons
                                screenCaptureWidget.showMonitorPicker = !screenCaptureWidget.showMonitorPicker;
                            }
                        }
                    }
                }
            }

            // Recording Tooltip
            Rectangle {
                visible: recMouse.containsMouse && !screenCaptureWidget.showMonitorPicker
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: recTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: recTipText
                    anchors.centerIn: parent
                    text: screenCaptureWidget.isRecording ? "Recording... (Click to Stop)" : (screenCaptureWidget.isRecArea ? "Record: Area (Right-click: Full)" : "Record: Full Screen (Click for L/H)")
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }

        // 3. Laptop Option Button (L: eDP-1) - Inline in Bar
        Rectangle {
            id: laptopBtn
            visible: screenCaptureWidget.showMonitorPicker && !screenCaptureWidget.isRecording
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: laptopMouse.pressed ? Theme.passivePressedButtonBackground : Theme.passiveButtonBackground
            border.color: laptopMouse.pressed ? Theme.passivePressedButtonBorder : Theme.passiveButtonBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "L"
                color: laptopMouse.pressed ? Theme.passivePressedButtonText : Theme.passiveButtonText
                font.pixelSize: 11
                font.bold: true
                font.family: "Hack"
            }

            MouseArea {
                id: laptopMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    screenCaptureWidget.showMonitorPicker = false;
                    startLaptopRecProcess.running = false;
                    startLaptopRecProcess.running = true;
                }
            }

            // Tooltip
            Rectangle {
                visible: laptopMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: lTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: lTipText
                    anchors.centerIn: parent
                    text: "Record Laptop (eDP-1)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }

        // 4. HDMI Option Button (H: HDMI-A-1) - Inline in Bar
        Rectangle {
            id: hdmiBtn
            visible: screenCaptureWidget.showMonitorPicker && !screenCaptureWidget.isRecording
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: hdmiMouse.pressed ? Theme.passivePressedButtonBackground : Theme.passiveButtonBackground
            border.color: hdmiMouse.pressed ? Theme.passivePressedButtonBorder : Theme.passiveButtonBorder
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "H"
                color: hdmiMouse.pressed ? Theme.passivePressedButtonText : Theme.passiveButtonText
                font.pixelSize: 11
                font.bold: true
                font.family: "Hack"
            }

            MouseArea {
                id: hdmiMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    screenCaptureWidget.showMonitorPicker = false;
                    startHdmiRecProcess.running = false;
                    startHdmiRecProcess.running = true;
                }
            }

            // Tooltip
            Rectangle {
                visible: hdmiMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: hTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: hTipText
                    anchors.centerIn: parent
                    text: "Record HDMI (HDMI-A-1)"
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }
    }

    // 1. Area Recording Process (with 0.1s pointer grab release delay)
    Process {
        id: startAreaRecProcess
        command: ["sh", "-c", "sleep 0.1; mkdir -p \"$HOME/Videos\"; FILE=\"$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4\"; GEOM=$(slurp); if [ -n \"$GEOM\" ]; then notify-send 'Ekran Kaydı' 'Alan kaydı başlatıldı (60fps)...' -i media-record; wf-recorder -y -g \"$GEOM\" -r 60 -c libx264 -p crf=18 -p preset=faster -x yuv420p -f \"$FILE\"; notify-send 'Ekran Kaydı' \"Kayıt tamamlandı:\n$(basename \"$FILE\")\" -i video-x-generic; fi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                checkRecProcess.running = false
                checkRecProcess.running = true
            }
        }
    }

    // 2. Laptop (eDP-1) Recording Process
    Process {
        id: startLaptopRecProcess
        command: ["sh", "-c", "mkdir -p \"$HOME/Videos\"; FILE=\"$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4\"; notify-send 'Ekran Kaydı' 'Laptop (eDP-1) ekran kaydı başlatıldı (60fps)...' -i media-record; wf-recorder -y -o eDP-1 -r 60 -c libx264 -p crf=18 -p preset=faster -x yuv420p -f \"$FILE\"; notify-send 'Ekran Kaydı' \"Kayıt tamamlandı:\n$(basename \"$FILE\")\" -i video-x-generic"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                checkRecProcess.running = false
                checkRecProcess.running = true
            }
        }
    }

    // 3. HDMI (HDMI-A-1) Recording Process
    Process {
        id: startHdmiRecProcess
        command: ["sh", "-c", "mkdir -p \"$HOME/Videos\"; FILE=\"$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4\"; notify-send 'Ekran Kaydı' 'HDMI (HDMI-A-1) ekran kaydı başlatıldı (60fps)...' -i media-record; wf-recorder -y -o HDMI-A-1 -r 60 -c libx264 -p crf=18 -p preset=faster -x yuv420p -f \"$FILE\"; notify-send 'Ekran Kaydı' \"Kayıt tamamlandı:\n$(basename \"$FILE\")\" -i video-x-generic"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                checkRecProcess.running = false
                checkRecProcess.running = true
            }
        }
    }

    // Stop Recording Process
    Process {
        id: stopRecProcess
        command: ["sh", "-c", "killall -INT wf-recorder"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                checkRecProcess.running = false
                checkRecProcess.running = true
            }
        }
    }

    // Status Check Process
    Process {
        id: checkRecProcess
        command: ["sh", "-c", "pgrep -x wf-recorder >/dev/null && echo 'recording' || echo 'idle'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                screenCaptureWidget.isRecording = (text.trim() === "recording")
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            checkRecProcess.running = false
            checkRecProcess.running = true
        }
    }
}
