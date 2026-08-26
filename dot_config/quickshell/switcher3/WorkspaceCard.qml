import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: workspaceCard

    property bool isDualMonitor: false
    property int vdeskId: 1
    property int workspaceid: 1
    property int leftWsId: 1
    property int rightWsId: 11
    property var allclients: null
    property var allmonitors: null
    property var allworkspaces: null
    property bool isActive: false
    property bool isDragging: false
    property bool isLeftDragging: false
    property bool isRightDragging: false
    property string activeDragAddress: ""
    property string activeWindowAddress: ""

    // ── Monitor Resolution & Geometry Helper ──────────────────────────
    property var leftMonObj: (function() {
        var m = allmonitors ? allmonitors.find(mon => mon.name === "HDMI-A-1") : null
        return m || { name: "HDMI-A-1", x: 0, y: 0, width: 1920, height: 1080 }
    })()

    property var rightMonObj: (function() {
        var m = allmonitors ? allmonitors.find(mon => mon.name === "eDP-1") : null
        return m || { name: "eDP-1", x: 1920, y: 0, width: 1920, height: 1080 }
    })()

    property var monObj: isDualMonitor ? leftMonObj : (function() {
        var m = null
        if (allworkspaces && allmonitors) {
            var wsObj = allworkspaces.find(w => w.id === workspaceid)
            if (wsObj) {
                m = allmonitors.find(mon => mon.name === wsObj.monitor || mon.id === wsObj.monitorID)
            }
        }
        if (!m && allmonitors && allmonitors.length > 0) {
            m = allmonitors[0]
        }
        return m || { name: "", x: 0, y: 0, width: 1920, height: 1080 }
    })()

    signal fetchRequested()
    signal dragStarted()
    signal dragEnded()
    signal workspaceSelected()
    signal clientDoubleClicked(string address, int wsId)
    signal cancelDragRequested(string address)

    // ── Model Sync Helper ──────────────────────────────────────────
    function syncModel(model, targetWsId, isVdeskMatch) {
        if (!allclients) return

        var addrMap = {}
        for (var i = 0; i < allclients.length; i++) {
            var c = allclients[i]
            if (c.workspace && c.workspace.id > 0) {
                if (isVdeskMatch) {
                    var v = (c.workspace.id > 10) ? (c.workspace.id - 10) : c.workspace.id
                    if (v === targetWsId) {
                        addrMap[c.address] = c
                    }
                } else {
                    if (c.workspace.id === targetWsId) {
                        addrMap[c.address] = c
                    }
                }
            }
        }

        // In-place update & prune
        for (var k = model.count - 1; k >= 0; k--) {
            var currentAddr = model.get(k).address
            var match = addrMap[currentAddr]

            if (!match) {
                if (workspaceCard.isDragging && currentAddr === workspaceCard.activeDragAddress) {
                    continue
                }
                model.remove(k, 1)
            } else {
                var atx = match.at ? match.at[0] : 0
                var aty = match.at ? match.at[1] : 0
                var sx = match.size ? match.size[0] : 0
                var sy = match.size ? match.size[1] : 0
                var isAct = (workspaceCard.activeWindowAddress !== "" && match.address === workspaceCard.activeWindowAddress) ? 1 : 0

                var item = model.get(k)
                if (item.atx !== atx) model.setProperty(k, "atx", atx)
                if (item.aty !== aty) model.setProperty(k, "aty", aty)
                if (item.sizex !== sx) model.setProperty(k, "sizex", sx)
                if (item.sizey !== sy) model.setProperty(k, "sizey", sy)
                if (item.title !== (match.title || "")) model.setProperty(k, "title", match.title || "")
                if (item.activeWindow !== isAct) model.setProperty(k, "activeWindow", isAct)
                delete addrMap[currentAddr]
            }
        }

        for (var addr in addrMap) {
            var nc = addrMap[addr]
            model.append({
                address: nc.address || "",
                clientClass: nc.class || "",
                title: nc.title || "",
                floating: nc.floating || false,
                atx: nc.at ? nc.at[0] : 0,
                aty: nc.at ? nc.at[1] : 0,
                sizex: nc.size ? nc.size[0] : 0,
                sizey: nc.size ? nc.size[1] : 0,
                activeWindow: (workspaceCard.activeWindowAddress !== "" && nc.address === workspaceCard.activeWindowAddress) ? 1 : 0
            })
        }
    }

    function refreshModels() {
        if (isDualMonitor) {
            syncModel(clientsModelLeft, leftWsId, false)
            syncModel(clientsModelRight, rightWsId, false)
        } else {
            syncModel(clientsModelSingle, vdeskId, true)
        }
    }

    onAllclientsChanged: refreshModels()
    onActiveWindowAddressChanged: refreshModels()
    onLeftWsIdChanged: refreshModels()
    onRightWsIdChanged: refreshModels()
    onWorkspaceidChanged: refreshModels()
    onVdeskIdChanged: refreshModels()
    onIsDualMonitorChanged: refreshModels()
    Component.onCompleted: refreshModels()

    width: isDualMonitor ? 400 : 208
    height: 124
    z: isDragging ? 999999 : (isActive ? 10 : 1)
    color: Theme.base
    border.width: 1
    border.color: isActive ? Theme.border : Qt.rgba(1, 0.6, 0.18, 0.3)
    radius: 6

    // Double-click background to switch to this Virtual Desktop
    MouseArea {
        anchors.fill: parent
        onDoubleClicked: {
            focusWsProcess.command = ["sh", "-c", "hyprctl eval 'return require(\"lua.syncedworkspaces\").switch_vdesk(" + vdeskId + ")'"]
            focusWsProcess.running = true
            workspaceCard.workspaceSelected()
        }
    }

    Process {
        id: focusWsProcess
        command: ["sh", "-c", "echo noop"]
        running: false
    }

    // Background Virtual Desktop Watermark Number
    Text {
        anchors.centerIn: parent
        text: workspaceCard.isDualMonitor ? workspaceCard.vdeskId : workspaceCard.workspaceid
        font.family: Theme.fontFamily || "Hack"
        font.bold: true
        font.pixelSize: 68
        color: workspaceCard.isActive ? Qt.rgba(1, 0.6, 0.18, 0.28) : Qt.rgba(1, 1, 1, 0.10)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        z: 0
    }

    // ── TOP DEBUG HEADER (Hidden) ──
    Item {
        id: topDebugHeader
        visible: false
        height: 0
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        // Left Real Workspace Label (Red)
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "WS: " + (workspaceCard.isDualMonitor ? workspaceCard.leftWsId : workspaceCard.workspaceid)
            font.family: "Hack"
            font.bold: true
            font.pixelSize: 20
            color: "#ff3333"
        }

        // Big Center Vdesk Number (Green)
        Text {
            anchors.centerIn: parent
            text: "VDESK " + (workspaceCard.isDualMonitor ? workspaceCard.vdeskId : workspaceCard.workspaceid)
            font.family: "Hack"
            font.bold: true
            font.pixelSize: 24
            color: workspaceCard.isActive ? "#33ff33" : Qt.rgba(0.2, 1.0, 0.4, 0.5)
        }

        // Right Real Workspace Label (Red)
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: workspaceCard.isDualMonitor
            text: "WS: " + workspaceCard.rightWsId
            font.family: "Hack"
            font.bold: true
            font.pixelSize: 20
            color: "#ff3333"
        }
    }

    // ── DUAL MONITOR LAYOUT ──────────────────────────────────────────
    Item {
        id: dualMonitorContainer
        anchors.fill: parent
        anchors.margins: 8
        visible: workspaceCard.isDualMonitor

        // 1. Left Half: HDMI Monitor (Workspace V)
        Rectangle {
            id: leftHalf
            x: 0
            y: 0
            width: 192
            height: 108
            z: workspaceCard.isLeftDragging ? 999 : 1
            color: Qt.rgba(0.05, 0.04, 0.03, 0.25)
            border.width: 0
            border.color: "transparent"
            radius: 4

            DropArea {
                id: leftDropArea
                anchors.fill: parent
                keys: ["clientCard"]

                onDropped: function(drop) {
                    var src = drop.source
                    if (!src || !src.clientAddress) return

                    src.dropHandled = true
                    var addr = src.clientAddress
                    var targetWs = workspaceCard.leftWsId
                    var mon = workspaceCard.leftMonObj

                    var realWidth = src.clientSizex || 0
                    var realHeight = src.clientSizey || 0

                    var localPos = src.mapToItem(leftHalf, 0, 0)
                    var curCenterX = Math.max(0, Math.min(192, localPos.x + src.width / 2))
                    var curCenterY = Math.max(0, Math.min(108, localPos.y + src.height / 2))

                    var targetX = Math.round(mon.x + (curCenterX / 192) * mon.width - (realWidth / 2))
                    var targetY = Math.round(mon.y + (curCenterY / 108) * mon.height - (realHeight / 2))

                    targetX = Math.max(mon.x, Math.min(mon.x + mon.width - realWidth, targetX))
                    targetY = Math.max(mon.y, Math.min(mon.y + mon.height - realHeight, targetY))

                    var dropCmd = "hyprctl eval 'return hl.plugin.qswitcher.drop(\"" + addr + "\", " + targetWs + ", " + targetX + ", " + targetY + ", \"" + (mon.name || "") + "\")'"
                    dropDispatcher.command = ["sh", "-c", dropCmd]
                    dropDispatcher.running = true
                }
            }

            ListModel { id: clientsModelLeft }

            Repeater {
                model: clientsModelLeft
                delegate: ClientCard {
                    parentMon: workspaceCard.leftMonObj
                    clientAtx: model.atx
                    clientAty: model.aty
                    clientSizex: model.sizex
                    clientSizey: model.sizey
                    clientClass: model.clientClass
                    clientTitle: model.title
                    clientAddress: model.address
                    clientFloating: model.floating
                    clientWorkspaceId: workspaceCard.leftWsId
                    clientActiveWindow: model.activeWindow

                    onDragStarted: {
                        workspaceCard.isDragging = true
                        workspaceCard.isLeftDragging = true
                        workspaceCard.isRightDragging = false
                        workspaceCard.activeDragAddress = clientAddress
                        workspaceCard.dragStarted()
                    }
                    onDragEnded: {
                        workspaceCard.isDragging = false
                        workspaceCard.isLeftDragging = false
                        workspaceCard.isRightDragging = false
                        workspaceCard.activeDragAddress = ""
                        workspaceCard.dragEnded()
                    }
                    onCancelDragRequested: function(addr) {
                        workspaceCard.isDragging = false
                        workspaceCard.isLeftDragging = false
                        workspaceCard.isRightDragging = false
                        workspaceCard.cancelDragRequested(addr)
                    }
                    onClientDoubleClicked: function(addr, wsId) {
                        workspaceCard.clientDoubleClicked(addr, wsId)
                    }
                    onFetchRequested: workspaceCard.fetchRequested()
                }
            }
        }

        // 2. Right Half: Laptop Monitor (Workspace 10+V)
        Rectangle {
            id: rightHalf
            x: 192
            y: 0
            width: 192
            height: 108
            z: workspaceCard.isRightDragging ? 999 : 1
            color: Qt.rgba(0.05, 0.04, 0.03, 0.25)
            border.width: 0
            border.color: "transparent"
            radius: 4

            DropArea {
                id: rightDropArea
                anchors.fill: parent
                keys: ["clientCard"]

                onDropped: function(drop) {
                    var src = drop.source
                    if (!src || !src.clientAddress) return

                    src.dropHandled = true
                    var addr = src.clientAddress
                    var targetWs = workspaceCard.rightWsId
                    var mon = workspaceCard.rightMonObj

                    var realWidth = src.clientSizex || 0
                    var realHeight = src.clientSizey || 0

                    var localPos = src.mapToItem(rightHalf, 0, 0)
                    var curCenterX = Math.max(0, Math.min(192, localPos.x + src.width / 2))
                    var curCenterY = Math.max(0, Math.min(108, localPos.y + src.height / 2))

                    var targetX = Math.round(mon.x + (curCenterX / 192) * mon.width - (realWidth / 2))
                    var targetY = Math.round(mon.y + (curCenterY / 108) * mon.height - (realHeight / 2))

                    targetX = Math.max(mon.x, Math.min(mon.x + mon.width - realWidth, targetX))
                    targetY = Math.max(mon.y, Math.min(mon.y + mon.height - realHeight, targetY))

                    var dropCmd = "hyprctl eval 'return hl.plugin.qswitcher.drop(\"" + addr + "\", " + targetWs + ", " + targetX + ", " + targetY + ", \"" + (mon.name || "") + "\")'"
                    dropDispatcher.command = ["sh", "-c", dropCmd]
                    dropDispatcher.running = true
                }
            }

            ListModel { id: clientsModelRight }

            Repeater {
                model: clientsModelRight
                delegate: ClientCard {
                    parentMon: workspaceCard.rightMonObj
                    clientAtx: model.atx
                    clientAty: model.aty
                    clientSizex: model.sizex
                    clientSizey: model.sizey
                    clientClass: model.clientClass
                    clientTitle: model.title
                    clientAddress: model.address
                    clientFloating: model.floating
                    clientWorkspaceId: workspaceCard.rightWsId
                    clientActiveWindow: model.activeWindow

                    onDragStarted: {
                        workspaceCard.isDragging = true
                        workspaceCard.isRightDragging = true
                        workspaceCard.isLeftDragging = false
                        workspaceCard.activeDragAddress = clientAddress
                        workspaceCard.dragStarted()
                    }
                    onDragEnded: {
                        workspaceCard.isDragging = false
                        workspaceCard.isRightDragging = false
                        workspaceCard.isLeftDragging = false
                        workspaceCard.activeDragAddress = ""
                        workspaceCard.dragEnded()
                    }
                    onCancelDragRequested: function(addr) {
                        workspaceCard.isDragging = false
                        workspaceCard.isRightDragging = false
                        workspaceCard.isLeftDragging = false
                        workspaceCard.cancelDragRequested(addr)
                    }
                    onClientDoubleClicked: function(addr, wsId) {
                        workspaceCard.clientDoubleClicked(addr, wsId)
                    }
                    onFetchRequested: workspaceCard.fetchRequested()
                }
            }
        }
    }

    // ── SINGLE MONITOR LAYOUT ─────────────────────────────────────────
    Rectangle {
        id: singleMonitorContainer
        anchors.fill: parent
        anchors.margins: 8
        visible: !workspaceCard.isDualMonitor
        color: Qt.rgba(0.05, 0.04, 0.03, 0.25)
        border.width: 0
        border.color: "transparent"
        radius: 4

        DropArea {
            id: singleDropArea
            anchors.fill: parent
            keys: ["clientCard"]

            onDropped: function(drop) {
                var src = drop.source
                if (!src || !src.clientAddress) return

                src.dropHandled = true
                var addr = src.clientAddress
                var targetWs = workspaceCard.vdeskId
                var mon = workspaceCard.monObj

                var realWidth = src.clientSizex || 0
                var realHeight = src.clientSizey || 0

                var localPos = src.mapToItem(singleMonitorContainer, 0, 0)
                var curCenterX = Math.max(0, Math.min(192, localPos.x + src.width / 2))
                var curCenterY = Math.max(0, Math.min(108, localPos.y + src.height / 2))

                var targetX = Math.round(mon.x + (curCenterX / 192) * mon.width - (realWidth / 2))
                var targetY = Math.round(mon.y + (curCenterY / 108) * mon.height - (realHeight / 2))

                targetX = Math.max(mon.x, Math.min(mon.x + mon.width - realWidth, targetX))
                targetY = Math.max(mon.y, Math.min(mon.y + mon.height - realHeight, targetY))

                var dropCmd = "hyprctl eval 'return hl.plugin.qswitcher.drop(\"" + addr + "\", " + targetWs + ", " + targetX + ", " + targetY + ", \"" + (mon.name || "") + "\")'"
                dropDispatcher.command = ["sh", "-c", dropCmd]
                dropDispatcher.running = true
            }
        }

        ListModel { id: clientsModelSingle }

        Repeater {
            model: clientsModelSingle
            delegate: ClientCard {
                parentMon: workspaceCard.monObj
                clientAtx: model.atx
                clientAty: model.aty
                clientSizex: model.sizex
                clientSizey: model.sizey
                clientClass: model.clientClass
                clientTitle: model.title
                clientAddress: model.address
                clientFloating: model.floating
                clientWorkspaceId: workspaceCard.workspaceid
                clientActiveWindow: model.activeWindow

                onDragStarted: {
                    workspaceCard.isDragging = true
                    workspaceCard.activeDragAddress = clientAddress
                    workspaceCard.dragStarted()
                }
                onDragEnded: {
                    workspaceCard.isDragging = false
                    workspaceCard.activeDragAddress = ""
                    workspaceCard.dragEnded()
                }
                onCancelDragRequested: function(addr) {
                    workspaceCard.isDragging = false
                    workspaceCard.cancelDragRequested(addr)
                }
                onClientDoubleClicked: function(addr, wsId) {
                    workspaceCard.clientDoubleClicked(addr, wsId)
                }
                onFetchRequested: workspaceCard.fetchRequested()
            }
        }
    }

    Process {
        id: dropDispatcher
        command: ["sh", "-c", "echo noop"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[WorkspaceCard] drop stdout:", text.trim())
                workspaceCard.fetchRequested()
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim()) console.log("[WorkspaceCard] drop stderr:", text.trim())
            }
        }
    }
}
