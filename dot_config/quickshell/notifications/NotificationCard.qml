import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import ".."

Rectangle {
    id: card
    property var notification: null
    property bool isToast: false
    property bool isSelected: false
    property bool showSettings: false
    signal dismissed()
    signal defaultActionTriggered()

    readonly property int notifId: (notification && notification.id !== undefined) ? notification.id : 0
    readonly property string appName: (notification && notification.appName) ? notification.appName : "System"
    readonly property int urgency: (notification && notification.urgency !== undefined) ? notification.urgency : 1
    readonly property bool isCritical: urgency === 2
    readonly property bool isLow: urgency === 0
    readonly property bool isPersistent: isCritical || (notification && notification.isPersistent)
    readonly property int progress: (notification && notification.progress !== undefined) ? notification.progress : -1

    readonly property var currentRule: {
        var v = NotificationManager.rulesVersion;
        return NotificationManager.getAppRule(appName);
    }
    readonly property bool isPopupsMuted: !!(currentRule && currentRule.silent)
    readonly property bool isAppBlocked: !!(currentRule && currentRule.block)

    width: parent ? parent.width : 340
    implicitHeight: contentCol.implicitHeight + 18
    radius: 6
    color: isSelected ? "#241c16" : (isHovered ? "#1b1511" : "#130f0c")
    border.color: isCritical ? Theme.error : (isSelected ? Theme.border : (isHovered ? "#523c2d" : "#2a2018"))
    border.width: 1
    clip: true

    readonly property bool isHovered: cardMouse.containsMouse
    property int remainingMs: isLow ? 3000 : 5000

    // Auto-dismiss countdown timer for toasts (Disabled for critical / persistent alerts)
    Timer {
        id: dismissTimer
        interval: 100
        repeat: true
        running: card.isToast && !card.isPersistent && !card.isHovered && !replyInput.activeFocus && card.remainingMs > 0 && card.notification !== null
        onTriggered: {
            card.remainingMs = card.remainingMs - 100;
            if (card.remainingMs <= 0) {
                card.dismissed();
            }
        }
    }

    // Main Card MouseArea
    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                card.showSettings = !card.showSettings;
            } else {
                executeDefaultAction();
            }
        }
    }

    Column {
        id: contentCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 9
        spacing: 5

        // 1. Header Row (Icon, App Name, Settings, Time, Close Button)
        RowLayout {
            width: parent.width
            spacing: 6

            // App Icon or Contextual Glyph
            Item {
                width: 14
                height: 14
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
                    source: (card.notification && card.notification.appIcon && card.notification.appIcon.length > 0) 
                            ? card.notification.appIcon 
                            : ""
                    visible: source != ""
                }

                Text {
                    anchors.centerIn: parent
                    text: (card.notification && card.notification.glyph) ? card.notification.glyph : "󰂚"
                    color: card.isCritical ? Theme.error : Theme.border
                    font.pixelSize: 11
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    visible: !card.notification || !card.notification.appIcon || card.notification.appIcon.length === 0
                }
            }

            // App Name
            Text {
                Layout.fillWidth: true
                text: card.appName
                color: card.isCritical ? Theme.error : Theme.subtext0
                font.pixelSize: 10
                font.bold: true
                font.family: "Hack"
                elide: Text.ElideRight
            }

            // Critical Urgency Badge
            Rectangle {
                visible: card.isCritical
                height: 14
                width: critTxt.implicitWidth + 6
                radius: 2
                color: Theme.error
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: critTxt
                    anchors.centerIn: parent
                    text: "CRITICAL"
                    color: "#ffffff"
                    font.pixelSize: 8
                    font.bold: true
                    font.family: "Hack"
                }
            }

            // Timestamp
            Text {
                visible: card.notification && card.notification.time !== undefined && card.notification.time.length > 0
                text: (card.notification && card.notification.time) ? card.notification.time : ""
                color: "#6b645b"
                font.pixelSize: 9
                font.family: "Hack"
                Layout.alignment: Qt.AlignVCenter
            }

            // Per-App Settings Button (󰒓)
            Text {
                text: "󰒓"
                color: (card.showSettings || setMouse.containsMouse) ? Theme.border : "#6b645b"
                font.pixelSize: 10
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                opacity: (card.isHovered || card.showSettings || setMouse.containsMouse) ? 1.0 : 0.0
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    id: setMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        card.showSettings = !card.showSettings;
                    }
                }
            }

            // Minimal Close Button (󰅖)
            Text {
                text: "󰅖"
                color: closeMouse.containsMouse ? Theme.border : "#6b645b"
                font.pixelSize: 10
                font.family: "Hack"
                opacity: (card.isHovered || closeMouse.containsMouse) ? 1.0 : 0.4
                Layout.alignment: Qt.AlignVCenter

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Qt.callLater(() => {
                            card.dismissed();
                        });
                    }
                }
            }
        }

        // 2. Embedded Per-App Settings Panel (when toggled via 󰒓 or right click)
        Rectangle {
            id: appSettingsBox
            width: parent.width
            height: card.showSettings ? settingsCol.implicitHeight + 12 : 0
            radius: 4
            color: "#1c1612"
            border.color: Theme.border
            border.width: 1
            clip: true
            visible: card.showSettings

            Column {
                id: settingsCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 5

                Text {
                    text: card.appName + " Notification Rules"
                    color: Theme.border
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Hack"
                }

                Row {
                    spacing: 6

                    // Mute Popups toggle
                    Rectangle {
                        height: 20
                        width: muteTxt.implicitWidth + 10
                        radius: 3
                        color: card.isPopupsMuted ? Theme.border : "#2a2018"
                        border.color: "#3d2e23"
                        border.width: 1

                        Text {
                            id: muteTxt
                            anchors.centerIn: parent
                            text: card.isPopupsMuted ? "Popups: Muted" : "Popups: Active"
                            color: card.isPopupsMuted ? Theme.base : Theme.text
                            font.pixelSize: 9
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationManager.setAppRule(card.appName, { silent: !card.isPopupsMuted });
                            }
                        }
                    }

                    // Block App toggle
                    Rectangle {
                        height: 20
                        width: blockTxt.implicitWidth + 10
                        radius: 3
                        color: card.isAppBlocked ? Theme.error : "#2a2018"
                        border.color: "#3d2e23"
                        border.width: 1

                        Text {
                            id: blockTxt
                            anchors.centerIn: parent
                            text: card.isAppBlocked ? "Blocked" : "Block App"
                            color: card.isAppBlocked ? "#ffffff" : Theme.text
                            font.pixelSize: 9
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationManager.setAppRule(card.appName, { block: !card.isAppBlocked });
                            }
                        }
                    }

                    // Clear All from this app
                    Rectangle {
                        height: 20
                        width: clrAppTxt.implicitWidth + 10
                        radius: 3
                        color: "#2a2018"
                        border.color: "#3d2e23"
                        border.width: 1

                        Text {
                            id: clrAppTxt
                            anchors.centerIn: parent
                            text: "Clear All"
                            color: Theme.subtext0
                            font.pixelSize: 9
                            font.family: "Hack"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var app = card.appName;
                                if (app) {
                                    Qt.callLater(() => {
                                        NotificationManager.clearAppGroup(app);
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }

        // 3. Summary (Title) with Rich Text Markup support
        Text {
            width: parent.width
            text: (card.notification && card.notification.summary) ? card.notification.summary : ""
            textFormat: Text.StyledText
            color: Theme.text
            font.pixelSize: 12
            font.bold: true
            font.family: "Hack"
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            visible: text.length > 0
        }

        // 4. Body (Message) with Rich Text Markup support
        Text {
            width: parent.width
            text: (card.notification && card.notification.body) ? card.notification.body : ""
            textFormat: Text.StyledText
            color: "#a49d93"
            font.pixelSize: 11
            font.family: "Hack"
            wrapMode: Text.Wrap
            maximumLineCount: 4
            elide: Text.ElideRight
            visible: text.length > 0
        }

        // 5. Slim Modern Progress Bar Tracking
        Column {
            width: parent.width
            spacing: 3
            visible: card.progress >= 0

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: "#231b14"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.min(parent.width, parent.width * (Math.max(0, card.progress) / 100.0))
                    radius: 2
                    color: Theme.border
                }
            }

            Text {
                anchors.right: parent.right
                text: card.progress + "%"
                color: Theme.subtext0
                font.pixelSize: 9
                font.family: "Hack"
            }
        }

        // 6. Notification Image Preview
        Rectangle {
            id: imgContainer
            width: parent.width
            height: 100
            radius: 4
            color: "#18130f"
            border.color: "#2a2018"
            border.width: 1
            clip: true
            visible: card.notification && card.notification.image && card.notification.image.length > 0

            Image {
                anchors.fill: parent
                source: (card.notification && card.notification.image) ? card.notification.image : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
        }

        // 7. Sleek Inline Reply Box
        Rectangle {
            id: inlineReplyBox
            width: parent.width
            height: 26
            radius: 4
            color: "#1c1612"
            border.color: replyInput.activeFocus ? Theme.border : "#2e241c"
            border.width: 1
            visible: card.notification && card.notification.hasInlineReply

            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 4

                TextInput {
                    id: replyInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.pixelSize: 10
                    font.family: "Hack"
                    clip: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        text: (card.notification && card.notification.inlineReplyPlaceholder) ? card.notification.inlineReplyPlaceholder : "Reply..."
                        color: "#6b645b"
                        font.pixelSize: 10
                        font.family: "Hack"
                        visible: replyInput.text.length === 0 && !replyInput.inputMethodComposing
                    }

                    onAccepted: {
                        sendReply();
                    }
                }

                // Send Button (󰁔)
                Rectangle {
                    width: 20
                    height: 20
                    radius: 3
                    color: sendMouse.pressed ? Theme.activePressedButtonBackground : (sendMouse.containsMouse ? Theme.border : "#282019")

                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        color: (sendMouse.containsMouse || sendMouse.pressed) ? Theme.base : Theme.border
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Hack"
                    }

                    MouseArea {
                        id: sendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            sendReply();
                        }
                    }
                }
            }
        }

        // 8. Action Buttons Row (Sleek Compact Pills)
        Row {
            width: parent.width
            spacing: 5
            visible: card.notification && card.notification.actions && card.notification.actions.length > 0

            Repeater {
                model: (card.notification && card.notification.actions) ? card.notification.actions : []

                Rectangle {
                    height: 22
                    width: actionText.implicitWidth + 14
                    radius: 3
                    color: actMouse.pressed ? Theme.activePressedButtonBackground : (actMouse.containsMouse ? Theme.border : "#1e1813")
                    border.color: actMouse.containsMouse ? Theme.border : "#352920"
                    border.width: 1

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: (modelData && modelData.text) ? modelData.text : "Open"
                        color: (actMouse.containsMouse || actMouse.pressed) ? Theme.base : Theme.text
                        font.pixelSize: 10
                        font.bold: true
                        font.family: "Hack"
                    }

                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            try {
                                if (modelData && modelData.actionRef && modelData.actionRef.invoke) {
                                    modelData.actionRef.invoke();
                                }
                            } catch(e) {}
                            Qt.callLater(() => {
                                card.dismissed();
                            });
                        }
                    }
                }
            }
        }
    }

    // Toast Timer Progress Bar
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        height: 2
        color: card.isCritical ? Theme.error : Theme.border
        visible: card.isToast && !card.isPersistent
        width: Math.max(0, card.width * (card.remainingMs / (card.isLow ? 3000.0 : 5000.0)))
    }

    function executeDefaultAction() {
        if (card.showSettings) return;
        if (card.notification && card.notification.actions && card.notification.actions.length > 0) {
            try {
                var first = card.notification.actions[0];
                if (first && first.actionRef && first.actionRef.invoke) {
                    first.actionRef.invoke();
                }
            } catch(e) {}
        }
        card.defaultActionTriggered();
        card.dismissed();
    }

    function sendReply() {
        if (replyInput.text.trim().length === 0) return;
        if (card.notification && card.notification.rawNotif && card.notification.rawNotif.sendInlineReply) {
            try {
                card.notification.rawNotif.sendInlineReply(replyInput.text.trim());
            } catch(e) {}
        }
        card.dismissed();
    }
}
