import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: notepadWin

    property bool isVisible: false
    property bool isLoading: false
    property bool isSaving: false
    property string lastSavedTime: "Loaded"

    visible: isVisible
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Load content from disk
    Process {
        id: notesReader
        command: ["cat", "/home/rakman/.config/quickshell/notes"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text !== undefined) {
                    notepadWin.isLoading = true;
                    textArea.text = text;
                    notepadWin.isLoading = false;
                    notepadWin.lastSavedTime = "Loaded";
                }
            }
        }
    }

    Timer {
        id: saveDebounce
        interval: 350
        onTriggered: {
            notepadWin.saveNotes();
        }
    }

    function reloadNotes() {
        notesReader.running = false;
        notesReader.running = true;
    }

    function saveNotes() {
        if (isLoading) return;
        isSaving = true;
        var p = Qt.createQmlObject('import Quickshell.Io; Process { }', notepadWin);
        p.command = ["sh", "-c", "cat << 'EOF' > /home/rakman/.config/quickshell/notes\n" + textArea.text + "\nEOF"];
        p.running = true;
        isSaving = false;
        lastSavedTime = new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss");
    }

    function copyAll() {
        var p = Qt.createQmlObject('import Quickshell.Io; Process { }', notepadWin);
        p.command = ["sh", "-c", "echo -n '" + textArea.text.replace(/'/g, "'\\''") + "' | wl-copy"];
        p.running = true;
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        onClicked: notepadWin.isVisible = false
    }

    // Centered Floating Notepad Container
    Rectangle {
        id: modalBox
        width: 560
        height: 440
        anchors.centerIn: parent
        radius: 8
        color: "#0f0c09"
        border.color: "#352920"
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // 1. Header Bar
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 8

                Text {
                    text: "󰏫"
                    color: Theme.border
                    font.pixelSize: 16
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                }

                Text {
                    text: "Scratchpad / Quick Notes"
                    color: Theme.text
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Hack"
                }

                // Saved Status Indicator
                Text {
                    text: notepadWin.isSaving ? "Saving..." : ("Saved ✓ (" + notepadWin.lastSavedTime + ")")
                    color: "#6b645b"
                    font.pixelSize: 9
                    font.family: "Hack"
                    Layout.fillWidth: true
                }

                // Copy All Button
                Rectangle {
                    height: 22
                    width: copyTxt.implicitWidth + 12
                    radius: 3
                    color: copyMouse.pressed ? Theme.activePressedButtonBackground : (copyMouse.containsMouse ? "#28201a" : "#18130f")
                    border.color: copyMouse.containsMouse ? Theme.border : "#352920"
                    border.width: 1

                    Text {
                        id: copyTxt
                        anchors.centerIn: parent
                        text: "󰆏 Copy"
                        color: copyMouse.containsMouse ? Theme.border : Theme.subtext0
                        font.pixelSize: 9
                        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notepadWin.copyAll()
                    }
                }

                // Clear Button
                Rectangle {
                    height: 22
                    width: clrTxt.implicitWidth + 12
                    radius: 3
                    color: clrMouse.pressed ? Theme.activePressedButtonBackground : (clrMouse.containsMouse ? "#28201a" : "#18130f")
                    border.color: clrMouse.containsMouse ? Theme.border : "#352920"
                    border.width: 1

                    Text {
                        id: clrTxt
                        anchors.centerIn: parent
                        text: "󰃢 Clear"
                        color: clrMouse.containsMouse ? Theme.border : Theme.subtext0
                        font.pixelSize: 9
                        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    }

                    MouseArea {
                        id: clrMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            textArea.text = "";
                            notepadWin.saveNotes();
                        }
                    }
                }

                // Close Button
                Rectangle {
                    height: 22
                    width: 22
                    radius: 3
                    color: closeMouse.pressed ? Theme.activePressedButtonBackground : (closeMouse.containsMouse ? "#28201a" : "#18130f")
                    border.color: closeMouse.containsMouse ? Theme.border : "#352920"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        color: closeMouse.containsMouse ? Theme.border : Theme.subtext0
                        font.pixelSize: 10
                        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notepadWin.isVisible = false
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#28201a"
            }

            // 2. Editor Body (ScrollView with TextArea)
            ScrollView {
                id: editorScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.vertical: ScrollBar {
                    id: vScroll
                    width: 4
                    policy: ScrollBar.AsNeeded
                    active: editorScroll.moving || vScroll.hovered

                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: vScroll.pressed ? Theme.activePressedButtonBackground : (vScroll.hovered ? Theme.border : "#523c2d")
                        opacity: vScroll.active ? 1.0 : 0.0

                        Behavior on opacity {
                            NumberAnimation { duration: 180 }
                        }
                    }

                    background: Rectangle {
                        implicitWidth: 4
                        color: "transparent"
                    }
                }

                TextArea {
                    id: textArea
                    font.family: "Hack"
                    font.pixelSize: 11
                    color: Theme.text
                    placeholderText: "Type quick notes, TODOs, snippets, or links here...\nAuto-saved to ~/.config/quickshell/notes in real-time."
                    placeholderTextColor: "#524b43"
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    selectionColor: "#ff9a2f"
                    selectedTextColor: "#0d0b09"
                    focus: notepadWin.isVisible

                    background: Rectangle {
                        color: "transparent"
                    }

                    onTextChanged: {
                        if (!notepadWin.isLoading) {
                            saveDebounce.restart();
                        }
                    }

                    Keys.onEscapePressed: {
                        notepadWin.isVisible = false;
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#28201a"
            }

            // 3. Footer Bar (Path & Stats)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                spacing: 8

                Text {
                    text: "~/.config/quickshell/notes"
                    color: "#524b43"
                    font.pixelSize: 9
                    font.family: "Hack"
                    Layout.fillWidth: true
                }

                Text {
                    readonly property int lineCount: textArea.text.length === 0 ? 0 : textArea.text.split("\n").length
                    readonly property int wordCount: textArea.text.trim().length === 0 ? 0 : textArea.text.trim().split(/\s+/).length
                    readonly property int charCount: textArea.text.length

                    text: lineCount + " lines | " + wordCount + " words | " + charCount + " chars"
                    color: "#6b645b"
                    font.pixelSize: 9
                    font.family: "Hack"
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            reloadNotes();
            textArea.forceActiveFocus();
        } else {
            saveNotes();
        }
    }
}
