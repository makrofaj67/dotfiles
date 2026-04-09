import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../../.."

// ╔══════════════════════════════════════════════════════════════╗
// ║  CLOCK TAB - Time & Calendar Display                         ║
// ╚══════════════════════════════════════════════════════════════╝

ColumnLayout {
    id: clockTab
    spacing: 10
    
    required property bool isActive  // Tab görünür mü?
    
    // ▓▓▓ DIGITAL CLOCK DISPLAY ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 80
        radius: 6
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 0.5; color: Theme.displayMid }
            GradientStop { position: 1.0; color: Theme.displayDark }
        }
        
        border.width: 1
        border.color: Theme.displayBorder
        
        Text {
            id: clockText
            anchors.centerIn: parent
            text: Qt.formatTime(new Date(), "HH:mm")
            font.family: Theme.fontMono
            font.pixelSize: 42
            font.bold: true
            color: Theme.lambda
        }
        
        Timer {
            interval: 1000
            running: clockTab.isActive
            repeat: true
            onTriggered: clockText.text = Qt.formatTime(new Date(), "HH:mm")
        }
        Component.onCompleted: clockText.text = Qt.formatTime(new Date(), "HH:mm")
    }
    
    // ▓▓▓ CALENDAR DISPLAY ▓▓▓
    Rectangle {
        id: calendarBox
        Layout.fillWidth: true
        Layout.preferredHeight: calCol.implicitHeight + 36
        radius: 6
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        property var currentDate: new Date()
        property int currentDay: currentDate.getDate()
        property int currentMonth: currentDate.getMonth()
        property int currentYear: currentDate.getFullYear()
        property int firstDayOfMonth: (new Date(currentYear, currentMonth, 1).getDay() + 6) % 7
        property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()
        
        Column {
            id: calCol
            anchors.centerIn: parent
            spacing: 4
            
            Text {
                text: Qt.formatDate(new Date(), "MMMM yyyy")
                font.family: Theme.fontMono
                font.pixelSize: 10
                font.bold: true
                color: Theme.lambda
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Row {
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        width: 24; text: modelData
                        font.family: Theme.fontMono
                        font.pixelSize: 8; font.bold: true
                        color: index >= 5 ? Theme.blood : Theme.contentTextDim
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
            
            Grid {
                columns: 7; spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                
                Repeater {
                    model: calendarBox.firstDayOfMonth
                    Item { width: 24; height: 20 }
                }
                
                Repeater {
                    model: calendarBox.daysInMonth
                    
                    Rectangle {
                        width: 24; height: 20; radius: 3
                        property bool isToday: (index + 1) === calendarBox.currentDay
                        property bool isWeekend: ((calendarBox.firstDayOfMonth + index) % 7) >= 5
                        
                        color: isToday ? Theme.lambda : "transparent"
                        
                        Text {
                            anchors.centerIn: parent
                            text: index + 1
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            font.bold: isToday
                            color: isToday ? Theme.headerText : (isWeekend ? Theme.blood : Theme.contentText)
                        }
                    }
                }
            }
        }
        
        Timer {
            interval: 3600000
            running: clockTab.isActive
            repeat: true
            onTriggered: calendarBox.currentDate = new Date()
        }
    }
    
    // ▓▓▓ SEPARATOR ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: -4
        Layout.bottomMargin: -4
        height: 2
        radius: 1
        
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.2; color: Theme.bloodDark }
            GradientStop { position: 0.5; color: Theme.blood }
            GradientStop { position: 0.8; color: Theme.bloodDark }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    
    // ▓▓▓ CONTROL BUTTONS ▓▓▓
    GridLayout {
        columns: 2
        columnSpacing: 10
        rowSpacing: 8
        Layout.fillWidth: true
        
        // ▓▓▓ AWAKE / IDLE TOGGLE ▓▓▓
        Rectangle {
            id: awakeButton
            Layout.fillWidth: true
            height: 38
            radius: 6

            // Logic Properties
            property bool isAwake: false // True = Hypridle KAPALI (Ekran uyumaz)

            gradient: Gradient {
                GradientStop { position: 0.0; color: awakeButton.isAwake ? Theme.lambdaMid : Theme.backgroundPanel }
                GradientStop { position: 0.5; color: awakeButton.isAwake ? Theme.lambda : Theme.cellBackground }
                GradientStop { position: 1.0; color: awakeButton.isAwake ? Theme.lambdaDark : Theme.background }
            }
            border.width: 2
            border.color: awakeButton.isAwake ? Theme.lambdaGlow : Theme.borderNormal

            // Top Bevel
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 3
                height: 1; radius: parent.radius
                color: awakeButton.isAwake ? Theme.lambdaBevel : Theme.rustDark
                opacity: 0.5
            }

            Text {
                anchors.centerIn: parent
                // AWAKE aktifse "☕ UYANIK", değilse "☾ UYKU MODU"
                text: awakeButton.isAwake ? "☕ AWAKE" : "☾ IDLE ON"
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: awakeButton.isAwake ? Theme.headerText : Theme.contentTextDim
            }

            // ════ LOGIC ════
            
            // 1. Yönetici Process
            Process {
                id: idleControlProcess
                // Komutlar aşağıda dinamik atanacak
            }

            // 2. Durum Kontrolü (Başlangıçta ve değişimde)
            Process {
                id: checkIdleStatus
                // Eğer hypridle çalışıyorsa (systemctl active) -> AWAKE DEĞİLDİR.
                // Eğer hypridle çalışmıyorsa -> AWAKE'TİR.
                command: ["sh", "-c", "systemctl --user is-active hypridle -q && echo 'running' || echo 'stopped'"]
                running: true // Yüklendiğinde kontrol et
                stdout: SplitParser {
                    onRead: data => {
                        // Hypridle çalışıyorsa (running) -> Uyanık modu kapalıdır (isAwake = false)
                        // Hypridle durmuşsa (stopped) -> Uyanık modu açıktır (isAwake = true)
                        awakeButton.isAwake = (data.trim() === "stopped")
                    }
                }
            }
            
            // 3. Tıklama Mantığı
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Mantığı tersine çeviriyoruz
                    // Eğer şu an Uyanıksa -> Kapat (Hypridle Başlat)
                    // Eğer şu an Uyku Moduysa -> Uyanık Yap (Hypridle Durdur)
                    
                    if (awakeButton.isAwake) {
                        // AWAKE'i kapat -> Hypridle'ı başlat (Ekran uyuyabilsin)
                        idleControlProcess.command = ["systemctl", "--user", "start", "hypridle"]
                    } else {
                        // AWAKE'i aç -> Hypridle'ı durdur (Ekran uyumasın)
                        idleControlProcess.command = ["systemctl", "--user", "stop", "hypridle"]
                    }
                    
                    idleControlProcess.running = true
                    
                    // UI güncellenmesi için kısa bir gecikmeyle durumu tekrar kontrol et
                    checkTimer.restart()
                }
            }
            
            Timer {
                id: checkTimer
                interval: 200
                onTriggered: checkIdleStatus.running = true
            }
        }
        
        // ▓▓▓ EXIT BUTTON ▓▓▓
        Rectangle {
            id: exitBtn
            Layout.fillWidth: true
            height: 38
            radius: 6
            
            property bool hovered: exitMouse.containsMouse
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: exitBtn.hovered ? Theme.blood : Theme.backgroundPanel }
                GradientStop { position: 0.5; color: exitBtn.hovered ? Theme.bloodBright : Theme.cellBackground }
                GradientStop { position: 1.0; color: exitBtn.hovered ? Theme.bloodDark : Theme.background }
            }
            
            border.width: 2
            border.color: exitBtn.hovered ? Theme.bloodBright : Theme.borderNormal
            
            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 3
                height: 1; radius: parent.radius
                color: Theme.bloodDark; opacity: 0.4
            }
            
            Text {
                anchors.centerIn: parent
                text: "⏻ EXIT"
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.bold: true
                color: exitMouse.containsMouse ? Theme.activeText : Theme.textSecondary
            }
            
            Process {
                id: wlogoutProcess
                running: false
                // wlogout process olarak çalışınca bazen shell'i bloklar, detached (&) çalıştıralım
                command: ["sh", "-c", "wlogout -p layer-shell &"]
            }
            
            MouseArea {
                id: exitMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    // Menüyü açınca bu paneli kapatmak isteyebilirsin
                    // leftPanel.isOpen = false 
                    wlogoutProcess.running = true
                }
            }
        }
    }
}
