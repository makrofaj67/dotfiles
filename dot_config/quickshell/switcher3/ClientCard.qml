import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: clientCard

    property var parentMon: ({ x: 0, y: 0, width: 1920, height: 1080 })
    property real clientAtx: 0
    property real clientAty: 0
    property real clientSizex: 0
    property real clientSizey: 0
    property string clientClass: ""
    property string clientTitle: ""
    property string clientAddress: ""
    property bool clientFloating: false
    property int clientWorkspaceId: 1
    property int clientActiveWindow: 0

    // Temporary ghost hiding after drop/cancel
    property bool isDropped: false
    visible: !isDropped

    onOrigXChanged: isDropped = false
    onOrigYChanged: isDropped = false

    Timer {
        id: ghostBusterTimer
        interval: 150
        onTriggered: clientCard.isDropped = false
    }

    property bool isDragging: false
    property bool wasFloating: false
    property bool dropHandled: false
    property real lastMoveTime: 0

    // Dynamic resolution scaling
    property var origX: (parentMon && parentMon.width > 0) ? ((clientAtx - parentMon.x) / parentMon.width) * 192 : 0
    property var origY: (parentMon && parentMon.height > 0) ? ((clientAty - parentMon.y) / parentMon.height) * 108 : 0

    signal hoverStateChanged(bool hovered)
    signal dragStarted()
    signal dragEnded()
    signal clientDoubleClicked(string address, int workspaceId)
    signal cancelDragRequested(string address)
    signal fetchRequested()

    // Decouple x/y bindings during drag to eliminate polling jitter
    Binding on x {
        when: !clientCard.isDragging
        value: clientCard.origX
    }
    Binding on y {
        when: !clientCard.isDragging
        value: clientCard.origY
    }

    width: Math.max(16, (parentMon && parentMon.width > 0) ? (clientSizex / parentMon.width) * 192 : 16)
    height: Math.max(16, (parentMon && parentMon.height > 0) ? (clientSizey / parentMon.height) * 108 : 16)
    color: (clientActiveWindow === 1) ? Qt.rgba(1, 0.6, 0.18, 0.82) : Qt.rgba(0.08, 0.06, 0.05, 0.70)
    border.color: (clientActiveWindow === 1) ? Theme.border : (dragArea.containsMouse ? Theme.border : Qt.rgba(1, 0.6, 0.18, 0.45))
    border.width: 1
    radius: 3
    z: isDragging ? 100000 : (dragArea.containsMouse ? 9999 : 1)
    opacity: isDragging ? 0.85 : 1.0

    Behavior on scale {
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }

    Drag.active: dragArea.drag.active
    Drag.source: clientCard
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
    Drag.keys: ["clientCard"]

    // Client Name Text (Proportional font size matching TopBar tags)
    Text {
        id: clientLabel
        anchors.centerIn: parent
        width: Math.max(0, parent.width - 6)
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: {
            var cls = clientClass || ""
            if (cls.indexOf(".") !== -1) {
                var parts = cls.split(".")
                cls = parts[parts.length - 1]
            }
            if (cls.length === 0) {
                cls = clientTitle ? clientTitle.trim().substring(0, 12) : "window"
            }
            return cls.toLowerCase()
        }
        color: (clientActiveWindow === 1) ? Theme.background : Theme.text
        font.family: Theme.fontFamily || "Hack"
        font.bold: (clientActiveWindow === 1)
        font.pixelSize: Math.max(7, Math.min(13, Math.floor(Math.min(clientCard.width / 5, clientCard.height / 2.8))))
    }

    // 2-Row Debug Number Stack (Hidden)
    Column {
        id: clientLabelCol
        visible: false
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "V:" + ((clientCard.clientWorkspaceId > 10) ? (clientCard.clientWorkspaceId - 10) : clientCard.clientWorkspaceId)
            color: "#33ff33"
            font.family: "Hack"
            font.bold: true
            font.pixelSize: Math.max(10, Math.min(22, Math.floor(clientCard.height / 2.6)))
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "W:" + clientCard.clientWorkspaceId
            color: "#ff3333"
            font.family: "Hack"
            font.bold: true
            font.pixelSize: Math.max(10, Math.min(22, Math.floor(clientCard.height / 2.6)))
        }
    }

    // Tooltip for full title / class name on hover
    Rectangle {
        id: tooltip
        visible: dragArea.containsMouse && !clientCard.isDragging
        color: Theme.base
        border.color: Theme.border
        radius: 3
        width: tooltipText.width + 12
        height: 20
        anchors.bottom: parent.top
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        z: 99999

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: clientClass + (clientTitle ? ": " + clientTitle : "")
            color: Theme.text
            font.pixelSize: 10
            font.family: "Hack"
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: clientCard
        drag.axis: Drag.XAndYAxis
        hoverEnabled: true

        property real startPressX: 0
        property real startPressY: 0
        property bool dragInitiated: false

        onEntered: {
            clientCard.hoverStateChanged(true)
        }
        onExited: {
            clientCard.hoverStateChanged(false)
        }

        onPressed: function(mouse) {
            startPressX = mouse.x
            startPressY = mouse.y
            dragInitiated = false
            clientCard.dropHandled = false
            console.log("[ClientCard] Pressed on:", clientCard.clientClass, "addr:", clientCard.clientAddress, "ws:", clientCard.clientWorkspaceId)
        }

        onPositionChanged: function(mouse) {
            if (dragArea.drag.active) {
                if (!dragInitiated) {
                    dragInitiated = true
                    clientCard.isDragging = true
                    clientCard.wasFloating = clientCard.clientFloating
                    clientCard.dragStarted()

                    // Start persistent pipe stream and send START immediately via FIFO
                    dragStreamProcess.running = true
                    dragStreamProcess.write("START " + clientCard.clientAddress + "\n")
                }

                // Throttle FIFO stream to ~60fps (16ms)
                var now = Date.now()
                if (now - clientCard.lastMoveTime > 16) {
                    clientCard.lastMoveTime = now

                    var parentWs = clientCard.parent ? clientCard.parent : null
                    var mon = clientCard.parentMon || { x: 0, y: 0, width: 1920, height: 1080 }
                    var pWidth = parentWs ? parentWs.width : 192
                    var pHeight = parentWs ? parentWs.height : 108

                    var curCenterX = clientCard.x + clientCard.width / 2
                    var curCenterY = clientCard.y + clientCard.height / 2

                    var scaleX = (mon.width > 0 && pWidth > 0) ? (mon.width / pWidth) : 10
                    var scaleY = (mon.height > 0 && pHeight > 0) ? (mon.height / pHeight) : 10

                    var screenX = Math.round(mon.x + curCenterX * scaleX - clientCard.clientSizex / 2)
                    var screenY = Math.round(mon.y + curCenterY * scaleY - clientCard.clientSizey / 2)

                    // Write directly to stdin of persistent stream (Zero PID / Zero fork overhead)
                    var payload = "MOVE " + now + " " + clientCard.clientAddress + " " + (clientCard.clientWorkspaceId || 1) + " " + screenX + " " + screenY + "\n"
                    dragStreamProcess.write(payload)
                }
            }
        }

        onReleased: function() {
            // Close persistent pipe stream on release
            dragStreamProcess.running = false

            if (dragInitiated) {
                // 1. Trigger synchronous QML Drop on target DropArea
                var dropAction = clientCard.Drag.drop()
                
                // 2. Allow event queue tick for dropHandled to be processed reliably
                Qt.callLater(function() {
                    if (!clientCard.dropHandled) {
                        console.log("[ClientCard] Dropped outside, requesting global cancel for:", clientCard.clientAddress)
                        clientCard.cancelDragRequested(clientCard.clientAddress)
                        
                        var cancelCmd = "hyprctl eval 'return hl.plugin.qswitcher.cancel(\"" + clientCard.clientAddress + "\")'"
                        dragCancelProcess.command = ["sh", "-c", cancelCmd]
                        dragCancelProcess.running = true

                        // Hide immediately during cancel until polling restores card at original slot
                        clientCard.isDropped = true
                        ghostBusterTimer.start()
                    } else {
                        clientCard.isDropped = true
                        ghostBusterTimer.start()
                    }
                    
                    dragInitiated = false
                    clientCard.isDragging = false
                    clientCard.dragEnded()
                })
            } else {
                dragInitiated = false
                clientCard.isDragging = false
            }
        }

        onDoubleClicked: function() {
            console.log("[ClientCard] Double clicked on:", clientCard.clientClass, "addr:", clientCard.clientAddress, "ws:", clientCard.clientWorkspaceId)
            clientCard.clientDoubleClicked(clientCard.clientAddress, clientCard.clientWorkspaceId)
        }
    }

    // Persistent stream process: keeps pipe open during drag with non-blocking safety
    Process {
        id: dragStreamProcess
        command: ["sh", "-c", "exec dd of=\"${XDG_RUNTIME_DIR:-/tmp}/qswitcher.fifo\" status=none"]
        running: false
    }

    Process {
        id: dragCancelProcess
        command: ["sh", "-c", "echo noop"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[ClientCard] dragCancel stdout:", text.trim())
                clientCard.fetchRequested()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[ClientCard] dragCancel stderr:", text.trim())
            }
        }
    }

    Component.onDestruction: {
        if (clientCard.isDragging) {
            dragStreamProcess.running = false
            clientCard.cancelDragRequested(clientCard.clientAddress)
        }
    }
}
