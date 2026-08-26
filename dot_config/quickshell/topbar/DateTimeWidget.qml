import QtQuick
import Quickshell.Io
import ".."

Rectangle
{
    id: dateTime

    height: 31
    width: dateText.width + 16
    radius: 4

    property var dateString: null
    signal clicked()

    color: Theme.base
    border.color: Theme.border
    border.width: 1

    Text
    {
        id: dateText
        anchors.centerIn: parent
        text: dateTime.dateString || ""
        color: Theme.text
        font.pixelSize: 13
        font.family: "Hack"
        font.bold: true
    }

    MouseArea
    {
        id: dateMouse
        anchors.fill: parent
        onClicked: {
            dateTime.clicked();
        }
    }

    function updateTime() {
        var d = new Date();
        var dayOfWeek = (d.getDay() === 0) ? 7 : d.getDay();
        dateTime.dateString = "[" + dayOfWeek + "] " + Qt.formatDateTime(d, "MM/dd/yyyy hh:mm:ss");
    }

    Component.onCompleted: {
        updateTime();
    }

    Timer
    {
        running: true
        repeat: true
        interval: 1000
        onTriggered:
        {
            dateTime.updateTime();
        }
    }
}
