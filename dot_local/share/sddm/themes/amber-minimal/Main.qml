import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    width: 1920
    height: 1080

    // Theme Tokens (matching Quickshell Theme.qml)
    readonly property color baseColor: "#0d0b09"
    readonly property color borderColor: "#ff9a2f"
    readonly property color textColor: "#f1e6d8"
    readonly property color subtextColor: "#8d887f"
    readonly property color buttonBg: "#221812"
    readonly property color activeBtnBg: "#ff9a2f"
    readonly property color activeBtnText: "#221812"
    readonly property color errorColor: "#d51110"
    readonly property string fontFamily: "Hack, JetBrains Mono Nerd Font, CaskaydiaCove Nerd Font, sans-serif"

    property string currentUsername: (userModel && userModel.lastUser) ? userModel.lastUser : "rakman"
    property string errorMessage: ""

    // Deep Atmospheric Background
    Rectangle {
        anchors.fill: parent
        color: root.baseColor
    }

    // SDDM Signal Connections
    Connections {
        target: sddm
        function onLoginFailed() {
            root.errorMessage = "Hatalı şifre, lütfen tekrar deneyin."
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        }
        function onLoginSucceeded() {
            root.errorMessage = ""
        }
        function onInformationMessage(message) {
            root.errorMessage = message
        }
    }

    // Realtime Clock Timer
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            timeText.text = Qt.formatTime(d, "hh:mm");
            dateText.text = Qt.formatDate(d, "dddd, d MMMM yyyy");
        }
    }

    // Main Center Container
    Column {
        anchors.centerIn: parent
        spacing: 6
        width: 320

        // 1. Digital Clock (Large & Crisp)
        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.textColor
            font.pixelSize: 72
            font.bold: true
            font.family: root.fontFamily
        }

        // 2. Date Label (Amber Accent)
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.borderColor
            font.pixelSize: 13
            font.bold: true
            font.family: root.fontFamily
        }

        Item { width: 1; height: 28 } // Spacing

        // 3. User Badge Pill
        Rectangle {
            id: userBadge
            anchors.horizontalCenter: parent.horizontalCenter
            width: userRow.width + 20
            height: 28
            radius: 14
            color: root.buttonBg
            border.color: root.borderColor
            border.width: 1

            Row {
                id: userRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌾"
                    color: root.borderColor
                    font.pixelSize: 12
                    font.family: root.fontFamily
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentUsername.length > 0 ? root.currentUsername : "rakman"
                    color: root.textColor
                    font.pixelSize: 12
                    font.bold: true
                    font.family: root.fontFamily
                }
            }
        }

        Item { width: 1; height: 12 } // Spacing

        // 4. Password Input Box
        Rectangle {
            id: inputCard
            anchors.horizontalCenter: parent.horizontalCenter
            width: 260
            height: 42
            radius: 6
            color: root.baseColor
            border.color: passwordInput.activeFocus ? root.borderColor : root.buttonBg
            border.width: 1

            TextInput {
                id: passwordInput
                anchors.left: parent.left
                anchors.right: loginActionBtn.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 6
                
                echoMode: TextInput.Password
                passwordCharacter: "•"
                color: root.textColor
                font.pixelSize: 14
                font.family: root.fontFamily
                focus: true
                clip: true

                Text {
                    visible: passwordInput.text.length === 0 && !passwordInput.inputMethodComposing
                    text: "Şifre..."
                    color: root.subtextColor
                    font.pixelSize: 12
                    font.family: root.fontFamily
                    anchors.verticalCenter: parent.verticalCenter
                }

                onAccepted: {
                    doLogin();
                }
            }

            // Submit Button inside Input Box (󰁔)
            Rectangle {
                id: loginActionBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 6
                width: 30
                height: 30
                radius: 15
                color: loginActionMouse.pressed ? root.textColor : (loginActionMouse.containsMouse ? root.activeBtnBg : root.buttonBg)
                border.color: root.borderColor
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰁔"
                    color: (loginActionMouse.containsMouse || loginActionMouse.pressed) ? root.activeBtnText : root.borderColor
                    font.pixelSize: 12
                    font.bold: true
                    font.family: root.fontFamily
                }

                MouseArea {
                    id: loginActionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }

        // 5. Error & Status Messages
        Text {
            id: errorLabel
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.errorMessage.length > 0
            text: root.errorMessage
            color: root.errorColor
            font.pixelSize: 11
            font.family: root.fontFamily
        }

        Item { width: 1; height: 10 } // Spacing

        // 6. Session Selector Pill (Hyprland default)
        Rectangle {
            id: sessionPill
            anchors.horizontalCenter: parent.horizontalCenter
            width: sessionRow.width + 16
            height: 24
            radius: 12
            color: root.baseColor
            border.color: root.buttonBg
            border.width: 1

            Row {
                id: sessionRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍹"
                    color: root.subtextColor
                    font.pixelSize: 11
                    font.family: root.fontFamily
                }

                Text {
                    id: sessionLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: sessionCombo.currentText.length > 0 ? sessionCombo.currentText : "Hyprland"
                    color: root.subtextColor
                    font.pixelSize: 11
                    font.family: root.fontFamily
                }
            }

            ComboBox {
                id: sessionCombo
                anchors.fill: parent
                opacity: 0
                model: sessionModel
                textRole: "name"
                currentIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
            }
        }
    }

    // Bottom Navigation Bar (Power & System Controls)
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 30
        spacing: 16

        // 1. Suspend Button (󰒲)
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: suspendMouse.pressed ? root.activeBtnBg : (suspendMouse.containsMouse ? root.buttonBg : root.baseColor)
            border.color: root.borderColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰒲"
                color: suspendMouse.pressed ? root.activeBtnText : (suspendMouse.containsMouse ? root.textColor : root.borderColor)
                font.pixelSize: 13
                font.family: root.fontFamily
            }

            MouseArea {
                id: suspendMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.suspend()
            }
        }

        // 2. Reboot Button (󰜉)
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: rebootMouse.pressed ? root.activeBtnBg : (rebootMouse.containsMouse ? root.buttonBg : root.baseColor)
            border.color: root.borderColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰜉"
                color: rebootMouse.pressed ? root.activeBtnText : (rebootMouse.containsMouse ? root.textColor : root.borderColor)
                font.pixelSize: 13
                font.family: root.fontFamily
            }

            MouseArea {
                id: rebootMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }

        // 3. Power Off Button (󰐥)
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: powerMouse.pressed ? root.errorColor : (powerMouse.containsMouse ? root.buttonBg : root.baseColor)
            border.color: powerMouse.containsMouse ? root.errorColor : root.borderColor
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "󰐥"
                color: powerMouse.pressed ? root.textColor : (powerMouse.containsMouse ? root.errorColor : root.borderColor)
                font.pixelSize: 13
                font.family: root.fontFamily
            }

            MouseArea {
                id: powerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }
    }

    // Login function
    function doLogin() {
        root.errorMessage = "";
        var user = root.currentUsername.length > 0 ? root.currentUsername : "rakman";
        var sessionIdx = (sessionCombo.currentIndex >= 0) ? sessionCombo.currentIndex : 0;
        sddm.login(user, passwordInput.text, sessionIdx);
    }

    Component.onCompleted: {
        passwordInput.forceActiveFocus();
    }
}
