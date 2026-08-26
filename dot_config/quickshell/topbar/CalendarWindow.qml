import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: calendarWindow

    property bool isVisible: false

    visible: isVisible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // Click anywhere on backdrop to dismiss calendar immediately
    MouseArea {
        anchors.fill: parent
        onClicked: {
            calendarWindow.isVisible = false
        }
    }

    CalendarPopup {
        id: popup
        x: 5
        y: 5
    }

    IpcHandler {
        target: "calendar"
        function toggle() {
            calendarWindow.isVisible = !calendarWindow.isVisible
        }
        function close() {
            calendarWindow.isVisible = false
        }
    }
}
