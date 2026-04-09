import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../.."

// ╔══════════════════════════════════════════════════════════════╗
// ║  HEV MARK V - HAZARDOUS ENVIRONMENT SUIT CONTROL INTERFACE  ║
// ║  Modular Tab-based Control Panel                             ║
// ╚══════════════════════════════════════════════════════════════╝

Variants {
    // Multi-monitor: each screen gets its own independent right panel
    model: Quickshell.screens
    
    PanelWindow {
        id: rightPanel
        required property var modelData
        screen: modelData
        
        // Panel boyutları - tüm ekranı kapla
        anchors { top: true; left: true; bottom: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        
        mask: Region { item: rightPanel.isOpen ? backgroundClickArea : triggerZone }
        
        property bool isOpen: false
        property int currentTab: 0  // 0=Clock, 1=Display, 2=Comms, 3=System
        
        // Tab isimleri ve ikonları
        readonly property var tabData: [
            { icon: "⏰", name: "CLOCK" },
            { icon: "☀", name: "DISPLAY" },
            { icon: "📡", name: "COMMS" },
            { icon: "📊", name: "SYSTEM" }
        ]
        
        // Arka plan tıklama alanı
        Item {
            id: backgroundClickArea
            anchors.fill: parent
            
            MouseArea {
                anchors.fill: parent
                onClicked: rightPanel.isOpen = false
            }
        }
        
        // Tetikleyici
        Rectangle {
            id: triggerZone
            width: 280
            height: 10
            color: "transparent"
            anchors { top: parent.top; right: parent.right }
            visible: !rightPanel.isOpen
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: rightPanel.isOpen = true
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // ███ MAIN PANEL FRAME ███
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            id: outerFrame
            width: 280
            height: 450
            anchors.right: parent.right
            anchors.rightMargin: 8
            transformOrigin: Item.Top
            radius: 12
            visible: opacity > 0 || y > -height
            
            states: [
                State {
                    name: "open"; when: rightPanel.isOpen
                    PropertyChanges { target: outerFrame; y: 8; opacity: 1; scale: 1.0 }
                },
                State {
                    name: "closed"; when: !rightPanel.isOpen
                    PropertyChanges { target: outerFrame; y: -height - 20; opacity: 0; scale: 0.96 }
                }
            ]
            
            transitions: [
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                        NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutCubic }
                    }
                },
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { property: "y"; duration: 220; easing.type: Easing.InCubic }
                        NumberAnimation { property: "opacity"; duration: 150; easing.type: Easing.InQuad }
                        NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.InBack; easing.overshoot: 0.3 }
                    }
                }
            ]
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: true
            }
            
            // ▓▓▓ OUTER FRAME — minimal dark border ▓▓▓
            color: Theme.rust
            border.width: 1
            border.color: Theme.borderNormal
            
            // Top teal accent highlight
            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
                height: 1; radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Theme.lambdaDark }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                opacity: 0.5
            }
            
            // ▓▓▓ INNER DISPLAY AREA ▓▓▓
            Rectangle {
                id: innerDisplay
                anchors.fill: parent
                anchors.margins: 6
                radius: 8
                
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.displayDark }
                    GradientStop { position: 0.1; color: Theme.displayLight }
                    GradientStop { position: 0.9; color: Theme.background }
                    GradientStop { position: 1.0; color: Theme.displayDark }
                }
                
                // ═══ HEADER BAR ═══
                Rectangle {
                    id: headerBar
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    height: 40
                    radius: parent.radius
                    
                    color: Theme.headerBackground

                    // Top teal accent line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        radius: parent.radius
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Theme.lambda }
                            GradientStop { position: 0.8; color: Theme.lambda }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        opacity: 0.8
                    }
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            text: Theme.blackMesa
                            font.family: Theme.fontMono
                            font.pixelSize: 12; font.bold: true
                            font.letterSpacing: 2
                            color: Theme.headerText
                        }
                    }
                    
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Theme.lambdaDark }
                            GradientStop { position: 0.5; color: Theme.lambda }
                            GradientStop { position: 0.8; color: Theme.lambdaDark }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        opacity: 0.7
                    }
                }
                
                // ═══ TAB BAR ═══
                Rectangle {
                    id: tabBar
                    anchors { top: headerBar.bottom; left: parent.left; right: parent.right }
                    height: 32
                    color: Theme.displayDark
                    
                    Row {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        
					Repeater {
                            model: rightPanel.tabData
                            
                            Rectangle {
                                width: (tabBar.width - 14) / 4
                                height: parent.height
                                radius: 4
                                
                                property bool isActive: rightPanel.currentTab === index
                                
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: isActive ? Theme.lambdaMid : "transparent" }
                                    GradientStop { position: 1.0; color: isActive ? Theme.lambdaDark : "transparent" }
                                }
                                border.width: isActive ? 1 : 0
                                border.color: Theme.lambda
                                
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    
                                    // ════ DEĞİŞİKLİK BURADA ════
                                    Text {
                                        text: modelData.icon
                                        font.pixelSize: 10
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        
                                        // İkona renk ataması yapıyoruz:
                                        // Aktifse başlık rengi, değilse sönük renk (alttaki yazıyla aynı)
                                        color: isActive ? Theme.headerText : Theme.contentTextDim
                                    }
                                    // ═══════════════════════════

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.fontMono
                                        font.pixelSize: 7
                                        font.bold: isActive
                                        color: isActive ? Theme.headerText : Theme.contentTextDim
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: rightPanel.currentTab = index
                                }
                            }
                        }
                    }
                }
                
                // ═══ CONTENT AREA ═══
                Item {
                    id: contentArea
                    anchors {
                        top: tabBar.bottom
                        bottom: footerBar.top
                        left: parent.left
                        right: parent.right
                        margins: 8
                        topMargin: 6
                    }
                    
                    // Tab Contents with smooth transitions
                    ClockTab {
                        anchors.fill: parent
                        isActive: rightPanel.currentTab === 0 && rightPanel.isOpen
                        visible: rightPanel.currentTab === 0
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    
                    DisplayTab {
                        anchors.fill: parent
                        isActive: rightPanel.currentTab === 1 && rightPanel.isOpen
                        visible: rightPanel.currentTab === 1
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    
                    CommsTab {
                        anchors.fill: parent
                        isActive: rightPanel.currentTab === 2 && rightPanel.isOpen
                        visible: rightPanel.currentTab === 2
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    
                    SystemTab {
                        anchors.fill: parent
                        isActive: rightPanel.currentTab === 3 && rightPanel.isOpen
                        visible: rightPanel.currentTab === 3
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
                
                // ═══ FOOTER BAR ═══
                Rectangle {
                    id: footerBar
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    height: 24
                    radius: parent.radius
                    color: Theme.displayDark
                    
                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width; height: parent.radius
                        color: Theme.displayDark
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: Theme.tagline
                        font.family: Theme.fontMono
                        font.pixelSize: 7
                        font.letterSpacing: 1
                        color: Theme.textMuted
                    }
                }
            }
            
            // ▓▓▓ CORNER MARKERS ▓▓▓
            Repeater {
                model: 4
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Theme.screwBg
                    border.width: 1
                    border.color: Theme.screwBorder
                    x: (index % 2 === 0) ? 10 : parent.width - 18
                    y: (index < 2) ? 10 : parent.height - 18
                    Rectangle {
                        anchors.centerIn: parent
                        width: 3; height: 3; radius: 1.5
                        color: Theme.lambdaDark
                        opacity: 0.7
                    }
                }
            }
        }
    }
}
