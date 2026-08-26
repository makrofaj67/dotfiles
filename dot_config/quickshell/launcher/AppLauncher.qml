import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import ".."

PanelWindow {
    id: launcherWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: LauncherManager.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: LauncherManager.isOpen

    readonly property var results: LauncherManager.filteredResults
    readonly property int resultCount: results ? results.length : 0

    // Backdrop dismissal (click outside modal closes launcher)
    MouseArea {
        anchors.fill: parent
        onClicked: LauncherManager.close()
    }

    // Centered Spotlight Container
    Rectangle {
        id: modalBox
        width: 580
        height: Math.min(480, Math.max(110, contentCol.implicitHeight + 20))
        anchors.centerIn: parent
        radius: 8
        color: "#0f0c09"
        border.color: "#352920"
        border.width: 1
        clip: true

        // Prevent clicking inside modal from closing
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            // 1. Search Header Row
            RowLayout {
                id: headerCol
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: 8

                Text {
                    text: "󰍉"
                    color: Theme.border
                    font.pixelSize: 16
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 4
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.pixelSize: 13
                    font.family: "Hack"
                    font.bold: true
                    clip: true
                    focus: launcherWindow.visible

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: "Search apps, math (25*4), cl / @ for clipboard, or commands..."
                        color: "#524b43"
                        font.pixelSize: 12
                        font.family: "Hack"
                        visible: searchInput.text.length === 0 && !searchInput.inputMethodComposing
                    }

                    onTextChanged: {
                        LauncherManager.searchQuery = text;
                        LauncherManager.selectedIndex = 0;
                    }

                    Keys.onEscapePressed: {
                        LauncherManager.close();
                    }

                    Keys.onUpPressed: {
                        if (launcherWindow.resultCount > 0) {
                            LauncherManager.selectedIndex = Math.max(0, LauncherManager.selectedIndex - 1);
                        }
                    }

                    Keys.onDownPressed: {
                        if (launcherWindow.resultCount > 0) {
                            LauncherManager.selectedIndex = Math.min(launcherWindow.resultCount - 1, LauncherManager.selectedIndex + 1);
                        }
                    }

                    Keys.onReturnPressed: {
                        if (launcherWindow.resultCount > 0 && LauncherManager.selectedIndex < launcherWindow.resultCount) {
                            LauncherManager.launchItem(launcherWindow.results[LauncherManager.selectedIndex]);
                        }
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_PageUp) {
                            LauncherManager.selectedIndex = Math.max(0, LauncherManager.selectedIndex - 5);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageDown) {
                            if (launcherWindow.resultCount > 0) {
                                LauncherManager.selectedIndex = Math.min(launcherWindow.resultCount - 1, LauncherManager.selectedIndex + 5);
                            }
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home) {
                            LauncherManager.selectedIndex = 0;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End) {
                            if (launcherWindow.resultCount > 0) {
                                LauncherManager.selectedIndex = launcherWindow.resultCount - 1;
                            }
                            event.accepted = true;
                        }
                    }
                }

                // Esc Badge / Clear
                Rectangle {
                    height: 20
                    width: escTxt.implicitWidth + 8
                    radius: 3
                    color: "#18130f"
                    border.color: "#2e241c"
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 4

                    Text {
                        id: escTxt
                        anchors.centerIn: parent
                        text: searchInput.text.length > 0 ? "CLEAR" : "ESC"
                        color: "#736a60"
                        font.pixelSize: 8
                        font.bold: true
                        font.family: "Hack"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (searchInput.text.length > 0) {
                                searchInput.text = "";
                                LauncherManager.searchQuery = "";
                            } else {
                                LauncherManager.close();
                            }
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#28201a"
            }

            // 2. Results List View Container
            Item {
                id: listContainer
                Layout.fillWidth: true
                implicitHeight: launcherWindow.resultCount === 0 ? 56 : Math.min(380, Math.max(50, resultsListView.contentHeight))
                clip: true

                ListView {
                    id: resultsListView
                    anchors.fill: parent
                    clip: true
                    spacing: 3
                    model: launcherWindow.results
                    currentIndex: LauncherManager.selectedIndex

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    // Auto-hiding smooth scrollbar (only appears when scrolling / hovered)
                    ScrollBar.vertical: ScrollBar {
                        id: vScroll
                        width: 4
                        policy: ScrollBar.AsNeeded
                        active: resultsListView.moving || resultsListView.flicking || vScroll.hovered

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

                    delegate: Rectangle {
                        id: itemCard
                        width: resultsListView.width - (vScroll.visible ? 6 : 0)
                        height: 44
                        radius: 5
                        color: isSelected ? "#241c16" : (itemMouse.containsMouse ? "#19130f" : "transparent")
                        border.color: isSelected ? Theme.border : (itemMouse.containsMouse ? "#3d2e23" : "transparent")
                        border.width: 1

                        readonly property bool isSelected: index === LauncherManager.selectedIndex

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                LauncherManager.selectedIndex = index;
                                LauncherManager.launchItem(modelData);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            // App Icon or Custom Action Glyph
                            Rectangle {
                                width: 30
                                height: 30
                                radius: 4
                                color: isSelected ? "#140f0c" : "#120e0b"
                                border.color: "#28201a"
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 3
                                    source: (modelData && modelData.icon && modelData.icon.length > 0) ? ("file://" + modelData.icon) : ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: modelData && modelData.icon && modelData.icon.length > 0
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: (modelData && modelData.iconGlyph && modelData.iconGlyph.length > 0) 
                                          ? modelData.iconGlyph 
                                          : ((modelData && modelData.glyph) ? modelData.glyph : (modelData && modelData.type === "math" ? "󰪚" : (modelData && modelData.type === "system" ? "󰐥" : "󰀻")))
                                    color: isSelected ? Theme.border : "#736a60"
                                    font.pixelSize: 14
                                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                                    visible: !modelData || !modelData.icon || modelData.icon.length === 0
                                }
                            }

                            // Title & Subtitle Column
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    text: (modelData && modelData.name) ? modelData.name : ""
                                    color: (modelData && modelData.type === "math") ? Theme.border : (isSelected ? Theme.text : "#d1cac1")
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Hack"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: (modelData && modelData.comment && modelData.comment.length > 0) 
                                          ? modelData.comment 
                                          : ((modelData && modelData.exec) ? modelData.exec : "")
                                    color: "#6b645b"
                                    font.pixelSize: 9
                                    font.family: "Hack"
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    visible: text.length > 0
                                }
                            }

                            // Type Badge Pill (App / Math / System / Web)
                            Rectangle {
                                height: 16
                                width: badgeTxt.implicitWidth + 8
                                radius: 2
                                color: isSelected ? "#352920" : "#1a1410"
                                Layout.alignment: Qt.AlignVCenter
                                Layout.rightMargin: 4

                                Text {
                                    id: badgeTxt
                                    anchors.centerIn: parent
                                    text: (modelData && modelData.type) ? modelData.type.toUpperCase() : "APP"
                                    color: isSelected ? Theme.border : "#6b645b"
                                    font.pixelSize: 8
                                    font.bold: true
                                    font.family: "Hack"
                                }
                            }
                        }
                    }
                }

                // Empty State when query finds 0 results
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: launcherWindow.resultCount === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰍉"
                        color: "#463d35"
                        font.pixelSize: 24
                        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No matching apps or commands found"
                        color: "#6b645b"
                        font.pixelSize: 11
                        font.family: "Hack"
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }
}
