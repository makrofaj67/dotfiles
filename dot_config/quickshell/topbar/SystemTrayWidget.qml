import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import ".."

Row {
    id: trayRow
    spacing: 4
    height: 31

    readonly property var itemsList: (SystemTray.items && SystemTray.items.values) ? SystemTray.items.values : []
    visible: itemsList.length > 0

    Repeater {
        model: trayRow.itemsList

        Rectangle {
            id: trayItemBox
            width: 27
            height: 27
            radius: 4
            color: trayMouse.pressed ? Theme.activePressedButtonBackground : (trayMouse.containsMouse ? "#221a14" : "#140f0c")
            border.color: trayMouse.containsMouse ? Theme.border : "#28201a"
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            readonly property var trayItem: modelData
            readonly property string iconSource: (trayItem && trayItem.icon) ? trayItem.icon : ""
            readonly property string tooltipText: {
                if (!trayItem) return "";
                if (trayItem.tooltipTitle && trayItem.tooltipTitle.length > 0) {
                    return trayItem.tooltipDescription ? (trayItem.tooltipTitle + "\n" + trayItem.tooltipDescription) : trayItem.tooltipTitle;
                }
                return trayItem.title || trayItem.id || "Tray App";
            }

            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: trayItemBox.iconSource
                visible: trayItemBox.iconSource.length > 0
            }

            Text {
                anchors.centerIn: parent
                text: (trayItem && trayItem.title && trayItem.title.length > 0) ? trayItem.title.substring(0, 1).toUpperCase() : "󰅍"
                color: trayMouse.containsMouse ? Theme.border : Theme.subtext0
                font.pixelSize: 11
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                visible: !trayItemBox.iconSource || trayItemBox.iconSource.length === 0
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: (mouse) => {
                    if (!trayItemBox.trayItem) return;
                    if (mouse.button === Qt.RightButton) {
                        trayItemBox.trayItem.secondaryActivate();
                    } else {
                        trayItemBox.trayItem.activate();
                    }
                }
            }

            // Minimal Tooltip
            ToolTip.visible: trayMouse.containsMouse && trayItemBox.tooltipText.length > 0
            ToolTip.text: trayItemBox.tooltipText
            ToolTip.delay: 300
        }
    }
}
