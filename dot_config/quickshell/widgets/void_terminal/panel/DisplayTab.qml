import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."

// ╔══════════════════════════════════════════════════════════════╗
// ║  DISPLAY TAB - Screen Controls                                ║
// ║  hyprsunset (color temp), ddcutil (external), brightnessctl   ║
// ╚══════════════════════════════════════════════════════════════╝

ColumnLayout {
    id: displayTab
    spacing: 8
    
    required property bool isActive
    
    property int brightness: 100          // 0-100
    property int colorTemp: 6500          // 2500-6500K (6500 = neutral)
    property bool nightLightOn: false
    property int externalBrightness: 50   // DDC brightness for external monitor
    property bool hasExternalMonitor: false
    
    Component.onCompleted: {
        getBrightnessProcess.running = true
        checkExternalMonitor.running = true
    }
    
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 65
        radius: 6
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            
            Row {
                spacing: 8
                Text {
                    text: "☀"
                    font.pixelSize: 14
                    color: Theme.lambda
                }
                Text {
                    text: "DISPLAY INTENSITY"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: Theme.lambda
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: displayTab.brightness + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.contentText
                }
            }
            
            // Slider
            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 4
                color: Theme.displayDark
                border.width: 1
                border.color: Theme.displayBorder
                
                Rectangle {
                    width: parent.width * (displayTab.brightness / 100)
                    height: parent.height
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.lambdaDark }
                        GradientStop { position: 1.0; color: Theme.lambda }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: function(mouse) {
                        var newVal = Math.round((mouse.x / width) * 100)
                        newVal = Math.max(5, Math.min(100, newVal))
                        displayTab.brightness = newVal
                        setBrightnessProcess.command = ["brightnessctl", "set", newVal + "%"]
                        setBrightnessProcess.running = true
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            var newVal = Math.round((mouse.x / width) * 100)
                            newVal = Math.max(5, Math.min(100, newVal))
                            displayTab.brightness = newVal
                        }
                    }
                    onReleased: {
                        setBrightnessProcess.command = ["brightnessctl", "set", displayTab.brightness + "%"]
                        setBrightnessProcess.running = true
                    }
                }
            }
        }
    }
    // ▓▓▓ EXTERNAL MONITOR (ddcutil) ▓▓▓
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 65
        radius: 6
        visible: displayTab.hasExternalMonitor
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            
            Row {
                spacing: 8
                Text {
                    text: "🖥"
                    font.pixelSize: 14
                }
                Text {
                    text: "EXTERNAL DISPLAY"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: Theme.lambda
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: displayTab.externalBrightness + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.contentText
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 4
                color: Theme.displayDark
                border.width: 1
                border.color: Theme.displayBorder
                
                Rectangle {
                    width: parent.width * (displayTab.externalBrightness / 100)
                    height: parent.height
                    radius: parent.radius
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.rustDark }
                        GradientStop { position: 1.0; color: Theme.rust }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    property bool isDragging: false
                    onClicked: function(mouse) {
                        var newVal = Math.round((mouse.x / width) * 100)
                        newVal = Math.max(10, Math.min(100, newVal))
                        displayTab.externalBrightness = newVal
                        setDdcProcess.command = ["ddcutil", "setvcp", "10", newVal.toString()]
                        setDdcProcess.running = true
                    }
                    onPositionChanged: function(mouse) {
                        if (pressed) {
                            var newVal = Math.round((mouse.x / width) * 100)
                            displayTab.externalBrightness = Math.max(10, Math.min(100, newVal))
                        }
                    }
                    onReleased: {
                        setDdcProcess.command = ["ddcutil", "setvcp", "10", displayTab.externalBrightness.toString()]
                        setDdcProcess.running = true
                    }
                }
            }
        }
    }

    Rectangle {
        id: opticFilterCard
        Layout.fillWidth: true
        Layout.preferredHeight: 65
        radius: 6
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.displayDark }
            GradientStop { position: 1.0; color: Theme.displayMid }
        }
        border.width: 1
        border.color: Theme.displayBorder
        
        // ════ LOGIC: PROCESS MANAGEMENT ════
        
        Process {
            id: shellProcess
            // Process bittiğinde veya hata verdiğinde temizlik yapmaya gerek yok,
            // çünkü fire-and-forget mantığı kullanıyoruz.
        }

        // Başlangıçta sistemde hyprsunset açık mı diye kontrol et
        Process {
            id: checkStatusProcess
            command: ["sh", "-c", "pgrep -x hyprsunset > /dev/null && echo 'yes' || echo 'no'"]
            running: true // Component yüklendiğinde çalışsın
            stdout: SplitParser {
                onRead: data => {
                    // Eğer sistemde açıksa butonu ON yap
                    if (data.trim() === "yes") {
                        displayTab.nightLightOn = true
                    }
                }
            }
        }

        function setNightLight(active, temp) {
            // Kelvin değerinin Integer olduğundan emin ol
            var safeTemp = Math.floor(temp)

            if (active) {
                // pkill'den sonra 0.1sn bekle ki sistem process'i temizleyebilsin
                var cmd = "pkill hyprsunset; sleep 0.1; hyprsunset -t " + safeTemp + " > /dev/null 2>&1 &"
                shellProcess.command = ["sh", "-c", cmd]
                shellProcess.running = true
            } else {
                shellProcess.command = ["sh", "-c", "pkill hyprsunset"]
                shellProcess.running = true
            }
        }

        // Slider sürüklenirken anlık komut göndermeyi engellemek için Timer
        Timer {
            id: sunsetDebounce
            interval: 250 // 250ms gecikme idealdir
            running: false
            onTriggered: {
                if (displayTab.nightLightOn) {
                    opticFilterCard.setNightLight(true, displayTab.colorTemp)
                }
            }
        }
        
        // ════ UI COMPONENTS ════

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4
            
            // Header Row
            Row {
                spacing: 8
                Text {
                    text: displayTab.nightLightOn ? "🌙" : "🌞"
                    font.pixelSize: 14
                }
                Text {
                    text: "OPTIC FILTER"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    font.bold: true
                    color: displayTab.nightLightOn ? Theme.lambda : Theme.contentTextDim
                }
                Item { width: 1; height: 1; Layout.fillWidth: true }
                Text {
                    text: displayTab.colorTemp + "K"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.contentText
                }
            }
            
            // Controls Row
            Row {
                spacing: 6
                Layout.fillWidth: true
                
                // Toggle button
                Rectangle {
                    width: 50
                    height: 20
                    radius: 4
                    color: displayTab.nightLightOn ? Theme.lambda : Theme.displayDark
                    border.width: 1
                    border.color: displayTab.nightLightOn ? Theme.lambdaGlow : Theme.displayBorder
                    
                    Text {
                        anchors.centerIn: parent
                        text: displayTab.nightLightOn ? "ON" : "OFF"
                        font.family: Theme.fontMono
                        font.pixelSize: 8
                        font.bold: true
                        color: displayTab.nightLightOn ? Theme.headerText : Theme.contentTextDim
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            displayTab.nightLightOn = !displayTab.nightLightOn
                            opticFilterCard.setNightLight(displayTab.nightLightOn, displayTab.colorTemp)
                        }
                    }
                }
                
                // Temperature slider container
                Rectangle {
                    id: sliderContainer
                    width: parent.width - 60
                    height: 20
                    radius: 4
                    color: Theme.displayDark
                    border.width: 1
                    border.color: Theme.displayBorder
                    opacity: displayTab.nightLightOn ? 1 : 0.4
                    
                    // Gradient bar
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 2; radius: 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#ff6b35" }  // 2500K
                            GradientStop { position: 0.5; color: "#ffd699" }  // 4500K
                            GradientStop { position: 1.0; color: "#ffffff" }  // 6500K
                        }
                        opacity: 0.6
                    }
                    
                    // Indicator Knob
                    Rectangle {
                        id: knob
                        // Slider matematik düzeltmesi
                        x: (sliderContainer.width - width) * ((displayTab.colorTemp - 2500) / 4000)
                        
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: parent.height - 4
                        radius: 2
                        color: Theme.lambda
                        border.width: 1
                        border.color: Theme.headerText
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        enabled: displayTab.nightLightOn
                        cursorShape: displayTab.nightLightOn ? Qt.PointingHandCursor : Qt.ArrowCursor
                        
                        function updateTemp(mouseX) {
                            var validX = Math.max(0, Math.min(mouseX, sliderContainer.width))
                            var ratio = validX / sliderContainer.width
                            
                            // 2500 ile 6500 arasında değer üret
                            var newTemp = 2500 + (ratio * 4000)
                            
                            // En yakın 100'lüğe yuvarla (Örn: 4235 -> 4200)
                            newTemp = Math.round(newTemp / 100) * 100
                            
                            // Sınırları kesinleştir
                            newTemp = Math.max(2500, Math.min(6500, newTemp))
                            
                            if (displayTab.colorTemp !== newTemp) {
                                displayTab.colorTemp = newTemp
                                sunsetDebounce.restart()
                            }
                        }
                        
                        onPressed: mouse => updateTemp(mouse.x)
                        onPositionChanged: mouse => updateTemp(mouse.x)
                    }
                }
            }
        }
    }

    // ... (Brightness ve DDC kartları burada kalabilir) ...

    Item { Layout.fillHeight: true }
    
    // ════ CLEAN PROCESS LIST ════
    // Eski "startSunsetProcess", "stopSunsetProcess", "updateSunsetProcess", "checkSunsetProcess"
    // GİBİ PROCESSLERİ BURADAN SİLMENİZ GEREKİYOR.
    // Sadece aşağıdakiler kalmalı:

	Process {
		id: setBrightnessProcess;
	}

	Process {
		id: setDdcProcess;
	}


    Process {
        id: getBrightnessProcess
        command: ["sh", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val)) displayTab.brightness = val
            }
        }
    }
    
    Process {
        id: checkExternalMonitor
        command: ["sh", "-c", "ddcutil detect 2>/dev/null | grep -q 'Display' && echo 'yes' || echo 'no'"]
        stdout: SplitParser {
            onRead: data => {
                displayTab.hasExternalMonitor = (data.trim() === "yes")
                if (displayTab.hasExternalMonitor) {
                    getDdcBrightness.running = true
                }
            }
        }
    }
    
    Process {
        id: getDdcBrightness
        command: ["sh", "-c", "ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\\s*\\K\\d+'"]
        stdout: SplitParser {
            onRead: data => {
                var val = parseInt(data.trim())
                if (!isNaN(val)) displayTab.externalBrightness = val
            }
        }
    }
}
