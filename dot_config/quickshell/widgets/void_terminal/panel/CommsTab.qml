import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."

// ╔══════════════════════════════════════════════════════════════╗
// ║  COMMS TAB - Communication & Audio Controls                   ║
// ║  WiFi, Bluetooth, Volume                                      ║
// ╚══════════════════════════════════════════════════════════════╝

ColumnLayout {
    id: commsTab
    spacing: 8
    
    required property bool isActive
    
    // ═══ STATE ═══
    property int volume: 50
    property bool muted: false
    property bool wifiEnabled: true
    property string wifiNetwork: "..."
    property bool bluetoothEnabled: false
    property string btDevice: "No device"
    
    Component.onCompleted: {
        getVolumeProcess.running = true
        getWifiProcess.running = true
        getBtProcess.running = true
    }
    
    // ▓▓▓ AUDIO SUBSYSTEM ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 75
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            
            Row {
                spacing: 8
                Text {
                    text: commsTab.muted ? "🔇" : (commsTab.volume > 50 ? "🔊" : "🔉")
                    font.pixelSize: 14
                }
                Text {
                    text: "AUDIO SUBSYSTEM"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: commsTab.muted ? Theme.contentTextDim : Theme.lambda
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: commsTab.muted ? "MUTED" : commsTab.volume + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: commsTab.muted ? Theme.blood : Theme.contentText
                }
            }
            
            Row {
                spacing: 6
                Layout.fillWidth: true
                
                // Mute button
                Rectangle {
                    width: 36
                    height: 24
                    radius: 4
                    color: commsTab.muted ? Theme.blood : Theme.displayDark
                    border.width: 1
                    border.color: commsTab.muted ? Theme.bloodBright : Theme.displayBorder
                    
                    Text {
                        anchors.centerIn: parent
                        text: commsTab.muted ? "🔇" : "🔊"
                        font.pixelSize: 12
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            commsTab.muted = !commsTab.muted
                            toggleMuteProcess.running = true
                        }
                    }
                }
                
                // Volume slider
                Rectangle {
                    width: parent.width - 46
                    height: 24
                    radius: 4
                    color: Theme.displayDark
                    border.width: 1
                    border.color: Theme.displayBorder
                    opacity: commsTab.muted ? 0.4 : 1
                    
                    Rectangle {
                        width: parent.width * (commsTab.volume / 100)
                        height: parent.height
                        radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Theme.lambdaDark }
                            GradientStop { position: 0.7; color: Theme.lambda }
                            GradientStop { position: 1.0; color: commsTab.volume > 90 ? Theme.blood : Theme.lambdaLight }
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        enabled: !commsTab.muted
                        cursorShape: !commsTab.muted ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: function(mouse) {
                            var newVal = Math.round((mouse.x / width) * 100)
                            newVal = Math.max(0, Math.min(100, newVal))
                            commsTab.volume = newVal
                            setVolumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (newVal/100).toFixed(2)]
                            setVolumeProcess.running = true
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed && !commsTab.muted) {
                                var newVal = Math.round((mouse.x / width) * 100)
                                commsTab.volume = Math.max(0, Math.min(100, newVal))
                            }
                        }
                        onReleased: {
                            if (!commsTab.muted) {
                                setVolumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (commsTab.volume/100).toFixed(2)]
                                setVolumeProcess.running = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ▓▓▓ WIFI ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            
            Text {
                text: commsTab.wifiEnabled ? "📶" : "📵"
                font.pixelSize: 16
            }
            
            Column {
                Layout.fillWidth: true
                Text {
                    text: "COMM LINK"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: commsTab.wifiEnabled ? Theme.lambda : Theme.contentTextDim
                }
                Text {
                    text: commsTab.wifiEnabled ? commsTab.wifiNetwork : "DISABLED"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.contentText
                    elide: Text.ElideRight
                    width: 120
                }
            }
            
            Rectangle {
                width: 50
                height: 24
                radius: 4
                color: commsTab.wifiEnabled ? Theme.lambda : Theme.displayDark
                border.width: 1
                border.color: commsTab.wifiEnabled ? Theme.lambdaGlow : Theme.displayBorder
                
                Text {
                    anchors.centerIn: parent
                    text: commsTab.wifiEnabled ? "ON" : "OFF"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    color: commsTab.wifiEnabled ? Theme.headerText : Theme.contentTextDim
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        commsTab.wifiEnabled = !commsTab.wifiEnabled
                        toggleWifiProcess.command = ["nmcli", "radio", "wifi", commsTab.wifiEnabled ? "on" : "off"]
                        toggleWifiProcess.running = true
                    }
                }
            }
        }
    }
    
    // ▓▓▓ BLUETOOTH ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
            
            Text {
                text: "ᛒ"  // Bluetooth rune
                font.pixelSize: 18
                font.bold: true
                color: commsTab.bluetoothEnabled ? "#3b82f6" : Theme.contentTextDim
            }
            
            Column {
                Layout.fillWidth: true
                Text {
                    text: "SHORT RANGE COMM"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: commsTab.bluetoothEnabled ? Theme.lambda : Theme.contentTextDim
                }
                Text {
                    text: commsTab.bluetoothEnabled ? commsTab.btDevice : "DISABLED"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.contentText
                    elide: Text.ElideRight
                    width: 120
                }
            }
            
            Rectangle {
                width: 50
                height: 24
                radius: 4
                color: commsTab.bluetoothEnabled ? "#3b82f6" : Theme.displayDark
                border.width: 1
                border.color: commsTab.bluetoothEnabled ? "#60a5fa" : Theme.displayBorder
                
                Text {
                    anchors.centerIn: parent
                    text: commsTab.bluetoothEnabled ? "ON" : "OFF"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    font.bold: true
                    color: commsTab.bluetoothEnabled ? "#ffffff" : Theme.contentTextDim
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        commsTab.bluetoothEnabled = !commsTab.bluetoothEnabled
                        toggleBtProcess.command = ["bluetoothctl", "power", commsTab.bluetoothEnabled ? "on" : "off"]
                        toggleBtProcess.running = true
                    }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
    
    // ═══ PROCESSES ═══
    Process {
        id: getVolumeProcess
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val)) commsTab.volume = val
            }
        }
    }
    
    Process {
        id: setVolumeProcess
        running: false
    }
    
    Process {
        id: toggleMuteProcess
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        running: false
    }
    
    Process {
        id: getWifiProcess
        command: ["sh", "-c", "nmcli -t -f WIFI g 2>/dev/null | grep -q enabled && echo 'on' || echo 'off'"]
        stdout: SplitParser {
            onRead: data => {
                commsTab.wifiEnabled = (data.trim() === "on")
                if (commsTab.wifiEnabled) getWifiNameProcess.running = true
            }
        }
    }
    
    Process {
        id: getWifiNameProcess
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2"]
        stdout: SplitParser {
            onRead: data => {
                var ssid = data.trim()
                commsTab.wifiNetwork = ssid || "Not connected"
            }
        }
    }
    
    Process {
        id: toggleWifiProcess
        running: false
        onExited: {
            if (commsTab.wifiEnabled) {
                wifiRefreshTimer.start()
            }
        }
    }
    
    Timer {
        id: wifiRefreshTimer
        interval: 2000
        onTriggered: getWifiNameProcess.running = true
    }
    
    Process {
        id: getBtProcess
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 'on' || echo 'off'"]
        stdout: SplitParser {
            onRead: data => {
                commsTab.bluetoothEnabled = (data.trim() === "on")
                if (commsTab.bluetoothEnabled) getBtDeviceProcess.running = true
            }
        }
    }
    
    Process {
        id: getBtDeviceProcess
        command: ["sh", "-c", "bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d' ' -f3-"]
        stdout: SplitParser {
            onRead: data => {
                var device = data.trim()
                commsTab.btDevice = device || "No device"
            }
        }
    }
    
    Process {
        id: toggleBtProcess
        running: false
    }
    
    // Refresh on tab activation
    onIsActiveChanged: {
        if (isActive) {
            getVolumeProcess.running = true
            getWifiProcess.running = true
            getBtProcess.running = true
        }
    }
}
