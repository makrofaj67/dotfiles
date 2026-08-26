import ".."
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: topBar

    property var parsedWorkspaces: []
    property var parsedClients: []
    property var parsedMonitors: []
    property int activeWorkspaceId: 1
    property string activeWindowAddress: ""
    property bool isVisible: true
    signal calendarToggleRequested()
    signal notepadToggleRequested()

    visible: isVisible
    implicitHeight: 60
    implicitWidth: 1920
    anchors.top: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: isVisible ? 25 : 0

    // Only receive mouse input inside the topbar; pass through everything below
    mask: Region {
        item: barContent
    }

    Item {
        id: barContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32

        // Left Section: Time & Tools
        Row {
            id: leftRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 5
            spacing: 5

            DateTimeWidget {
                id: dateTimeWidget
                onClicked: {
                    topBar.calendarToggleRequested()
                }
            }
            QuickControls {}
            ScreenCaptureWidget {}
            LyricsWidget {}
        }

        // Center Section: Workspaces
        WorkspacesWidget {
            anchors.centerIn: parent
            parsedWorkspaces: topBar.parsedWorkspaces
            parsedClients: topBar.parsedClients
            parsedMonitors: topBar.parsedMonitors
            activeWorkspaceId: topBar.activeWorkspaceId
            activeWindowAddress: topBar.activeWindowAddress
        }

        // Right Section: Power, Connectivity, Display, Tray, Notes & Session
        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 5
            spacing: 5

            SystemTrayWidget {}
            NotepadWidget {
                onToggleRequested: {
                    topBar.notepadToggleRequested()
                }
            }
            NotificationWidget {}
            BatteryWidget {}
            ConnectivityWidget {}
            BrightnessSlider {}
        //   SessionWidget {}
        }
    }

    IpcHandler {
        target: "topBar"
        function toggleVisibility() {
            topBar.isVisible = !topBar.isVisible
        }
    }
}
