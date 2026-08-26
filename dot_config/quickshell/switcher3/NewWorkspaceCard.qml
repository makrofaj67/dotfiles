import QtQuick
import Quickshell.Io
import ".."

Rectangle {
    id: newWsCard

    property bool isDualMonitor: false
    property var allworkspaces: null
    property var allmonitors: null

    signal fetchRequested()
    signal workspaceSelected()

    width: isDualMonitor ? 400 : 208
    height: 124
    color: Theme.base
    border.width: 1
    border.color: Qt.rgba(1, 0.6, 0.18, 0.3)
    radius: 6

    Rectangle {
        id: newWsInner
        anchors.fill: parent
        anchors.margins: 8
        color: Theme.base
        border.width: 1
        border.color: Qt.rgba(1, 0.6, 0.18, 0.2)
        radius: 4

        // Plus icon in center
        Text {
            anchors.centerIn: parent
            text: "+"
            color: Theme.text
            opacity: dropArea.containsDrag ? 0.8 : 0.25
            font.pixelSize: 28
            font.bold: true
            font.family: "Hack"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            newWsCard.border.color = Theme.border
        }
        onExited: {
            newWsCard.border.color = Qt.rgba(1, 0.6, 0.18, 0.3)
        }

        onDoubleClicked: {
            if (isDualMonitor) {
                var maxV = 0
                if (newWsCard.allworkspaces) {
                    newWsCard.allworkspaces.forEach(function(w) {
                        if (w.id > 0) {
                            var v = (w.id > 10) ? (w.id - 10) : w.id
                            if (v > maxV) maxV = v
                        }
                    })
                }
                var nextV = maxV + 1
                createEmptyWsProcess.command = ["sh", "-c", "hyprctl eval 'return require(\"lua.syncedworkspaces\").switch_vdesk(" + nextV + ")'"]
            } else {
                createEmptyWsProcess.command = ["sh", "-c", "hyprctl dispatch 'hl.dsp.workspace.create()'"]
            }
            createEmptyWsProcess.running = true
            newWsCard.workspaceSelected()
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        keys: ["clientCard"]

        onDropped: function(drop) {
            var src = drop.source
            if (!src || !src.clientAddress)
                return

            src.dropHandled = true
            var addr = src.clientAddress
            
            var realWidth = src.clientSizex || 0
            var realHeight = src.clientSizey || 0

            var maxV = 0
            if (newWsCard.allworkspaces) {
                newWsCard.allworkspaces.forEach(function(w) {
                    if (w.id > 0) {
                        var v = (w.id > 10) ? (w.id - 10) : w.id
                        if (v > maxV) maxV = v
                    }
                })
            }
            var nextV = maxV + 1

            if (isDualMonitor) {
                var dropLeft = (drop.x < 192)
                var newWsId = dropLeft ? nextV : (10 + nextV)
                var mon = dropLeft ? 
                    ((newWsCard.allmonitors && newWsCard.allmonitors.find(m => m.name === "HDMI-A-1")) || { name: "HDMI-A-1", x: 0, y: 0, width: 1920, height: 1080 }) :
                    ((newWsCard.allmonitors && newWsCard.allmonitors.find(m => m.name === "eDP-1")) || { name: "eDP-1", x: 1920, y: 0, width: 1920, height: 1080 })

                var subX = dropLeft ? drop.x : (drop.x - 192)
                var targetX = Math.round(mon.x + (subX / 192) * mon.width - (realWidth / 2))
                var targetY = Math.round(mon.y + (drop.y / 108) * mon.height - (realHeight / 2))

                var dropCmd = "hyprctl eval 'return hl.plugin.qswitcher.drop(\"" + addr + "\", " + newWsId + ", " + targetX + ", " + targetY + ", \"" + (mon.name || "") + "\")'"
                dropDispatcher.command = ["sh", "-c", dropCmd]
                dropDispatcher.running = true
            } else {
                var newWsId = nextV
                var mon = (newWsCard.allmonitors && newWsCard.allmonitors.length > 0) ? newWsCard.allmonitors[0] : { name: "", x: 0, y: 0, width: 1920, height: 1080 }
                var targetX = Math.round(mon.x + (drop.x / newWsCard.width) * mon.width - (realWidth / 2))
                var targetY = Math.round(mon.y + (drop.y / newWsCard.height) * mon.height - (realHeight / 2))

                var dropCmd = "hyprctl eval 'return hl.plugin.qswitcher.drop(\"" + addr + "\", " + newWsId + ", " + targetX + ", " + targetY + ", \"" + (mon.name || "") + "\")'"
                dropDispatcher.command = ["sh", "-c", dropCmd]
                dropDispatcher.running = true
            }
        }
    }

    Process {
        id: createEmptyWsProcess
        command: ["sh", "-c", "echo noop"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[NewWorkspaceCard] createWs stdout:", text.trim())
                newWsCard.fetchRequested()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[NewWorkspaceCard] createWs stderr:", text.trim())
            }
        }
    }

    Process {
        id: dropDispatcher
        command: ["sh", "-c", "echo noop"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[NewWorkspaceCard] drop stdout:", text.trim())
                newWsCard.fetchRequested()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[NewWorkspaceCard] drop stderr:", text.trim())
            }
        }
    }
}
