import QtQuick
import ".."
import "../notifications"

Rectangle {
    id: notifWidget

    color: Theme.base
    border.color: Theme.border
    border.width: 1
    height: 31
    width: mainRow.width + 16
    radius: 4

    readonly property int notifCount: (NotificationManager.historyList && NotificationManager.historyList.length) ? NotificationManager.historyList.length : 0
    readonly property bool hasNotifications: notifCount > 0 || NotificationManager.unreadCount > 0
    readonly property bool isDnd: NotificationManager.dndEnabled

    Row {
        id: mainRow
        anchors.centerIn: parent
        spacing: 6

        // 1. Notification Button (18x18 circle button)
        Rectangle {
            id: notifBtn
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: notifMouse.pressed 
                   ? (hasNotifications ? Theme.activePressedButtonBackground : Theme.passivePressedButtonBackground) 
                   : (hasNotifications ? Theme.activeButtonBackground : (notifMouse.containsMouse ? Theme.mantle : Theme.passiveButtonBackground))
            border.color: notifMouse.pressed 
                   ? (hasNotifications ? Theme.activePressedButtonBorder : Theme.passivePressedButtonBorder) 
                   : (hasNotifications ? Theme.activeButtonBorder : Theme.passiveButtonBorder)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: notifWidget.isDnd ? "󰂛" : (notifWidget.hasNotifications ? "󰂚" : "󰂜")
                color: notifMouse.pressed 
                       ? (notifWidget.hasNotifications ? Theme.activePressedButtonText : Theme.passivePressedButtonText) 
                       : (notifWidget.hasNotifications ? Theme.activeButtonText : Theme.passiveButtonText)
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
            }

            MouseArea {
                id: notifMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        NotificationManager.dndEnabled = !NotificationManager.dndEnabled;
                    } else {
                        NotificationManager.toggleCenter();
                    }
                }
            }

            // Tooltip
            Rectangle {
                visible: notifMouse.containsMouse
                color: Theme.base
                border.color: Theme.border
                radius: 3
                width: notifTipText.width + 10
                height: 18
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: 8
                z: 10000

                Text {
                    id: notifTipText
                    anchors.centerIn: parent
                    text: notifWidget.isDnd 
                          ? ("Notifications: " + NotificationManager.getDndStatusString() + " (Right Click: Toggle)") 
                          : (notifWidget.hasNotifications 
                             ? "Notifications: " + notifWidget.notifCount + " items (Right Click: DND)" 
                             : "No Notifications (Right Click: DND)")
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                }
            }
        }

        // 2. Notification Count Text (if count > 0)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: notifWidget.notifCount > 0
            text: notifWidget.notifCount.toString()
            color: Theme.text
            font.pixelSize: 13
            font.bold: true
            font.family: "Hack"
        }
    }
}
