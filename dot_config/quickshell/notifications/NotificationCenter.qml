import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: centerWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: NotificationManager.isCenterVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: 32
        bottom: 12
        right: 10
    }

    implicitWidth: 350
    color: "transparent"
    visible: NotificationManager.isCenterVisible

    readonly property int notifCount: (NotificationManager.historyList && NotificationManager.historyList.length) ? NotificationManager.historyList.length : 0
    property int selectedIndex: 0
    property bool showDndMenu: false

    // Keyboard Navigation Handlers
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: centerWindow.visible

        Keys.onEscapePressed: {
            NotificationManager.isCenterVisible = false;
        }

        Keys.onUpPressed: {
            if (centerWindow.notifCount > 0) {
                centerWindow.selectedIndex = Math.max(0, centerWindow.selectedIndex - 1);
            }
        }

        Keys.onDownPressed: {
            if (centerWindow.notifCount > 0) {
                centerWindow.selectedIndex = Math.min(centerWindow.notifCount - 1, centerWindow.selectedIndex + 1);
            }
        }

        Keys.onDeletePressed: {
            if (centerWindow.notifCount > 0 && centerWindow.selectedIndex < centerWindow.notifCount) {
                var item = NotificationManager.filteredHistory[centerWindow.selectedIndex];
                if (item && item.id !== undefined) {
                    NotificationManager.removeHistory(item.id);
                    if (centerWindow.selectedIndex >= centerWindow.notifCount) {
                        centerWindow.selectedIndex = Math.max(0, centerWindow.notifCount - 1);
                    }
                }
            }
        }

        Keys.onReturnPressed: {
            if (centerWindow.notifCount > 0 && centerWindow.selectedIndex < centerWindow.notifCount) {
                var it = NotificationManager.filteredHistory[centerWindow.selectedIndex];
                if (it && it.actions && it.actions.length > 0 && it.actions[0].actionRef) {
                    try { it.actions[0].actionRef.invoke(); } catch(e) {}
                }
                NotificationManager.removeHistory(it.id);
            }
        }

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Home) {
                centerWindow.selectedIndex = 0;
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                if (centerWindow.notifCount > 0) {
                    centerWindow.selectedIndex = centerWindow.notifCount - 1;
                }
                event.accepted = true;
            }
        }
    }

    // Main Drawer Card (Sleek Dark Container)
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#0f0c09"
        border.color: "#352920"
        border.width: 1
        clip: true

        ColumnLayout {
            id: contentLayout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 7

            // 1. Sleek Minimal Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Title & Icon
                Row {
                    spacing: 5
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂚"
                        color: Theme.border
                        font.pixelSize: 13
                        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Theme.text
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Hack"
                    }

                    // Minimal Count Badge
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: centerWindow.notifCount > 0 ? "(" + centerWindow.notifCount + ")" : ""
                        color: Theme.subtext0
                        font.pixelSize: 11
                        font.family: "Hack"
                    }
                }

                Item { Layout.fillWidth: true }

                // Grouped / All Compact Segmented Switcher
                Rectangle {
                    height: 22
                    width: viewToggleRow.implicitWidth + 4
                    radius: 4
                    color: "#18130f"
                    border.color: "#2e241c"
                    border.width: 1
                    visible: centerWindow.notifCount > 0

                    Row {
                        id: viewToggleRow
                        anchors.centerIn: parent
                        spacing: 2

                        Rectangle {
                            height: 18
                            width: grpTxt.implicitWidth + 6
                            radius: 3
                            color: NotificationManager.isGroupedView ? "#352920" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: grpTxt
                                anchors.centerIn: parent
                                text: "Group"
                                color: NotificationManager.isGroupedView ? Theme.text : "#736a60"
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Hack"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationManager.isGroupedView = true
                            }
                        }

                        Rectangle {
                            height: 18
                            width: allTxt.implicitWidth + 6
                            radius: 3
                            color: !NotificationManager.isGroupedView ? "#352920" : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: allTxt
                                anchors.centerIn: parent
                                text: "All"
                                color: !NotificationManager.isGroupedView ? Theme.text : "#736a60"
                                font.pixelSize: 9
                                font.bold: true
                                font.family: "Hack"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NotificationManager.isGroupedView = false
                            }
                        }
                    }
                }

                // DND Toggle Button
                Rectangle {
                    height: 22
                    width: dndRow.implicitWidth + 10
                    radius: 4
                    color: NotificationManager.dndEnabled ? Theme.border : (dndMouse.containsMouse ? "#241c16" : "#18130f")
                    border.color: NotificationManager.dndEnabled ? Theme.border : "#2e241c"
                    border.width: 1

                    Row {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰂛"
                            color: NotificationManager.dndEnabled ? Theme.base : Theme.subtext0
                            font.pixelSize: 10
                            font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: NotificationManager.dndEnabled ? (NotificationManager.dndRemainingSeconds > 0 ? Math.ceil(NotificationManager.dndRemainingSeconds / 60) + "m" : "DND") : "DND"
                            color: NotificationManager.dndEnabled ? Theme.base : Theme.text
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Hack"
                        }
                    }

                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                centerWindow.showDndMenu = !centerWindow.showDndMenu;
                            } else {
                                if (NotificationManager.dndEnabled) {
                                    NotificationManager.setDndMode(0, "Off");
                                } else {
                                    centerWindow.showDndMenu = !centerWindow.showDndMenu;
                                }
                            }
                        }
                    }
                }

                // Clear All Button (󰎟)
                Rectangle {
                    height: 22
                    width: clearRow.implicitWidth + 10
                    radius: 4
                    color: clearMouse.pressed ? Theme.activePressedButtonBackground : (clearMouse.containsMouse ? "#241c16" : "#18130f")
                    border.color: clearMouse.containsMouse ? Theme.border : "#2e241c"
                    border.width: 1
                    visible: centerWindow.notifCount > 0

                    Row {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰎟"
                            color: clearMouse.containsMouse ? Theme.border : Theme.subtext0
                            font.pixelSize: 10
                            font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clear"
                            color: clearMouse.containsMouse ? Theme.border : Theme.text
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Hack"
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationManager.clearAll();
                        }
                    }
                }

                // Close Drawer Button (󰅖)
                Text {
                    text: "󰅖"
                    color: closeDrawerMouse.containsMouse ? Theme.border : "#6b645b"
                    font.pixelSize: 12
                    font.family: "Hack"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.leftMargin: 2

                    MouseArea {
                        id: closeDrawerMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            NotificationManager.isCenterVisible = false;
                        }
                    }
                }
            }

            // 2. Timed DND Duration Selector Menu (when toggled)
            Rectangle {
                Layout.fillWidth: true
                height: centerWindow.showDndMenu ? 28 : 0
                radius: 4
                color: "#18130f"
                border.color: Theme.border
                border.width: 1
                clip: true
                visible: centerWindow.showDndMenu

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Text {
                        text: "Mute for:"
                        color: Theme.subtext0
                        font.pixelSize: 9
                        font.family: "Hack"
                    }

                    // 1 Hour
                    Rectangle {
                        height: 20
                        Layout.fillWidth: true
                        radius: 3
                        color: (NotificationManager.dndRemainingSeconds > 0 && NotificationManager.dndRemainingSeconds <= 3600) ? Theme.border : "#282019"

                        Text {
                            anchors.centerIn: parent
                            text: "1 Hour"
                            color: (NotificationManager.dndRemainingSeconds > 0 && NotificationManager.dndRemainingSeconds <= 3600) ? Theme.base : Theme.text
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationManager.setDndMode(60, "1h");
                                centerWindow.showDndMenu = false;
                            }
                        }
                    }

                    // 2 Hours
                    Rectangle {
                        height: 20
                        Layout.fillWidth: true
                        radius: 3
                        color: (NotificationManager.dndRemainingSeconds > 3600) ? Theme.border : "#282019"

                        Text {
                            anchors.centerIn: parent
                            text: "2 Hours"
                            color: (NotificationManager.dndRemainingSeconds > 3600) ? Theme.base : Theme.text
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationManager.setDndMode(120, "2h");
                                centerWindow.showDndMenu = false;
                            }
                        }
                    }

                    // Infinite
                    Rectangle {
                        height: 20
                        Layout.fillWidth: true
                        radius: 3
                        color: (NotificationManager.dndEnabled && NotificationManager.dndRemainingSeconds === 0) ? Theme.border : "#282019"

                        Text {
                            anchors.centerIn: parent
                            text: "Infinite"
                            color: (NotificationManager.dndEnabled && NotificationManager.dndRemainingSeconds === 0) ? Theme.base : Theme.text
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationManager.setDndMode(-1, "Infinite");
                                centerWindow.showDndMenu = false;
                            }
                        }
                    }

                    // Turn Off
                    Rectangle {
                        height: 20
                        width: 32
                        radius: 3
                        color: "#282019"

                        Text {
                            anchors.centerIn: parent
                            text: "Off"
                            color: Theme.error
                            font.pixelSize: 9
                            font.bold: true
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationManager.setDndMode(0, "Off");
                                centerWindow.showDndMenu = false;
                            }
                        }
                    }
                }
            }

            // 3. Active Media Player Card (Android Style at Top)
            MediaControlCard {
                Layout.fillWidth: true
            }

            // Subtle Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#28201a"
            }

            // 4. Main Notification Container (Grouped or Flat)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty State
                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: centerWindow.notifCount === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂛"
                        color: "#463d35"
                        font.pixelSize: 28
                        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No Notifications"
                        color: "#6b645b"
                        font.pixelSize: 11
                        font.family: "Hack"
                    }
                }

                // VIEW A: Grouped by App View
                ScrollView {
                    id: groupedScroll
                    anchors.fill: parent
                    clip: true
                    visible: centerWindow.notifCount > 0 && NotificationManager.isGroupedView

                    Column {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: NotificationManager.groupedHistory

                            Column {
                                width: parent.width
                                spacing: 4

                                // Minimal App Section Header
                                Item {
                                    width: parent.width
                                    height: 20

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var app = (modelData && modelData.appName) ? modelData.appName : "";
                                            if (app) {
                                                Qt.callLater(() => {
                                                    NotificationManager.toggleGroupCollapse(app);
                                                });
                                            }
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 4

                                        Text {
                                            text: (modelData && modelData.isCollapsed) ? "󰅂" : "󰅀"
                                            color: Theme.border
                                            font.pixelSize: 10
                                            font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                                        }

                                        Text {
                                            text: (modelData && modelData.appName) ? modelData.appName : "App"
                                            color: Theme.border
                                            font.pixelSize: 10
                                            font.bold: true
                                            font.family: "Hack"
                                        }

                                        Text {
                                            text: (modelData && modelData.items) ? ("(" + modelData.items.length + ")") : ""
                                            color: "#6b645b"
                                            font.pixelSize: 9
                                            font.family: "Hack"
                                            Layout.fillWidth: true
                                        }

                                        // Clear Group
                                        Text {
                                            text: "󰅖"
                                            color: grpCloseMouse.containsMouse ? Theme.border : "#524b43"
                                            font.pixelSize: 9
                                            font.family: "Hack"

                                            MouseArea {
                                                id: grpCloseMouse
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var app = (modelData && modelData.appName) ? modelData.appName : "";
                                                    if (app) {
                                                        Qt.callLater(() => {
                                                            NotificationManager.clearAppGroup(app);
                                                        });
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Group Items
                                Column {
                                    width: parent.width
                                    spacing: 4
                                    visible: modelData && !modelData.isCollapsed

                                    Repeater {
                                        model: (modelData && modelData.items) ? modelData.items : []

                                        NotificationCard {
                                            width: parent.width
                                            notification: modelData
                                            isToast: false
                                            isSelected: false
                                            onDismissed: {
                                                var targetId = (modelData && modelData.id !== undefined) ? modelData.id : 0;
                                                if (targetId) {
                                                    Qt.callLater(() => {
                                                        NotificationManager.removeHistory(targetId);
                                                    });
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // VIEW B: Flat All View
                ListView {
                    id: notifList
                    anchors.fill: parent
                    spacing: 5
                    clip: true
                    model: NotificationManager.historyList
                    visible: centerWindow.notifCount > 0 && !NotificationManager.isGroupedView
                    currentIndex: centerWindow.selectedIndex

                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }

                    delegate: NotificationCard {
                        width: notifList.width
                        notification: modelData
                        isToast: false
                        isSelected: index === centerWindow.selectedIndex
                        onDismissed: {
                            var targetId = (modelData && modelData.id !== undefined) ? modelData.id : 0;
                            if (targetId) {
                                Qt.callLater(() => {
                                    NotificationManager.removeHistory(targetId);
                                });
                            }
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        keyHandler.forceActiveFocus();
    }
}
