import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../.."

Variants {
    // Multi-monitor: show on every connected screen
    model: Quickshell.screens
    
    PanelWindow {
        id: hudPanel
        required property var modelData
        screen: modelData
        
        anchors { left: true; right: true; bottom: true }
        height: 120
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        
        // No input - click through
        mask: Region { item: null }
    
        property int activeVdesk: 1
        
        // Get initial vdesk
        Process {
            id: getVdesk
            command: ["sh", "-c", "hyprctl printdesk 2>/dev/null | grep -oP 'vdesk \\K\\d+' || echo 1"]
            running: false
            stdout: SplitParser {
                onRead: data => {
                    var val = parseInt(data.trim())
                    if (!isNaN(val) && val > 0) hudPanel.activeVdesk = val
                }
            }
        }
        
        // Listen for vdesk IPC event from virtual-desktops plugin
        Connections {
            target: Hyprland
            function onRawEvent(event) {
                // Plugin sends "vdesk>>N" when switching
                if (event.name === "vdesk") {
                    var val = parseInt(event.data)
                    if (!isNaN(val) && val > 0) hudPanel.activeVdesk = val
                }
            }
        }
        
        Component.onCompleted: getVdesk.running = true
        
        // ═══════════════════════════════════════════════════════════
        // ███ LEFT SIDE - WORKSPACE + AUX POWER ███
        // ═══════════════════════════════════════════════════════════
Item {
            id: leftHud
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 30
            anchors.bottomMargin: 35
            width: 250
            height: 110
            
            property int lastVdesk: 1
            property int totalDesks: 9
            
            // ▓▓▓ FLASH EFFECT ▓▓▓
            Rectangle {
                id: flashOverlay
                anchors.fill: parent
                color: Theme.indicatorColor
                opacity: 0
                radius: 4
                
                SequentialAnimation {
                    id: flashAnim
                    NumberAnimation { target: flashOverlay; property: "opacity"; to: 0.4; duration: 60 }
                    NumberAnimation { target: flashOverlay; property: "opacity"; to: 0; duration: 250 }
                }
            }
            
            Connections {
                target: hudPanel
                function onActiveVdeskChanged() {
                    if (leftHud.lastVdesk !== hudPanel.activeVdesk) {
                        flashAnim.restart()
                        leftHud.lastVdesk = hudPanel.activeVdesk
                    }
                }
            }
            
            // ▓▓▓ MAIN LAYOUT ▓▓▓
            Column {
                anchors.fill: parent
                spacing: 0
                
                // ═══ MAIN NUMBER ROW ═══
                Row {
                    spacing: 8
                    
                    // Big number with glow
                    Item {
                        width: mainNum.width + 10
                        height: mainNum.height
                        
                        // Glow layer
                        Text {
                            anchors.centerIn: parent
                            text: hudPanel.activeVdesk
                            font.family: "Impact"
                            font.pixelSize: 82
                            font.bold: true
                            color: Theme.indicatorColor
                            opacity: 0.2
                        }
                        
                        // Shadow
                        Text {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: 3
                            anchors.verticalCenterOffset: 3
                            text: hudPanel.activeVdesk
                            font.family: "Impact"
                            font.pixelSize: 78
                            font.bold: true
                            color: "#000000"
                        }
                        
                        // Main
                        Text {
                            id: mainNum
                            anchors.centerIn: parent
                            text: hudPanel.activeVdesk
                            font.family: "Impact"
                            font.pixelSize: 78
                            font.bold: true
                            color: Theme.indicatorColor
                        }
                    }
                    
                    // Side info - SECTOR label1
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                        spacing: 2
                        
                        // Lambda icon
                        Text {
                            text: "λ"
                            font.pixelSize: 22
                            font.bold: true
                            color: Theme.indicatorColor
                            opacity: 0.5
                        }
                        
                        // SECTOR text
                        Text {
                            text: "SECTOR"
                            font.family: Theme.fontMono
                            font.pixelSize: 14
                            font.bold: true
                            font.letterSpacing: 1
                            color: Theme.indicatorColor
                            opacity: 0.9
                        }
                    }
                }
                
                // ═══ BOTTOM: SEGMENT BAR ═══
                Rectangle {
                    width: segmentRow.width + 10
                    height: 14
                        color: "#88000000"
                    radius: 2
                    border.width: 1
                    border.color: Theme.indicatorColor
                    
                    Row {
                        id: segmentRow
                        anchors.centerIn: parent
                        spacing: 3
                        
                        Repeater {
                            model: leftHud.totalDesks
                            
                            Rectangle {
                                width: 12
                                height: 8
                                radius: 1
                                
                                property bool isActive: (index + 1) === hudPanel.activeVdesk
                                property bool isPast: (index + 1) < hudPanel.activeVdesk
                                
                                gradient: Gradient {
                                    GradientStop { 
                                        position: 0.0
                                        color: isActive ? Theme.indicatorColor : (isPast ? Theme.indicatorColor : Theme.cellBackground)
                                    }
                                    GradientStop { 
                                        position: 1.0
                                        color: isActive ? Theme.indicatorColor : (isPast ? Theme.indicatorColor : Theme.background)
                                    }
                                }
                                
                                border.width: 1
                                border.color: isActive ? Theme.indicatorColor : Theme.indicatorColor
                                opacity: isActive ? 1.0 : (isPast ? 0.7 : 0.25)
                                
                                // Pulse for active
                                SequentialAnimation on opacity {
                                    running: isActive
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.7; duration: 600 }
                                    NumberAnimation { to: 1.0; duration: 600 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
