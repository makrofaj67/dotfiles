import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../.."
import "../shared"

// ╔══════════════════════════════════════════════════════════════╗
// ║  LAB JOURNAL - BLACK MESA RESEARCH NOTES (REVISED)           ║
// ║  Fixed Logic, Dynamic Paths, Improved UX                     ║
// ╚══════════════════════════════════════════════════════════════╝

Variants {
    // Multi-monitor: each screen gets its own independent left panel
    model: Quickshell.screens

    PanelWindow {
        id: leftPanel
        required property var modelData
        screen: modelData

        // Panel boyutları - tüm ekranı kapla (dışarı tıklamayı yakalamak için)
        anchors { top: true; left: true; bottom: true; right: true }
        color: "transparent"
        
        // Input Maskesi: Açıkken tüm ekran, kapalıyken sadece tetikleyici (trigger)
        mask: Region { item: leftPanel.isOpen ? backgroundClickArea : triggerZone }

        // Layer ayarları
        exclusionMode: ExclusionMode.Ignore
        focusable: true // Klavye girişi için gerekli

        // ═══ STATE PROPERTIES ═══
        property bool isOpen: false
        property string homeDir: Quickshell.env("HOME") || "/tmp" // Fallback
        property string configDir: homeDir + "/.config/quickshell/data/"
        
        property string lastSavedTime: ""
        property bool hasUnsavedChanges: false
        property int currentNoteIndex: 0
        property var noteFiles: ["notes.txt", "notes2.txt", "notes3.txt"]
        property var noteNames: ["NOTE 1", "NOTE 2", "NOTE 3"]
        property bool showLineNumbers: true
        property bool searchMode: false

        // Başlangıçta klasörün var olduğundan emin olunmalı (Manuel işlem gerekebilir veya mkdir eklenebilir)

        // ═══ SHORTCUTS ═══
        Shortcut {
            sequence: "Escape"
            enabled: leftPanel.isOpen
            onActivated: {
                if (leftPanel.searchMode) {
                    leftPanel.searchMode = false
                } else {
                    leftPanel.isOpen = false
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+S"
            enabled: leftPanel.isOpen
            onActivated: leftPanel.saveCurrentNote()
        }

        Shortcut {
            sequence: "Ctrl+F"
            enabled: leftPanel.isOpen
            onActivated: {
                leftPanel.searchMode = !leftPanel.searchMode
                if (leftPanel.searchMode) searchInput.forceActiveFocus()
            }
        }

        Shortcut {
            sequence: "Ctrl+L"
            enabled: leftPanel.isOpen
            onActivated: leftPanel.showLineNumbers = !leftPanel.showLineNumbers
        }
        
        // Not Değiştirme Kısayolları
        Shortcut { sequence: "Ctrl+1"; enabled: leftPanel.isOpen; onActivated: switchToNote(0) }
        Shortcut { sequence: "Ctrl+2"; enabled: leftPanel.isOpen; onActivated: switchToNote(1) }
        Shortcut { sequence: "Ctrl+3"; enabled: leftPanel.isOpen; onActivated: switchToNote(2) }

        // ═══ LOGIC FUNCTIONS ═══
        
        function getCurrentFilePath() {
            return configDir + noteFiles[currentNoteIndex]
        }

        function switchToNote(index) {
            if (index === currentNoteIndex) return
            
            // Önce mevcut olanı kaydet
            if (hasUnsavedChanges) {
                saveCurrentNote()
            }
            
            currentNoteIndex = index
            // UI'ı temizle ve yüklemeyi başlat
            noteEdit.loaded = false
            noteEdit.text = "" 
            loadNoteProcess.running = true
        }
        
        function saveCurrentNote() {
            saveNoteProcess.save(noteEdit.text)
        }

        function updateLastSavedTime() {
            var now = new Date()
            lastSavedTime = now.toTimeString().split(' ')[0]
        }

        function getWordCount(text) {
            var trimmed = text.trim()
            return trimmed.length === 0 ? 0 : trimmed.split(/\s+/).length
        }

        function getLineCount(text) {
            return text.length === 0 ? 1 : text.split('\n').length
        }

        function findAndSelect(query) {
            if (!query || query.length < 1) return
            
            // Basit arama: İmleçten sonrasını ara, yoksa başa dön
            var startIndex = noteEdit.cursorPosition
            var text = noteEdit.text
            var foundIndex = text.indexOf(query, startIndex)
            
            if (foundIndex === -1) {
                // Baştan ara
                foundIndex = text.indexOf(query, 0)
            }
            
            if (foundIndex !== -1) {
                noteEdit.cursorPosition = foundIndex
                noteEdit.select(foundIndex, foundIndex + query.length)
            }
        }

        // ═══ BACKGROUND & TRIGGER ═══
        
        // 1. Dışarı tıklama alanı (Tüm ekran)
        Rectangle {
            id: backgroundClickArea
            anchors.fill: parent
            color: "transparent"
            visible: leftPanel.isOpen
            z: -1 // Panelin arkasında
            
            MouseArea {
                anchors.fill: parent
                onClicked: leftPanel.isOpen = false
            }
        }

        // 2. Tetikleyici (Üst kenar yatay şerit - panel genişliği kadar)
        Rectangle {
            id: triggerZone
            width: 340  // Panel genişliği kadar
            height: 10
            color: "transparent" // Debug için "red" yapabilirsiniz
            anchors { top: parent.top; left: parent.left }
            visible: !leftPanel.isOpen // Sadece kapalıyken aktif olsun

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: leftPanel.isOpen = true
            }
        }

        // ═══════════════════════════════════════════════════════════
        // ███ MAIN PANEL FRAME ███
        // ═══════════════════════════════════════════════════════════
        Rectangle {
            id: outerFrame
            width: 340
            height: 480
            x: 8
            transformOrigin: Item.Top  // Üstten scale
            
            radius: 12
            visible: opacity > 0 || y > -height

            // State-based animations for different open/close effects
            states: [
                State {
                    name: "open"
                    when: leftPanel.isOpen
                    PropertyChanges { target: outerFrame; y: 8; opacity: 1; scale: 1.0 }
                },
                State {
                    name: "closed"
                    when: !leftPanel.isOpen
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
                    height: 44
                    radius: parent.radius
                    opacity: leftPanel.isOpen ? 1 : 0
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }
                    
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.headerBackground }
                        GradientStop { position: 0.5; color: Theme.headerBackground }
                        GradientStop { position: 1.0; color: Theme.headerBackground }
                    }

                    // Alt köşe düzeltmesi (Radius olmasın)
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: parent.radius
                        color: Theme.headerBackground
                    }

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
                        spacing: 10
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "LAB JOURNAL"
                                font.family: Theme.fontMono; font.bold: true
                                color: Theme.headerText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: "RESEARCH NOTES"
                                font.family: Theme.fontMono; font.pixelSize: 8
                                color: Theme.headerTextDim
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                    
                    // Bottom separator line (teal)
                    Rectangle {
                        anchors.bottom: parent.bottom; width: parent.width; height: 1
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
                    anchors { top: headerBar.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 10 }
                    anchors.topMargin: 8
                    spacing: 6

                    // ▓▓▓ TAB BAR ▓▓▓
                    Row {
                        Layout.fillWidth: true
                        spacing: 4
                        
                        Repeater {
                            model: leftPanel.noteNames
                            Rectangle {
                                width: 70; height: 22; radius: 4
                                property bool isActive: index === leftPanel.currentNoteIndex
                                color: isActive ? Theme.lambda : Theme.displayDark
                                border.width: 1
                                border.color: isActive ? Theme.lambdaLight : Theme.displayBorder
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    font.family: Theme.fontMono; font.pixelSize: 9
                                    font.bold: parent.isActive
                                    color: parent.isActive ? Theme.headerText : Theme.contentText
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: leftPanel.switchToNote(index)
                                }
                            }
                        }

                        Item { Layout.fillWidth: true } // Spacer

                        // Line Numbers Toggle
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: leftPanel.showLineNumbers ? Theme.lambda : Theme.displayDark
                            border.width: 1
                            border.color: Theme.displayBorder
                            Text { anchors.centerIn: parent; text: "#"; color: Theme.contentText }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: leftPanel.showLineNumbers = !leftPanel.showLineNumbers
                            }
                        }

                        // Copy Button
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: Theme.displayDark; border.width: 1; border.color: Theme.displayBorder
                            Text { anchors.centerIn: parent; text: "📋" }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: clipboardCopyProcess.running = true
                            }
                        }
                    }

                    // ▓▓▓ SEARCH BAR ▓▓▓
                    Rectangle {
                        Layout.fillWidth: true
                        height: leftPanel.searchMode ? 28 : 0
                        visible: height > 0
                        radius: 4
                        color: Theme.displayDark
                        border.width: 1; border.color: Theme.lambda
                        clip: true
                        
                        Behavior on height { NumberAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent; anchors.margins: 4
                            Text { text: "🔍"; font.pixelSize: 12 }
                            
                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Theme.contentText
                                font.family: Theme.fontMono
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                onAccepted: leftPanel.findAndSelect(text)
                            }
                            
                            Text {
                                text: "Go"
                                color: Theme.lambda
                                font.bold: true
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: leftPanel.findAndSelect(searchInput.text)
                                }
                            }
                        }
                    }

                    // ▓▓▓ EDITOR AREA ▓▓▓
                    Rectangle {
                        id: notepadContainer
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        
                        // Delayed fade-in for editor
                        opacity: leftPanel.isOpen ? 1 : 0
                        transform: Translate { y: leftPanel.isOpen ? 0 : 10 }
                        
                        Behavior on opacity {
                            NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                        }
                        
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.displayDark }
                            GradientStop { position: 0.5; color: Theme.displayMid }
                            GradientStop { position: 1.0; color: Theme.displayDark }
                        }
                        
                        border.width: noteEdit.activeFocus ? 2 : 1
                        border.color: noteEdit.activeFocus ? Theme.lambda : Theme.displayBorder

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4
                            
                            // Line Numbers Column (synced with Flickable)
                            Rectangle {
                                id: lineNumbersCol
                                width: leftPanel.showLineNumbers ? 32 : 0
                                height: parent.height
                                color: "transparent"
                                visible: leftPanel.showLineNumbers
                                clip: true
                                
                                Flickable {
                                    anchors.fill: parent
                                    contentY: noteFlickable.contentY
                                    interactive: false
                                    
                                    Column {
                                        width: parent.width
                                        
                                        Repeater {
                                            model: leftPanel.getLineCount(noteEdit.text)
                                            
                                            Text {
                                                width: lineNumbersCol.width
                                                height: noteEdit.font.pixelSize + 4
                                                leftPadding: 2
                                                rightPadding: 6
                                                text: (index + 1).toString()
                                                font.family: Theme.fontMono
                                                font.pixelSize: 13
                                                color: Theme.textMuted
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }
                                
                                // Separator line
                                Rectangle {
                                    anchors.right: parent.right
                                    width: 1
                                    height: parent.height
                                    color: Theme.displayBorder
                                }
                            }

                            // Text Editor
                            Flickable {
                                id: noteFlickable
                                width: parent.width - lineNumbersCol.width
                                height: parent.height
                                contentHeight: noteEdit.contentHeight + 20
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                interactive: false

                                TextEdit {
                                    id: noteEdit
                                    width: noteFlickable.width - 12
                                    x: 4
                                    color: Theme.contentText
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    activeFocusOnPress: true
                                    focus: true
                                    
                                    property bool loaded: false
                                    
                                    onTextChanged: {
                                        if (loaded) {
                                            leftPanel.hasUnsavedChanges = true
                                            saveTimer.restart()
                                        }
                                    }
                                    
                                    cursorVisible: activeFocus
                                    
                                    cursorDelegate: Rectangle {
                                        width: 2
                                        color: Theme.lambda
                                        visible: noteEdit.cursorVisible
                                        opacity: cursorBlink.opacity
                                        
                                        SequentialAnimation {
                                            id: cursorBlink
                                            property real opacity: 1
                                            running: noteEdit.cursorVisible && leftPanel.isOpen
                                            loops: Animation.Infinite
                                            NumberAnimation { target: cursorBlink; property: "opacity"; to: 0; duration: 500 }
                                            NumberAnimation { target: cursorBlink; property: "opacity"; to: 1; duration: 500 }
                                            onRunningChanged: if (!running) cursorBlink.opacity = 1
                                        }
                                    }
                                    
                                    // Placeholder
                                    Text {
                                        anchors.fill: parent
                                        text: "Notlarınızı buraya yazın...\\n\\nKısayollar:\\n• Ctrl+S - Kaydet\\n• Ctrl+F - Ara\\n• Ctrl+L - Satır numaraları\\n• Ctrl+1/2/3 - Not değiştir"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 13
                                        color: Theme.textMuted
                                        opacity: 0.5
                                        wrapMode: Text.Wrap
                                        visible: !noteEdit.text && !noteEdit.activeFocus
                                    }
                                }
                            }
                        }
                        
                        // Scroll indicator
                        Rectangle {
                            visible: noteFlickable.contentHeight > noteFlickable.height
                            anchors.right: parent.right
                            anchors.rightMargin: 2
                            y: 4 + (noteFlickable.contentY / noteFlickable.contentHeight) * (noteFlickable.height - height - 8)
                            width: 4
                            height: Math.max(30, (noteFlickable.height / noteFlickable.contentHeight) * noteFlickable.height)
                            radius: 2
                            color: Theme.lambda
                            opacity: 0.6
                        }
                        
                        // Mouse wheel scroll
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.NoButton
                            onWheel: wheel => {
                                noteFlickable.contentY = Math.max(0, Math.min(
                                    noteFlickable.contentHeight - noteFlickable.height,
                                    noteFlickable.contentY - wheel.angleDelta.y * 0.3
                                ))
                            }
                        }
                    }

                    // ▓▓▓ STATUS BAR ▓▓▓
                    Rectangle {
                        Layout.fillWidth: true; height: 22
                        color: Theme.displayDark; radius: 4
                        border.width: 1; border.color: Theme.displayBorder

                        Row {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12
                            Text { text: "CHR: " + noteEdit.text.length; font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary }
                            Text { text: "WRD: " + leftPanel.getWordCount(noteEdit.text); font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary }
                            Text { text: "LN: " + (noteEdit.text.split('\n').length); font.family: Theme.fontMono; font.pixelSize: 9; color: Theme.textSecondary }
                        }

                        Row {
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Text { 
                                id: saveIndicator
                                text: leftPanel.hasUnsavedChanges ? "◐" : "●"
                                font.pixelSize: 10
                                color: leftPanel.hasUnsavedChanges ? Theme.lambda : Theme.accent
                                opacity: saveBlinkAnim.opacity
                                
                                SequentialAnimation {
                                    id: saveBlinkAnim
                                    property real opacity: 1
                                    running: leftPanel.hasUnsavedChanges && leftPanel.isOpen
                                    loops: Animation.Infinite
                                    NumberAnimation { target: saveBlinkAnim; property: "opacity"; to: 0.3; duration: 500 }
                                    NumberAnimation { target: saveBlinkAnim; property: "opacity"; to: 1; duration: 500 }
                                    onRunningChanged: if (!running) saveBlinkAnim.opacity = 1
                                }
                            }
                            Text { text: leftPanel.lastSavedTime; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.lambda }
                        }
                    }

                    // ▓▓▓ FOOTER ▓▓▓
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Theme.tagline
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        color: Theme.textMuted
                        opacity: 0.6
                    }
                }
            }
            
            // ▓▓▓ DECORATIVE SCREWS ▓▓▓
            Repeater {
                model: 4
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Theme.screwBg; border.color: Theme.screwBorder
                    x: (index % 2 === 0) ? 10 : parent.width - 18
                    y: (index < 2) ? 10 : parent.height - 18
                    Rectangle { anchors.centerIn: parent; width: 3; height: 3; radius: 1.5; color: Theme.lambdaDark; opacity: 0.7 }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════
        // ███ PROCESSES ███
        // ═══════════════════════════════════════════════════════════

        Timer {
            id: saveTimer
            interval: 1000
            onTriggered: leftPanel.saveCurrentNote()
        }

        // Load Note
        Process {
            id: loadNoteProcess
            command: ["cat", leftPanel.getCurrentFilePath()]
            property string buffer: ""

            stdout: SplitParser {
                splitMarker: "" // Ham veri
                onRead: data => loadNoteProcess.buffer += data
            }
            
            onExited: {
                // Not bulunamazsa boş gelir, sorun yok.
                noteEdit.text = buffer
                noteEdit.loaded = true
                leftPanel.hasUnsavedChanges = false
                buffer = ""
            }
        }

        // Save Note (Safer with printf)
        Process {
            id: saveNoteProcess
            
            function save(content) {
                var target = leftPanel.getCurrentFilePath()
                // Klasörün varlığından emin ol (sadece bir kez veya her seferinde)
                // "mkdir -p" ile klasörü oluştur, sonra yaz.
                command = ["sh", "-c", "mkdir -p \"$(dirname \"$2\")\"; printf '%s' \"$1\" > \"$2\"", "sh", content, target]
                running = true
            }
            
            onExited: function(code, status) {
                if (code === 0) {
                    leftPanel.updateLastSavedTime()
                    leftPanel.hasUnsavedChanges = false
                }
            }
        }

        // Clipboard (Safer with printf)
        Process {
            id: clipboardCopyProcess
            command: ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", noteEdit.text]
        }
        
        // Başlangıçta ilk notu yükle
        Component.onCompleted: loadNoteProcess.running = true
    }
}