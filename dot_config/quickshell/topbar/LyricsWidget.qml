import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: lyricsBox

    height: 31
    radius: 4
    color: Theme.base
    border.color: Theme.border
    border.width: 1
    clip: true

    readonly property var playersList: (Mpris.players && Mpris.players.values) ? Mpris.players.values : []

    readonly property var activePlayer: {
        if (!playersList || playersList.length === 0) return null;
        for (var i = 0; i < playersList.length; i++) {
            var p = playersList[i];
            if (p && p.isPlaying) return p;
        }
        return playersList[0];
    }

    readonly property bool isPlaying: activePlayer ? activePlayer.isPlaying : false
    readonly property string trackTitle: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string trackArtist: activePlayer ? (activePlayer.trackArtist || "") : ""
    readonly property bool hasMedia: activePlayer !== null && (trackTitle.length > 0 || isPlaying)

    // Lyrics Data
    property var parsedLyrics: []
    property string currentLyricLine: ""
    property string lastFetchedKey: ""
    property bool lyricsNotFound: false
    property bool isFetching: false

    // Real-time track position (seconds)
    property real currentPos: activePlayer ? activePlayer.position : 0

    // High frequency timer for smooth synchronized lyric switching (every 250ms)
    Timer {
        interval: 250
        repeat: true
        running: lyricsBox.isPlaying
        onTriggered: {
            if (lyricsBox.activePlayer) {
                lyricsBox.currentPos = lyricsBox.activePlayer.position;
                lyricsBox.updateActiveLyric();
            }
        }
    }

    // Trigger fetch on track change
    onTrackTitleChanged: checkAndFetchLyrics()
    onTrackArtistChanged: checkAndFetchLyrics()
    onIsPlayingChanged: {
        if (isPlaying) checkAndFetchLyrics();
    }

    function checkAndFetchLyrics() {
        if (!hasMedia || trackTitle.length === 0) {
            parsedLyrics = [];
            currentLyricLine = "";
            lastFetchedKey = "";
            lyricsNotFound = false;
            return;
        }

        var key = trackArtist + " - " + trackTitle;
        if (key === lastFetchedKey && (parsedLyrics.length > 0 || lyricsNotFound)) return;
        lastFetchedKey = key;
        parsedLyrics = [];
        currentLyricLine = "";
        lyricsNotFound = false;
        isFetching = true;

        fetchProc.command = [
            "/home/rakman/.config/quickshell/topbar/get-lyrics.sh",
            trackArtist,
            trackTitle
        ];
        fetchProc.running = true;
    }

    Process {
        id: fetchProc
        stdout: SplitParser {
            onRead: data => {
                lyricsBox.isFetching = false;
                try {
                    if (data && data.trim()) {
                        var json = JSON.parse(data.trim());
                        if (json && json.syncedLyrics) {
                            lyricsBox.lyricsNotFound = false;
                            lyricsBox.parseLRC(json.syncedLyrics);
                        } else if (json && json.plainLyrics) {
                            lyricsBox.lyricsNotFound = false;
                            lyricsBox.currentLyricLine = "";
                        } else if (json && json.notFound) {
                            lyricsBox.lyricsNotFound = true;
                        }
                    }
                } catch(e) {
                    lyricsBox.lyricsNotFound = true;
                }
            }
        }
    }

    function parseLRC(lrcText) {
        var lines = lrcText.split("\n");
        var result = [];
        var regex = /^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/;
        for (var i = 0; i < lines.length; i++) {
            var match = lines[i].trim().match(regex);
            if (match) {
                var mins = parseFloat(match[1]);
                var secs = parseFloat(match[2]);
                var totalSecs = mins * 60 + secs;
                var text = match[3].trim();
                result.push({ time: totalSecs, text: text });
            }
        }
        result.sort(function(a, b) { return a.time - b.time; });
        parsedLyrics = result;
        updateActiveLyric();
    }

    function updateActiveLyric() {
        if (!parsedLyrics || parsedLyrics.length === 0) return;
        var pos = currentPos;
        var activeText = "";
        for (var i = 0; i < parsedLyrics.length; i++) {
            if (parsedLyrics[i].time <= pos) {
                activeText = parsedLyrics[i].text;
            } else {
                break;
            }
        }
        currentLyricLine = activeText;
    }

    // Dynamic Display Text
    readonly property string displayText: {
        if (!hasMedia || !isPlaying) {
            return "/ not playing";
        }
        if (isFetching) {
            return "...";
        }
        if (lyricsNotFound) {
            return "lyrics not found";
        }
        if (currentLyricLine && currentLyricLine.trim().length > 0) {
            return currentLyricLine.trim();
        }
        if (trackTitle.length > 0) {
            return (trackArtist.length > 0 ? (trackArtist + " - " + trackTitle) : trackTitle);
        }
        return "/ not playing";
    }

    // Dynamic width exactly based on current rendered text length + padding
    width: mainTxt.implicitWidth + 16

    Text {
        id: mainTxt
        anchors.centerIn: parent
        text: lyricsBox.displayText
        color: (lyricsBox.hasMedia && lyricsBox.isPlaying && !lyricsBox.lyricsNotFound) ? Theme.text : "#736a60"
        font.pixelSize: 11
        font.bold: false
        font.family: "Hack"
    }

    Component.onCompleted: {
        checkAndFetchLyrics();
    }
}
