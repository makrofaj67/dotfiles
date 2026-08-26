import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "notifications"
import "launcher"

ShellRoot
{
    id: shellRoot

    property var parsedClients: []
    property var parsedWorkspaces: []
    property var parsedMonitors: []
    property var parsedActiveWindow: null
    property int activeWorkspaceId: 1
    property bool isDraggin: false

    // ── Data Fetcher ──────────────────────────────────────────────

    Process
    {
        id: jsonFetcher
        command: ["sh", "-c", "jq -n -c --argjson c \"$(hyprctl clients -j)\" --argjson w \"$(hyprctl workspaces -j)\" --argjson m \"$(hyprctl monitors -j)\" --argjson a \"$(hyprctl activeworkspace -j)\" --argjson win \"$(hyprctl activewindow -j)\" '{clients: $c, workspaces: $w, monitors: $m, activeWorkspace: $a, activeWindow: $win}'"]
        running: true
        stdout: StdioCollector
        {
            onStreamFinished:
            {
                try
                {
                    if (text && text.trim() !== "")
                    {
                        var data = JSON.parse(text)
                        shellRoot.parsedClients = data.clients || []
                        shellRoot.parsedWorkspaces = data.workspaces || []
                        shellRoot.parsedMonitors = data.monitors || []
                        shellRoot.parsedActiveWindow = data.activeWindow || null
                        if (data.activeWorkspace && data.activeWorkspace.id)
                        {
                            shellRoot.activeWorkspaceId = data.activeWorkspace.id
                        }
                        else
                        {
                            var focMon = (data.monitors || []).find(function(m) { return m.focused }) || (data.monitors && data.monitors[0])
                            if (focMon && focMon.activeWorkspace)
                            {
                                shellRoot.activeWorkspaceId = focMon.activeWorkspace.id
                            }
                        }
                    }
                }
                catch(e)
                {
                    console.log("jsonFetcher JSON Parse Error:", e)
                }
            }
        }
    }

    // ── Event Listener ────────────────────────────────────────────

    Process
    {
        id: eventListener
        command: ["sh", "-c", "ncat 127.0.0.1 23456"]
        running: true
        stdout: SplitParser
        {
            splitMarker: "\n"
            onRead: function(data)
            {
                if (data && data.trim() !== "")
                {
                    fetchDebounce.restart()
                }
            }
        }
    }

    Timer
    {
        id: eventReconnectTimer
        interval: 3000
        running: !eventListener.running
        onTriggered:
        {
            eventListener.running = true
        }
    }

    Timer
    {
        id: fetchDebounce
        interval: 30
        onTriggered:
        {
            jsonFetcher.running = false
            jsonFetcher.running = true
        }
    }

    // ── UI Components ─────────────────────────────────────────────

    TopBar
    {
        id: topBar
        parsedWorkspaces: shellRoot.parsedWorkspaces
        parsedClients: shellRoot.parsedClients
        parsedMonitors: shellRoot.parsedMonitors
        activeWorkspaceId: shellRoot.activeWorkspaceId
        activeWindowAddress: (shellRoot.parsedActiveWindow && shellRoot.parsedActiveWindow.address) ? shellRoot.parsedActiveWindow.address : ""
        onCalendarToggleRequested:
        {
            calendarWindow.isVisible = !calendarWindow.isVisible
        }
        onNotepadToggleRequested:
        {
            notepadWindow.isVisible = !notepadWindow.isVisible
        }
    }

    CalendarWindow
    {
        id: calendarWindow
    }

    NotepadWindow
    {
        id: notepadWindow
    }

    WindowSwitcher
    {
        id: windowSwitcherPanel
        parsedWorkspaces: shellRoot.parsedWorkspaces
        parsedClients: shellRoot.parsedClients
        parsedMonitors: shellRoot.parsedMonitors
        activeWorkspaceId: shellRoot.activeWorkspaceId
        activeWindowAddress: (shellRoot.parsedActiveWindow && shellRoot.parsedActiveWindow.address) ? shellRoot.parsedActiveWindow.address : ""
        onPollRequested:
        {
            if (!jsonFetcher.running)
                jsonFetcher.running = true
        }
        onFetchRequested: fetchDebounce.restart()
        onDragStateChanged: function(dragging)
        {
            shellRoot.isDraggin = dragging
        }
    }

    NotificationPopupLayer
    {
        id: notificationPopupLayer
    }

    NotificationCenter
    {
        id: notificationCenter
    }

    AppLauncher
    {
        id: appLauncher
    }

    IpcHandler
    {
        target: "notifications"
        function toggle()
        {
            NotificationManager.toggleCenter()
        }
    }

    IpcHandler
    {
        target: "launcher"
        function toggle()
        {
            LauncherManager.toggle()
        }
        function open()
        {
            LauncherManager.open()
        }
        function close()
        {
            LauncherManager.close()
        }
    }

    IpcHandler
    {
        target: "notepad"
        function toggle()
        {
            notepadWindow.isVisible = !notepadWindow.isVisible
        }
        function open()
        {
            notepadWindow.isVisible = true
        }
        function close()
        {
            notepadWindow.isVisible = false
        }
    }

    // ── 1. TOP-LEFT DEBUG OSD OVERLAY PER MONITOR (Red/Green) ──────
    Variants
    {
        model: Quickshell.screens
        delegate: PanelWindow
        {
            id: topDebugOverlay
            visible: false
            required property var modelData
            screen: modelData

            anchors.top: true
            anchors.left: true
            implicitWidth: 260
            implicitHeight: 130
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            mask: Region {} // click-through

            Rectangle
            {
                id: topDebugInnerRect
                x: 16
                y: 36
                width: topDebugTextCol.width + 20
                height: topDebugTextCol.height + 16
                color: Qt.rgba(0, 0, 0, 0.90)
                border.color: "#ff3333"
                border.width: 3
                radius: 6

                Column
                {
                    id: topDebugTextCol
                    anchors.centerIn: parent
                    spacing: 4

                    property var monObj: (shellRoot.parsedMonitors || []).find(function(m) { return m.name === topDebugOverlay.screen.name })
                    property int currentWsId: monObj && monObj.activeWorkspace ? monObj.activeWorkspace.id : 0
                    property int currentVdeskId: currentWsId > 10 ? (currentWsId - 10) : currentWsId

                    Text
                    {
                        text: "WS: " + topDebugTextCol.currentWsId
                        color: "#ff3333"
                        font.family: "Hack"
                        font.bold: true
                        font.pixelSize: 26
                    }

                    Text
                    {
                        text: "VDESK: " + topDebugTextCol.currentVdeskId
                        color: "#33ff33"
                        font.family: "Hack"
                        font.bold: true
                        font.pixelSize: 26
                    }
                }
            }
        }
    }

    // ── 2. BOTTOM-LEFT FOCUS DIAGNOSTIC HUD (Hot Pink) ──────────────
    Variants
    {
        model: Quickshell.screens
        delegate: PanelWindow
        {
            id: bottomPinkOverlay
            visible: false
            required property var modelData
            screen: modelData

            anchors.bottom: true
            anchors.left: true
            implicitWidth: 800
            implicitHeight: 180
            color: "transparent"

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusiveZone: 0
            mask: Region {} // click-through

            Rectangle
            {
                id: bottomPinkInnerRect
                x: 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                width: bottomPinkTextCol.width + 24
                height: bottomPinkTextCol.height + 20
                color: Qt.rgba(0, 0, 0, 0.92)
                border.color: "#ff2a8d"
                border.width: 3
                radius: 6

                Column
                {
                    id: bottomPinkTextCol
                    anchors.centerIn: parent
                    spacing: 4

                    property var actWin: shellRoot.parsedActiveWindow
                    property int winWsId: actWin && actWin.workspace ? actWin.workspace.id : 0
                    property int winVdeskId: winWsId > 10 ? (winWsId - 10) : winWsId
                    property int winX: actWin && actWin.at && actWin.at.length > 0 ? actWin.at[0] : 0
                    property int winY: actWin && actWin.at && actWin.at.length > 1 ? actWin.at[1] : 0
                    property string winCls: actWin && actWin.class ? actWin.class : (actWin && actWin.title ? actWin.title.substring(0, 16) : "none")

                    // 1. Satır: Gerçekte focus hangi ws de
                    Text
                    {
                        text: "1. GERÇEK FOCUS WS: " + shellRoot.activeWorkspaceId
                        color: "#ff2a8d"
                        font.family: "Hack"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    // 2. Satır: Bizim vdeskimizdeki focus nerede
                    Text
                    {
                        text: "2. VDESK FOCUS: " + (shellRoot.activeWorkspaceId > 10 ? (shellRoot.activeWorkspaceId - 10) : shellRoot.activeWorkspaceId)
                        color: "#ff2a8d"
                        font.family: "Hack"
                        font.bold: true
                        font.pixelSize: 22
                    }

                    // 3. Satır: Focusun hangi pencere olduğu -> WS, VDESK
                    Text
                    {
                        text: "3. WIN: " + bottomPinkTextCol.winCls + " -> WS: " + bottomPinkTextCol.winWsId + ", VDESK: " + bottomPinkTextCol.winVdeskId
                        color: "#ff2a8d"
                        font.family: "Hack"
                        font.bold: true
                        font.pixelSize: 20
                    }

                    // 4. Satır: Koordinat bilgisi
                    Text
                    {
                        text: "   KOORDİNAT: (" + bottomPinkTextCol.winX + ", " + bottomPinkTextCol.winY + ")"
                        color: "#ff66cc"
                        font.family: "Hack"
                        font.bold: true
                        font.pixelSize: 18
                    }
                }
            }
        }
    }
}
