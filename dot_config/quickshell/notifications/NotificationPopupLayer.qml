import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: popupWindow

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: 36
        right: 16
    }

    implicitWidth: 340
    implicitHeight: Math.max(1, toastCol.implicitHeight)
    color: "transparent"
    visible: NotificationManager.popups && NotificationManager.popups.length > 0

    Column {
        id: toastCol
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 8
        width: 320

        Repeater {
            model: NotificationManager.popups

            NotificationCard {
                notification: modelData
                isToast: true
                onDismissed: {
                    if (notification && notification.id !== undefined) {
                        NotificationManager.removePopup(notification.id);
                    }
                }
            }
        }
    }
}
