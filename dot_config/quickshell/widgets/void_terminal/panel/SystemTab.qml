import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."

// ╔══════════════════════════════════════════════════════════════╗
// ║  SYSTEM TAB - System Diagnostics                              ║
// ║  Battery, CPU, RAM                                            ║
// ╚══════════════════════════════════════════════════════════════╝

ColumnLayout {
    id: systemTab
    spacing: 8
    
    required property bool isActive
    
    // ═══ STATE ═══
    property int batteryPercent: 100
    property bool batteryCharging: false
    property string batteryTime: ""
    property int cpuUsage: 0
    property int ramUsage: 0
    property int ramTotal: 16  // GB
    property int ramUsed: 0    // GB
    
    Component.onCompleted: refreshAll()
    
    function refreshAll() {
        getBatteryProcess.running = true
        getCpuProcess.running = true
        getRamProcess.running = true
    }
    
    // ▓▓▓ BATTERY STATUS ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 70
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
                    text: systemTab.batteryCharging ? "⚡" : (systemTab.batteryPercent > 20 ? "🔋" : "🪫")
                    font.pixelSize: 14
                }
                Text {
                    text: "AUXILIARY POWER"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: systemTab.batteryPercent > 20 ? Theme.lambda : Theme.blood
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: systemTab.batteryPercent + "%" + (systemTab.batteryCharging ? " ⚡" : "")
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: systemTab.batteryCharging ? Theme.lambda : 
                           (systemTab.batteryPercent > 20 ? Theme.contentText : Theme.blood)
                }
            }
            
            // Battery bar
            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 4
                color: Theme.displayDark
                border.width: 1
                border.color: Theme.displayBorder
                
                Rectangle {
                    width: parent.width * (systemTab.batteryPercent / 100)
                    height: parent.height
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: systemTab.batteryPercent > 20 ? Theme.lambdaDark : Theme.bloodDark }
                        GradientStop { position: 1.0; color: systemTab.batteryPercent > 20 ? Theme.lambda : Theme.blood }
                    }
                    
                    // Charging animation
                    SequentialAnimation on opacity {
                        running: systemTab.batteryCharging
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 800 }
                        NumberAnimation { to: 1.0; duration: 800 }
                    }
                }
            }
            
            Text {
                text: systemTab.batteryTime
                font.family: Theme.fontMono
                font.pixelSize: 8
                color: Theme.contentTextDim
                visible: systemTab.batteryTime !== ""
            }
        }
    }
    
    // ▓▓▓ CPU USAGE ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 55
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
                    text: "⚙"
                    font.pixelSize: 14
                    color: Theme.rust
                }
                Text {
                    text: "PROCESSOR LOAD"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: systemTab.cpuUsage > 80 ? Theme.blood : Theme.lambda
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: systemTab.cpuUsage + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: systemTab.cpuUsage > 80 ? Theme.blood : Theme.contentText
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 16
                radius: 3
                color: Theme.displayDark
                border.width: 1
                border.color: Theme.displayBorder
                
                Rectangle {
                    width: parent.width * (systemTab.cpuUsage / 100)
                    height: parent.height
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#166534" }
                        GradientStop { position: 0.5; color: systemTab.cpuUsage > 50 ? Theme.lambda : "#22c55e" }
                        GradientStop { position: 1.0; color: systemTab.cpuUsage > 80 ? Theme.blood : Theme.lambda }
                    }
                    
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }
    }
    
    // ▓▓▓ RAM USAGE ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 55
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
                    text: "📊"
                    font.pixelSize: 14
                }
                Text {
                    text: "MEMORY BUFFER"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: systemTab.ramUsage > 80 ? Theme.blood : Theme.lambda
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: systemTab.ramUsed + " / " + systemTab.ramTotal + " GB"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.contentText
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 16
                radius: 3
                color: Theme.displayDark
                border.width: 1
                border.color: Theme.displayBorder
                
                Rectangle {
                    width: parent.width * (systemTab.ramUsage / 100)
                    height: parent.height
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#1e3a5f" }
                        GradientStop { position: 0.5; color: "#3b82f6" }
                        GradientStop { position: 1.0; color: systemTab.ramUsage > 80 ? Theme.blood : "#60a5fa" }
                    }
                    
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }
    }
    
    Item { Layout.fillHeight: true }
    
    // Refresh button
    Rectangle {
        Layout.fillWidth: true
        height: 28
        radius: 4
        color: Theme.displayDark
        border.width: 1
        border.color: Theme.displayBorder
        
        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                text: "🔄"
                font.pixelSize: 12
            }
            Text {
                text: "REFRESH DIAGNOSTICS"
                font.family: Theme.fontMono
                font.pixelSize: 9
                color: Theme.contentText
            }
        }
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: systemTab.refreshAll()
        }
    }
    
    // ═══ PROCESSES ═══
    Process {
        id: getBatteryProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val)) systemTab.batteryPercent = val
                getBatteryStatusProcess.running = true
            }
        }
    }
    
    Process {
        id: getBatteryStatusProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
        stdout: SplitParser {
            onRead: data => {
                var status = data.trim()
                systemTab.batteryCharging = (status === "Charging")
                if (status === "Discharging") {
                    getBatteryTimeProcess.running = true
                } else if (status === "Charging") {
                    systemTab.batteryTime = "Charging..."
                } else {
                    systemTab.batteryTime = ""
                }
            }
        }
    }
    
    Process {
        id: getBatteryTimeProcess
        command: ["sh", "-c", "acpi -b 2>/dev/null | grep -oP '\\d+:\\d+ remaining' || echo ''"]
        stdout: SplitParser {
            onRead: data => {
                var time = data.trim()
                systemTab.batteryTime = time ? time : ""
            }
        }
    }
    
    Process {
        id: getCpuProcess
        command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print int($2 + $4)}'"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val)) systemTab.cpuUsage = val
            }
        }
    }
    
    Process {
        id: getRamProcess
        command: ["sh", "-c", "free -g | awk '/Mem:/ {print $2, $3, int($3/$2*100)}'"]
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(' ')
                if (parts.length >= 3) {
                    systemTab.ramTotal = parseInt(parts[0]) || 16
                    systemTab.ramUsed = parseInt(parts[1]) || 0
                    systemTab.ramUsage = parseInt(parts[2]) || 0
                }
            }
        }
    }
    
    // Auto-refresh timer
    Timer {
        interval: 5000
        running: systemTab.isActive
        repeat: true
        onTriggered: {
            getCpuProcess.running = true
            getRamProcess.running = true
        }
    }
    
    // Refresh on tab activation
    onIsActiveChanged: {
        if (isActive) refreshAll()
    }
}
