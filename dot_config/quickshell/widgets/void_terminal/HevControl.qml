import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../.."
import "../shared"

// ╔══════════════════════════════════════════════════════════════╗
// ║  HEV MARK V - HAZARDOUS ENVIRONMENT SUIT CONTROL INTERFACE  ║
// ║  Skeuomorphic Design inspired by Black Mesa Technology      ║
// ╚══════════════════════════════════════════════════════════════╝

Variants {
    // Multi-monitor: each screen gets its own independent right panel
    model: Quickshell.screens
    
    PanelWindow {
        id: rightPanel
        required property var modelData
        screen: modelData
        
        // Panel boyutları - tüm ekranı kapla (dışarı tıklamayı yakalamak için)
        anchors { top: true; left: true; bottom: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        
        // Input Maskesi: Açıkken tüm ekran (backgroundClickArea), kapalıyken sadece tetikleyici
        mask: Region { item: rightPanel.isOpen ? backgroundClickArea : triggerZone }
        
        property bool isOpen: false
        
        // 1. Arka plan tıklama alanı (tüm ekran)
        Item {
            id: backgroundClickArea
            anchors.fill: parent
            
            MouseArea {
                anchors.fill: parent
                onClicked: rightPanel.isOpen = false
            }
        }
        
        // 2. Tetikleyici (Üst sağ köşe yatay şerit)
        Rectangle {
            id: triggerZone
            width: 280  // Panel genişliği kadar
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
        // ███ MAIN PANEL - SKEUOMORPHIC FRAME ███
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            id: outerFrame
            width: 264
            height: 404
            anchors.right: parent.right
            anchors.rightMargin: 8
            transformOrigin: Item.Top
            radius: 12
            visible: opacity > 0 || y > -height
            
            // State-based animations for different open/close effects
            states: [
                State {
                    name: "open"
                    when: rightPanel.isOpen
                    PropertyChanges { target: outerFrame; y: 8; opacity: 1; scale: 1.0 }
                },
                State {
                    name: "closed"
                    when: !rightPanel.isOpen
                    PropertyChanges { target: outerFrame; y: -height - 20; opacity: 0; scale: 0.96 }
                }
            ]
            
            transitions: [
                // Açılma animasyonu
                Transition {
                    from: "closed"; to: "open"
                    ParallelAnimation {
                        NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutBack; easing.overshoot: 0.5 }
                        NumberAnimation { property: "opacity"; duration: 180; easing.type: Easing.OutQuad }
                        NumberAnimation { property: "scale"; duration: 250; easing.type: Easing.OutCubic }
                    }
                },
                // Kapanma animasyonu
                Transition {
                    from: "open"; to: "closed"
                    ParallelAnimation {
                        NumberAnimation { property: "y"; duration: 220; easing.type: Easing.InCubic }
                        NumberAnimation { property: "opacity"; duration: 150; easing.type: Easing.InQuad }
                        NumberAnimation { property: "scale"; duration: 200; easing.type: Easing.InBack; easing.overshoot: 0.3 }
                    }
                }
            ]
            
            // Mouse tıklamalarının arkaya geçmesini engelle
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
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                height: 1
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.3; color: Theme.lambdaDark }
                    GradientStop { position: 0.7; color: Theme.lambdaDark }
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
                
                // Deep dark display background
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.displayDark }
                    GradientStop { position: 0.1; color: Theme.displayLight }
                    GradientStop { position: 0.9; color: Theme.background }
                    GradientStop { position: 1.0; color: Theme.displayDark }
                }
                
                // ═══ HEADER BAR ═══
                Rectangle {
                    id: headerBar
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 44
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
                    
                    // Header content
                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            
                            Text {
                                text: Theme.blackMesa
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                font.bold: true
                                font.letterSpacing: 2
                                color: Theme.headerText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "CONTROL"
                                font.family: Theme.fontMono
                                font.pixelSize: 8
                                font.letterSpacing: 1
                                color: Theme.headerTextDim
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                    
                    // Bottom separator line (teal)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
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
                
                // ═══ CONTENT AREA ═══
                ColumnLayout {
                    anchors.top: headerBar.bottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 12
                    anchors.topMargin: 10
                    spacing: 10
                    
                    // ▓▓▓ DIGITAL CLOCK DISPLAY ▓▓▓
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 6
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.displayDark }
                            GradientStop { position: 0.5; color: Theme.displayMid }
                            GradientStop { position: 1.0; color: Theme.displayDark }
                        }
                        
                        border.width: 1
                        border.color: Theme.displayBorder
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            
                            // Time display
                            Text {
                                id: clockText
                                text: Qt.formatTime(new Date(), "HH:mm")
                                font.family: Theme.fontMono
                                font.pixelSize: 42
                                font.bold: true
                                color: Theme.lambda
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        
                        Timer {
                            interval: 60000; running: rightPanel.isOpen; repeat: true
                            onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
                        }
                        Component.onCompleted: clockText.text = Qt.formatTime(new Date(), "HH:mm")
                    }
                    
                    // ▓▓▓ CALENDAR DISPLAY ▓▓▓
                    Rectangle {
                        id: calendarBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: calCol.implicitHeight + 16
                        radius: 6
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.displayDark }
                            GradientStop { position: 1.0; color: Theme.displayMid }
                        }
                        border.width: 1
                        border.color: Theme.displayBorder
                        
                        property var currentDate: new Date()
                        property int currentDay: currentDate.getDate()
                        property int currentMonth: currentDate.getMonth()
                        property int currentYear: currentDate.getFullYear()
                        property int firstDayOfMonth: (new Date(currentYear, currentMonth, 1).getDay() + 6) % 7
                        property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()
                        
                        Column {
                            id: calCol
                            anchors.centerIn: parent
                            spacing: 4
                            
                            Text {
                                text: Qt.formatDate(new Date(), "MMMM yyyy")
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                font.bold: true
                                color: Theme.lambda
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Row {
                                spacing: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                Repeater {
                                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                    Text {
                                        width: 24; text: modelData
                                        font.family: Theme.fontMono
                                        font.pixelSize: 8; font.bold: true
                                        color: index >= 5 ? Theme.textMuted : Theme.contentTextDim
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }
                            
                            Grid {
                                columns: 7; spacing: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                Repeater {
                                    model: calendarBox.firstDayOfMonth
                                    Item { width: 24; height: 20 }
                                }
                                
                                Repeater {
                                    model: calendarBox.daysInMonth
                                    
                                    Rectangle {
                                        width: 24; height: 20; radius: 3
                                        property bool isToday: (index + 1) === calendarBox.currentDay
                                        property bool isWeekend: ((calendarBox.firstDayOfMonth + index) % 7) >= 5
                                        
                                        color: isToday ? Theme.lambda : "transparent"
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: index + 1
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            font.bold: isToday
                                            color: isToday ? Theme.accentText : (isWeekend ? Theme.textMuted : Theme.contentText)
                                        }
                                    }
                                }
                            }
                        }
                        
                        Timer {
                            interval: 3600000; running: rightPanel.isOpen; repeat: true
                            onTriggered: calendarBox.currentDate = new Date()
                        }
                    }
                    
                    // ▓▓▓ SEPARATOR ▓▓▓
                    Separator {
                        Layout.fillWidth: true
                        fadeEdges: true
                    }
                    
                    // ▓▓▓ CONTROL BUTTONS ▓▓▓
                    GridLayout {
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 8
                        Layout.fillWidth: true
                        
                        // AWAKE Button (hypridle control) - rewritten for stability
                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 6

                            gradient: Gradient {
                                GradientStop { position: 0.0; color: idleState.isActive ? Theme.lambdaMid : Theme.backgroundPanel }
                                GradientStop { position: 0.5; color: idleState.isActive ? Theme.lambda : Theme.cellBackground }
                                GradientStop { position: 1.0; color: idleState.isActive ? Theme.lambdaDark : Theme.background }
                            }
                            border.width: 2
                            border.color: idleState.isActive ? Theme.lambdaGlow : Theme.borderNormal

                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 3
                                height: 1
                                radius: parent.radius
                                color: idleState.isActive ? Theme.lambdaBevel : Theme.rustDark
                                opacity: 0.5
                            }

                            Text {
                                anchors.centerIn: parent
                                text: idleState.isActive ? "☕ AWAKE" : "Ћ IDLE" 
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: idleState.isActive ? Theme.headerText : Theme.contentTextDim
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // record toggle time, optimistic UI flip
                                    idleState.lastToggleAt = Date.now()
                                    var intended = !idleState.isActive
                                    idleState.isActive = intended

                                    if (intended) {
                                        startIdleProcess.running = true
                                    } else {
                                        stopIdleProcess.running = true
                                    }
                                    // kick off verification quickly
                                    checkIdleDebounce.restart()
                                }
                            }

                            QtObject {
                                id: idleState
                                property bool isActive: false
                                property int lastToggleAt: 0
                                property int debounceMs: 300
                                property bool lastObserved: false
                                property int consecutiveCount: 0
                                property int requiredConsecutive: 2
                            }

                            Timer {
                                id: checkIdleDebounce
                                interval: 120
                                running: false
                                onTriggered: checkIdleProcess.running = true
                            }

                            Connections {
                                target: rightPanel
                                function onIsOpenChanged() {
                                    if (rightPanel.isOpen) checkIdleDebounce.restart()
                                }
                            }

                            // Check hypridle status; require `requiredConsecutive` stable observations
                            Process {
                                id: checkIdleProcess
                                command: ["sh", "-c", "pidof hypridle >/dev/null"]
                                running: false
                                onExited: (exitCode, status) => {
                                    var observed = (exitCode === 0)
                                    if (observed === idleState.lastObserved) {
                                        idleState.consecutiveCount += 1
                                    } else {
                                        idleState.lastObserved = observed
                                        idleState.consecutiveCount = 1
                                    }

                                    // only accept change after N consecutive observations and debounce elapsed
                                    var now = Date.now()
                                    if (idleState.consecutiveCount >= idleState.requiredConsecutive
                                            && (now - idleState.lastToggleAt) >= idleState.debounceMs) {
                                        if (idleState.isActive !== observed) idleState.isActive = observed
                                    }
                                }
                            }

                            // Start hypridle detached
                            Process {
                                id: startIdleProcess
                                command: ["sh", "-c", "setsid hypridle >/dev/null 2>&1 &"]
                                running: false
                                onExited: { /* no-op */ }
                                onRunningChanged: { if (!running) checkIdleDebounce.restart() }
                            }

                            // Stop hypridle
                            Process {
                                id: stopIdleProcess
                                command: ["sh", "-c", "pkill -x hypridle || true"]
                                running: false
                                onExited: { /* no-op */ }
                                onRunningChanged: { if (!running) checkIdleDebounce.restart() }
                            }
                        }
                        
                        // EXIT Button
                        Rectangle {
                            id: exitBtn
                            Layout.fillWidth: true
                            height: 38
                            radius: 6
                            
                            property bool hovered: exitMouse.containsMouse
                            
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: exitBtn.hovered ? Theme.blood : Theme.backgroundPanel }
                                GradientStop { position: 0.5; color: exitBtn.hovered ? Theme.bloodBright : Theme.cellBackground }
                                GradientStop { position: 1.0; color: exitBtn.hovered ? Theme.bloodDark : Theme.background }
                            }
                            
                            border.width: 2
                            border.color: exitBtn.hovered ? Theme.bloodBright : Theme.borderNormal
                            
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 3
                                height: 1
                                radius: parent.radius
                                color: Theme.bloodDark
                                opacity: 0.4
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "⏻ EXIT"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                font.bold: true
                                color: exitMouse.containsMouse ? Theme.activeText : Theme.textSecondary
                            }
                            
                            MouseArea {
                                id: exitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("exec wlogout")
                            }
                        }
                    }
                    
                    Item { Layout.fillHeight: true }
                    
                    // ▓▓▓ FOOTER ▓▓▓
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "BLACK MESA RESEARCH FACILITY"
                        font.family: Theme.fontMono
                        font.pixelSize: 7
                        font.letterSpacing: 1
                        color: Theme.rust
                    }
                }
            }
            
            // ▓▓▓ CORNER SCREWS (Decorative) ▓▓▓
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
                        width: 4; height: 1
                        color: Theme.screwSlot
                        rotation: 45
                    }
                }
            }
        }
    }
}
