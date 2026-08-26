import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."

PanelWindow {
    id: windowSwitcherPanel

    property var parsedWorkspaces: []
    property var parsedClients: []
    property var parsedMonitors: []
    property int activeWorkspaceId: 1
    property string activeWindowAddress: ""
    property bool isAnyDragging: false

    property bool hasDualMonitors: (parsedMonitors && parsedMonitors.length > 1)

    signal pollRequested()
    signal fetchRequested()
    signal dragStateChanged(bool dragging)

    function cancelDrag(address) {
        var cancelCmd = "hyprctl eval 'return hl.plugin.qswitcher.cancel(\"" + address + "\")'"
        console.log("[WindowSwitcher] Global cancel executing for:", address)
        globalCancelProcess.command = ["sh", "-c", cancelCmd]
        globalCancelProcess.running = true
    }

    function getVirtualDesktops() {
        var curActV = (activeWorkspaceId > 10) ? (activeWorkspaceId - 10) : activeWorkspaceId
        if (!curActV || curActV <= 0) curActV = 1

        var vmap = {}
        // Always include the current active virtual desktop
        vmap[curActV] = true

        // Include any virtual desktop that contains at least one client
        if (parsedClients && parsedClients.length > 0) {
            for (var c = 0; c < parsedClients.length; c++) {
                var cl = parsedClients[c]
                if (cl && cl.workspace && cl.workspace.id > 0) {
                    var vId = (cl.workspace.id > 10) ? (cl.workspace.id - 10) : cl.workspace.id
                    vmap[vId] = true
                }
            }
        }

        var list = []
        for (var k in vmap) {
            var vid = parseInt(k)
            list.push({
                vdeskId: vid,
                leftWsId: vid,
                rightWsId: 10 + vid,
                isActive: (curActV === vid)
            })
        }
        list.sort(function(a, b) { return a.vdeskId - b.vdeskId })
        return list
    }

    visible: windowSwitcher.isVisible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Rectangle {
        id: windowSwitcher

        property bool isVisible: false

        anchors.fill: parent
        color: "#66000000" // 40% black backdrop for clear overview focus
        visible: isVisible

        // Click on background to dismiss
        MouseArea {
            anchors.fill: parent
            onClicked: {
                windowSwitcher.isVisible = false
            }
        }

        // Center card container
        Item {
            anchors.centerIn: parent
            width: workspaceCardsRow.width + 40
            height: workspaceCardsRow.height + 60

            Column {
                anchors.centerIn: parent
                spacing: 12

                Row {
                    id: workspaceCardsRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 124
                    spacing: 16

                    // Existing Workspace / Virtual Desktop Cards
                    Repeater {
                        model: windowSwitcherPanel.getVirtualDesktops()
                        
                        delegate: WorkspaceCard {
                            isDualMonitor: windowSwitcherPanel.hasDualMonitors
                            vdeskId: modelData.vdeskId || modelData.id || 1
                            workspaceid: modelData.id || modelData.vdeskId || 1
                            leftWsId: modelData.leftWsId || modelData.id || 1
                            rightWsId: modelData.rightWsId || (10 + (modelData.id || 1))

                            allclients: windowSwitcherPanel.parsedClients
                            allmonitors: windowSwitcherPanel.parsedMonitors
                            allworkspaces: windowSwitcherPanel.parsedWorkspaces
                            isActive: windowSwitcherPanel.hasDualMonitors ? modelData.isActive : (modelData.id === windowSwitcherPanel.activeWorkspaceId)
                            activeWindowAddress: windowSwitcherPanel.activeWindowAddress
                            
                            onFetchRequested: windowSwitcherPanel.fetchRequested()
                            onDragStarted: {
                                windowSwitcherPanel.isAnyDragging = true
                                windowSwitcherPanel.dragStateChanged(true)
                            }
                            onDragEnded: {
                                windowSwitcherPanel.isAnyDragging = false
                                windowSwitcherPanel.dragStateChanged(false)
                            }
                            onCancelDragRequested: function(addr) {
                                windowSwitcherPanel.isAnyDragging = false
                                windowSwitcherPanel.cancelDrag(addr)
                            }
                            onWorkspaceSelected: {
                                console.log("[WindowSwitcher] Workspace selected, closing switcher")
                                windowSwitcher.isVisible = false
                            }
                            onClientDoubleClicked: function(addr, wsId) {
                                console.log("[WindowSwitcher] Client double-clicked, focusing window and switching vdesk:", addr, "ws:", wsId)
                                focusClientProcess.command = ["sh", "-c", "hyprctl eval 'return require(\"lua.syncedworkspaces\").focus_window_and_vdesk(\"" + addr + "\", " + wsId + ")'"]
                                focusClientProcess.running = true
                                windowSwitcher.isVisible = false
                            }
                        }
                    }
                }

                // Centered Minimalist [+] Button below workspace cards
                Rectangle {
                    id: newWsBtn
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 32
                    height: 24
                    radius: 4
                    color: btnMouseArea.containsMouse ? Theme.base : Qt.rgba(0.08, 0.06, 0.05, 0.75)
                    border.width: 1
                    border.color: btnMouseArea.containsMouse ? Theme.border : Qt.rgba(1, 0.6, 0.18, 0.35)

                    Text {
                        anchors.centerIn: parent
                        text: "+"
                        color: btnMouseArea.containsMouse ? Theme.border : Theme.text
                        font.family: Theme.fontFamily || "Hack"
                        font.pixelSize: 15
                        font.bold: true
                    }

                    DropArea {
                        id: newWsBtnDropArea
                        anchors.fill: parent
                        keys: ["clientCard"]

                        onDropped: function(drop) {
                            var src = drop.source
                            if (!src || !src.clientAddress) return
                            src.dropHandled = true

                            var maxV = 0
                            if (windowSwitcherPanel.parsedWorkspaces) {
                                windowSwitcherPanel.parsedWorkspaces.forEach(function(w) {
                                    if (w.id > 0) {
                                        var v = (w.id > 10) ? (w.id - 10) : w.id
                                        if (v > maxV) maxV = v
                                    }
                                })
                            }
                            var nextV = maxV + 1
                            var targetWs = nextV
                            var mon = windowSwitcherPanel.hasDualMonitors ? (windowSwitcherPanel.parsedMonitors.find(m => m.name === "HDMI-A-1") || { x: 0, y: 0, width: 1920, height: 1080 }) : { x: 0, y: 0, width: 1920, height: 1080 }
                            var targetX = Math.round(mon.x + (mon.width - (src.clientSizex || 800)) / 2)
                            var targetY = Math.round(mon.y + (mon.height - (src.clientSizey || 600)) / 2)

                            var dropCmd = "hyprctl eval 'return hl.plugin.qswitcher.drop(\"" + src.clientAddress + "\", " + targetWs + ", " + targetX + ", " + targetY + ", \"" + (mon.name || "") + "\")'"
                            createNewWsProcess.command = ["sh", "-c", dropCmd]
                            createNewWsProcess.running = true
                        }
                    }

                    MouseArea {
                        id: btnMouseArea
                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            var maxV = 0
                            if (windowSwitcherPanel.parsedWorkspaces) {
                                windowSwitcherPanel.parsedWorkspaces.forEach(function(w) {
                                    if (w.id > 0) {
                                        var v = (w.id > 10) ? (w.id - 10) : w.id
                                        if (v > maxV) maxV = v
                                    }
                                })
                            }
                            var nextV = maxV + 1
                            if (windowSwitcherPanel.hasDualMonitors) {
                                createNewWsProcess.command = ["sh", "-c", "hyprctl eval 'return require(\"lua.syncedworkspaces\").switch_vdesk(" + nextV + ")'"]
                            } else {
                                createNewWsProcess.command = ["sh", "-c", "hyprctl dispatch 'hl.dsp.workspace.create()'"]
                            }
                            createNewWsProcess.running = true
                        }
                    }
                }
            }
        }

        Process {
            id: createNewWsProcess
            command: ["sh", "-c", "echo noop"]
            stdout: StdioCollector {
                onStreamFinished: {
                    windowSwitcherPanel.fetchRequested()
                }
            }
        }

        Process {
            id: globalCancelProcess
            command: ["sh", "-c", "echo noop"]
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text && text.trim()) console.log("[WindowSwitcher] globalCancel stdout:", text.trim())
                    windowSwitcherPanel.fetchRequested()
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text && text.trim()) console.log("[WindowSwitcher] globalCancel stderr:", text.trim())
                }
            }
        }

        Process {
            id: focusClientProcess
            command: ["sh", "-c", "echo noop"]
            stdout: StdioCollector {
                onStreamFinished: {
                    if (text && text.trim()) console.log("[WindowSwitcher] focusClient stdout:", text.trim())
                }
            }
            stderr: StdioCollector {
                onStreamFinished: {
                    if (text && text.trim()) console.log("[WindowSwitcher] focusClient stderr:", text.trim())
                }
            }
        }

        Timer {
            id: uiUpdater
            repeat: true
            running: windowSwitcher.isVisible
            interval: 100
            onTriggered: {
                windowSwitcherPanel.pollRequested()
            }
        }

        IpcHandler {
            target: "windowSwitcher"
            function toggleVisibility() {
                if (windowSwitcher.isVisible && windowSwitcherPanel.isAnyDragging) {
                    return
                }
                windowSwitcher.isVisible = !windowSwitcher.isVisible
                console.log("[WindowSwitcher] IPC toggleVisibility -> isVisible:", windowSwitcher.isVisible)
                if (windowSwitcher.isVisible) {
                    windowSwitcherPanel.pollRequested()
                }
            }
        }
    }
}
