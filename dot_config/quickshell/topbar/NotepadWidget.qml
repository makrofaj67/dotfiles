import QtQuick
import QtQuick.Controls
import ".."

Rectangle {
    id: noteBtn
    width: 31
    height: 31
    radius: 4
    color: noteMouse.pressed ? Theme.activePressedButtonBackground : (noteMouse.containsMouse ? "#221a14" : Theme.base)
    border.color: noteMouse.containsMouse ? Theme.border : "#352920"
    border.width: 1

    signal toggleRequested()

    Text {
        anchors.centerIn: parent
        text: "󰏫"
        color: (noteMouse.containsMouse || noteMouse.pressed) ? Theme.border : Theme.subtext0
        font.pixelSize: 14
        font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
    }

    MouseArea {
        id: noteMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            noteBtn.toggleRequested();
        }
    }

    ToolTip.visible: noteMouse.containsMouse
    ToolTip.text: "Scratchpad / Quick Notes"
    ToolTip.delay: 400
}
