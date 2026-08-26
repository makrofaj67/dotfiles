import QtQuick
import ".."

Rectangle {
    id: calendarPopup

    property var displayedDate: new Date()
    property var today: new Date()
    property var monthNames: [
        "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
        "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"
    ]
    property var dayNames: ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]

    width: 236
    height: 208
    radius: 6
    color: Theme.base
    border.color: Theme.border
    border.width: 1

    // Subtle glow / outline
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: parent.radius + 1
        color: "transparent"
        border.color: Qt.rgba(1, 0.6, 0.2, 0.2)
        border.width: 1
        z: -1
    }

    function prevMonth() {
        var d = new Date(displayedDate.getFullYear(), displayedDate.getMonth() - 1, 1);
        displayedDate = d;
    }

    function nextMonth() {
        var d = new Date(displayedDate.getFullYear(), displayedDate.getMonth() + 1, 1);
        displayedDate = d;
    }

    function getDaysList() {
        var year = displayedDate.getFullYear();
        var month = displayedDate.getMonth();
        var now = new Date();

        var daysInMonth = new Date(year, month + 1, 0).getDate();
        var firstDay = (new Date(year, month, 1).getDay() + 6) % 7; // Monday = 0 .. Sunday = 6
        var prevMonthDays = new Date(year, month, 0).getDate();

        var list = [];
        for (var i = 0; i < 42; i++) {
            var dayNumber = 0;
            var inCurrentMonth = false;
            var col = i % 7;
            var isWeekend = (col === 5 || col === 6); // Cumartesi / Pazar

            if (i < firstDay) {
                dayNumber = prevMonthDays - firstDay + 1 + i;
                inCurrentMonth = false;
            } else if (i >= firstDay + daysInMonth) {
                dayNumber = i - (firstDay + daysInMonth) + 1;
                inCurrentMonth = false;
            } else {
                dayNumber = i - firstDay + 1;
                inCurrentMonth = true;
            }

            var isToday = (inCurrentMonth &&
                           dayNumber === now.getDate() &&
                           month === now.getMonth() &&
                           year === now.getFullYear());

            list.push({
                "day": dayNumber,
                "isCurrentMonth": inCurrentMonth,
                "isWeekend": isWeekend,
                "isToday": isToday
            });
        }
        return list;
    }

    Column {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 5

        // Top Navigation Header: <  Month Year  >
        Row {
            width: parent.width
            height: 22

            // Previous Month Button (<)
            Rectangle {
                width: 22
                height: 22
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: prevMouse.pressed ? Theme.passivePressedButtonBackground : (prevMouse.containsMouse ? Theme.passiveButtonBackground : "transparent")
                border.color: prevMouse.containsMouse ? Theme.passiveButtonBorder : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "<"
                    color: prevMouse.pressed ? Theme.passivePressedButtonText : (prevMouse.containsMouse ? Theme.text : Theme.border)
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarPopup.prevMonth()
                }
            }

            // Month & Year Text in Center
            Item {
                width: parent.width - 44
                height: 22
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    id: monthYearText
                    anchors.centerIn: parent
                    text: calendarPopup.monthNames[calendarPopup.displayedDate.getMonth()] + " " + calendarPopup.displayedDate.getFullYear()
                    color: Theme.text
                    font.pixelSize: 11
                    font.bold: true
                    font.family: Theme.fontFamily
                }
            }

            // Next Month Button (>)
            Rectangle {
                width: 22
                height: 22
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: nextMouse.pressed ? Theme.passivePressedButtonBackground : (nextMouse.containsMouse ? Theme.passiveButtonBackground : "transparent")
                border.color: nextMouse.containsMouse ? Theme.passiveButtonBorder : "transparent"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: ">"
                    color: nextMouse.pressed ? Theme.passivePressedButtonText : (nextMouse.containsMouse ? Theme.text : Theme.border)
                    font.pixelSize: 12
                    font.bold: true
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarPopup.nextMonth()
                }
            }
        }

        // Day Names Header (Pzt, Sal, Çar, Per, Cum, Cmt, Paz)
        Grid {
            columns: 7
            spacing: 2
            width: parent.width

            Repeater {
                model: calendarPopup.dayNames

                Rectangle {
                    width: (calendarPopup.width - 16 - 12) / 7
                    height: 18
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        // Cumartesi (index 5) ve Pazar (index 6) farklı renk
                        color: (index === 5 || index === 6) ? Theme.border : Theme.subtext0
                        font.pixelSize: 10
                        font.bold: (index === 5 || index === 6)
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        // Days Grid (42 cells: 6 weeks x 7 days)
        Grid {
            id: daysGrid
            columns: 7
            spacing: 2
            width: parent.width

            property var daysData: calendarPopup.getDaysList()

            Connections {
                target: calendarPopup
                function onDisplayedDateChanged() {
                    daysGrid.daysData = calendarPopup.getDaysList();
                }
            }

            Repeater {
                model: daysGrid.daysData

                Rectangle {
                    width: (calendarPopup.width - 16 - 12) / 7
                    height: 22
                    radius: 3

                    // Today highlight background
                    color: modelData.isToday ? Theme.border : "transparent"
                    border.width: 0

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        font.bold: modelData.isToday || (modelData.isCurrentMonth && modelData.isWeekend)

                        color: {
                            if (modelData.isToday) {
                                return Theme.base; // Dark text on bright border highlight
                            }
                            if (!modelData.isCurrentMonth) {
                                return Theme.subtext0;
                            }
                            if (modelData.isWeekend) {
                                return Theme.border; // Distinct accent color for Saturday / Sunday
                            }
                            return Theme.text;
                        }
                        opacity: modelData.isCurrentMonth ? 1.0 : 0.28
                    }
                }
            }
        }
    }
}
