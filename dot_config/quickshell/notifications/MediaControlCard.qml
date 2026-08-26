import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import ".."

Rectangle {
    id: mediaCard

    property int selectedPlayerIndex: 0
    readonly property var playersList: (Mpris.players && Mpris.players.values) ? Mpris.players.values : []

    readonly property var activePlayer: {
        if (!playersList || playersList.length === 0) return null;
        if (selectedPlayerIndex >= 0 && selectedPlayerIndex < playersList.length) {
            return playersList[selectedPlayerIndex];
        }
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p && p.isPlaying) return p;
        }
        return playersList[0];
    }

    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property string trackAlbum: activePlayer ? (activePlayer.trackAlbum || "") : ""
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property string playerIdentity: activePlayer ? (activePlayer.identity || "Media Player") : "Media"
    readonly property bool hasMedia: activePlayer !== null && (trackTitle.length > 0 || isPlaying)

    // Position and Length in seconds
    property real trackPos: activePlayer ? activePlayer.position : 0
    readonly property real trackLen: (activePlayer && activePlayer.length > 0) ? activePlayer.length : 0

    Timer {
        interval: 1000
        repeat: true
        running: mediaCard.isPlaying
        onTriggered: {
            if (mediaCard.activePlayer) {
                mediaCard.trackPos = mediaCard.activePlayer.position;
            }
        }
    }

    function formatTime(sec) {
        if (!sec || isNaN(sec) || sec <= 0) return "0:00";
        var m = Math.floor(sec / 60);
        var s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function getAppGlyph(identity) {
        var str = (identity || "").toLowerCase();
        if (str.indexOf("spotify") !== -1) return "󰓇";
        if (str.indexOf("youtube") !== -1 || str.indexOf("music") !== -1) return "";
        if (str.indexOf("firefox") !== -1) return "󰈹";
        if (str.indexOf("chrome") !== -1 || str.indexOf("chromium") !== -1 || str.indexOf("brave") !== -1) return "󰊯";
        if (str.indexOf("mpv") !== -1 || str.indexOf("vlc") !== -1) return "󰕼";
        return "󰝚";
    }

    visible: hasMedia
    width: parent ? parent.width : 330
    implicitHeight: hasMedia ? 64 : 0
    radius: 6
    color: "#140f0c"
    border.color: "#352920"
    border.width: 1
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // 1. Album Art Thumbnail (Left)
        Rectangle {
            width: 48
            height: 48
            radius: 5
            color: "#0f0c09"
            border.color: "#28201a"
            border.width: 1
            clip: true
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source: mediaCard.artUrl
                fillMode: Image.PreserveAspectCrop
                smooth: true
                visible: mediaCard.artUrl.length > 0
            }

            Text {
                anchors.centerIn: parent
                text: mediaCard.getAppGlyph(mediaCard.playerIdentity)
                color: Theme.border
                font.pixelSize: 20
                font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                visible: mediaCard.artUrl.length === 0
            }
        }

        // 2. Center Track Metadata & Slim Progress Bar
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // App Tag & Track Title
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: mediaCard.getAppGlyph(mediaCard.playerIdentity)
                    color: Theme.border
                    font.pixelSize: 10
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: mediaCard.trackTitle.length > 0 ? mediaCard.trackTitle : "No Media"
                    color: Theme.text
                    font.pixelSize: 11
                    font.bold: true
                    font.family: "Hack"
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Artist Name
            Text {
                text: mediaCard.trackArtist.length > 0 ? mediaCard.trackArtist : mediaCard.playerIdentity
                color: Theme.subtext0
                font.pixelSize: 9
                font.family: "Hack"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // Slim Interactive Progress Bar & Time Labels
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: mediaCard.trackLen > 0

                Text {
                    text: mediaCard.formatTime(mediaCard.trackPos)
                    color: "#6b645b"
                    font.pixelSize: 8
                    font.family: "Hack"
                }

                Rectangle {
                    id: trackBar
                    Layout.fillWidth: true
                    height: 3
                    radius: 1.5
                    color: "#231b14"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.min(parent.width, parent.width * (Math.max(0, mediaCard.trackPos) / Math.max(1, mediaCard.trackLen)))
                        radius: 1.5
                        color: Theme.border
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            if (mediaCard.activePlayer && mediaCard.trackLen > 0) {
                                var ratio = mouse.x / trackBar.width;
                                var target = Math.max(0, Math.min(mediaCard.trackLen, ratio * mediaCard.trackLen));
                                mediaCard.activePlayer.position = target;
                                mediaCard.trackPos = target;
                            }
                        }
                    }
                }

                Text {
                    text: mediaCard.formatTime(mediaCard.trackLen)
                    color: "#6b645b"
                    font.pixelSize: 8
                    font.family: "Hack"
                }
            }
        }

        // 3. Playback Controls on the Right (Prev, Play/Pause, Next)
        Row {
            spacing: 5
            Layout.alignment: Qt.AlignVCenter

            // Previous Button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: prevMouse.pressed ? Theme.activePressedButtonBackground : (prevMouse.containsMouse ? "#282019" : "#1a1410")
                border.color: prevMouse.containsMouse ? Theme.border : "#352920"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰒮"
                    color: (prevMouse.containsMouse || prevMouse.pressed) ? Theme.border : Theme.subtext0
                    font.pixelSize: 10
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                }

                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaCard.activePlayer && mediaCard.activePlayer.canGoPrevious) {
                            mediaCard.activePlayer.previous();
                        }
                    }
                }
            }

            // Play / Pause Button (Prominent Amber Circle)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: playMouse.pressed ? Theme.activePressedButtonBackground : (playMouse.containsMouse ? Theme.activePressedButtonBackground : Theme.border)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: mediaCard.isPlaying ? "󰏤" : "󰐊"
                    color: Theme.base
                    font.pixelSize: 12
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaCard.activePlayer) {
                            mediaCard.activePlayer.togglePlaying();
                        }
                    }
                }
            }

            // Next Button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: nextMouse.pressed ? Theme.activePressedButtonBackground : (nextMouse.containsMouse ? "#282019" : "#1a1410")
                border.color: nextMouse.containsMouse ? Theme.border : "#352920"
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "󰒭"
                    color: (nextMouse.containsMouse || nextMouse.pressed) ? Theme.border : Theme.subtext0
                    font.pixelSize: 10
                    font.family: "Symbols Nerd Font, CaskaydiaCove Nerd Font, Hack"
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaCard.activePlayer && mediaCard.activePlayer.canGoNext) {
                            mediaCard.activePlayer.next();
                        }
                    }
                }
            }
        }
    }
}
