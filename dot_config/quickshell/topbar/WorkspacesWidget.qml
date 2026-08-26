import ".."
import QtQuick
import Quickshell
import Quickshell.Io

Row {
    id: workspaceButtonsRow

    property var parsedWorkspaces: []
    property var parsedClients: []
    property var parsedMonitors: []
    property int activeWorkspaceId: 1
    property string activeWindowAddress: ""

    spacing: 5

    function getVirtualDesktops() {
        var activeVdesk = (activeWorkspaceId > 10) ? (activeWorkspaceId - 10) : activeWorkspaceId
        if (!activeVdesk || activeVdesk <= 0) activeVdesk = 1

        var vmap = {}
        vmap[activeVdesk] = true

        if (parsedClients && parsedClients.length > 0) {
            for (var c = 0; c < parsedClients.length; c++) {
                var cl = parsedClients[c]
                if (cl && cl.workspace && cl.workspace.id > 0) {
                    var cvId = (cl.workspace.id > 10) ? (cl.workspace.id - 10) : cl.workspace.id
                    vmap[cvId] = true
                }
            }
        }

        var list = []
        for (var k in vmap) {
            var vid = parseInt(k)
            list.push({
                id: vid,
                vdeskId: vid,
                leftWsId: vid,
                rightWsId: 10 + vid,
                isActive: (activeVdesk === vid)
            })
        }
        list.sort((a, b) => a.vdeskId - b.vdeskId)
        return list
    }

    Repeater {
        model: workspaceButtonsRow.getVirtualDesktops()
        
        delegate: Rectangle {
            id: wsCard
            property int vdeskId: modelData.vdeskId || modelData.id || 1
            property bool isWsActive: modelData.isActive

            property var wsClients: {
                if (!workspaceButtonsRow.parsedClients) return []
                var raw = workspaceButtonsRow.parsedClients.filter(function(c) {
                    if (!c.workspace || c.workspace.id <= 0) return false
                    var v = (c.workspace.id > 10) ? (c.workspace.id - 10) : c.workspace.id
                    return v === wsCard.vdeskId
                })

                // Spatial sorting: Left-to-right (X), top-to-bottom (Y) when in same vertical column
                raw.sort(function(a, b) {
                    var ax = (a.at && a.at.length > 0) ? a.at[0] : 0
                    var ay = (a.at && a.at.length > 1) ? a.at[1] : 0
                    var bx = (b.at && b.at.length > 0) ? b.at[0] : 0
                    var by = (b.at && b.at.length > 1) ? b.at[1] : 0

                    if (Math.abs(ax - bx) <= 20) {
                        return ay - by
                    }
                    return ax - bx
                })

                return raw
            }

            height: 31
            width: contentRow.width + 16
            radius: 4
            color: Theme.base
            border.color: wsCard.isWsActive ? Theme.border : Qt.rgba(1, 0.6, 0.18, 0.3)
            border.width: 1

            Process {
                id: hyprctlDispatcher
                command: ["sh", "-c", "hyprctl eval 'return require(\"lua.syncedworkspaces\").switch_vdesk(" + wsCard.vdeskId + ")'"]
                running: false
            }

            Process {
                id: focusClientProcess
                command: ["sh", "-c", "echo noop"]
                running: false
            }

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: 6

                // Virtual Desktop ID (Amber when active)
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: wsCard.vdeskId + ""
                    color: wsCard.isWsActive ? Theme.border : Theme.text
                    font.pixelSize: 13
                    font.bold: true
                    font.family: "Hack"
                }

                // Client window tags (Amber themed)
                Repeater {
                    model: wsCard.wsClients

                    delegate: Rectangle {
                        id: clientTag
                        property bool isClientFocused: (workspaceButtonsRow.activeWindowAddress !== "" && modelData.address === workspaceButtonsRow.activeWindowAddress)
                        anchors.verticalCenter: parent.verticalCenter
                        height: 21
                        width: clientTagText.width + 8
                        radius: 3
                        color: isClientFocused ? Theme.border : "transparent"
                        border.color: isClientFocused ? Theme.border : Qt.rgba(1, 0.6, 0.18, 0.4)
                        border.width: 1

                        Text {
                            id: clientTagText
                            anchors.centerIn: parent
                            text: {
                                var cls = modelData.class || ""
                                if (cls.indexOf(".") !== -1) {
                                    var parts = cls.split(".")
                                    cls = parts[parts.length - 1]
                                }
                                if (cls.length === 0) {
                                    cls = modelData.title ? modelData.title.trim().substring(0, 10) : "window"
                                }
                                return cls.toLowerCase()
                            }
                            color: clientTag.isClientFocused ? Theme.background : Theme.text
                            font.pixelSize: 11
                            font.family: "Hack"
                            font.bold: clientTag.isClientFocused
                        }

                        MouseArea {
                            id: tagMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                mouse.accepted = true
                                var targetWs = modelData.workspace ? modelData.workspace.id : wsCard.vdeskId
                                console.log("[WorkspacesWidget] Focus window clicked:", modelData.address, "ws:", targetWs)
                                focusClientProcess.command = ["sh", "-c", "hyprctl eval 'return require(\"lua.syncedworkspaces\").focus_window_and_vdesk(\"" + modelData.address + "\", " + targetWs + ")'"]
                                focusClientProcess.running = true
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                z: -1
                onClicked: {
                    console.log("[WorkspacesWidget] Workspace card clicked, switching to vdesk:", wsCard.vdeskId)
                    hyprctlDispatcher.running = true
                }
            }
        }
    }
}
