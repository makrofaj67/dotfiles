import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../.."
import "../shared"

// ═══════════════════════════════════════════════════════════
// OVERVIEW PANEL — Reimplemented with drag & drop
// ═══════════════════════════════════════════════════════════

Variants {
    id: overviewRoot
    model: Quickshell.screens

    // Required bindings from parent
    required property bool visible
    required property int activeVdesk
    required property var allWindows

    // Signals to parent
    signal toggleRequested()
    signal vdeskActivated(int vdeskNum)

    // ═══ STATE ═══
    property var allClients: []  // Raw hyprctl clients -j data
    property var windowsByVdesk: ({})  // Computed: {1: [...], 2: [...], ...}
    property int focusedVdeskIndex: -1  // Keyboard navigation state
    property int monitorCount: Math.max(1, Quickshell.screens.length)
    property int referenceMonitorWidth: (Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920)
    property int referenceMonitorHeight: (Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080)
    property bool fetchRequested: false

    // Drag state
    property var _drag: ({
        active: false,
        addr: "",
        srcVdesk: 0,
        dstVdesk: 0,
        ghostX: 0.0,
        ghostY: 0.0,
        ghostW: 0.0,
        ghostH: 0.0,
        startX: 0.0,
        startY: 0.0,
        originalX: 0.0,
        originalY: 0.0,
        originalW: 0.0,
        originalH: 0.0
    })

    // Resize state
    property var _resize: ({
        active: false,
        addr: "",
        vdesk: 0,
        startX: 0.0,
        startY: 0.0,
        startW: 0.0,
        startH: 0.0,
        currentW: 0.0,
        currentH: 0.0
    })

    // ═══ WINDOW DATA FETCHER ═══
    Process {
        id: clientsProcess
        command: ["/home/rakman/.config/quickshell/scripts/get_all_windows.sh"]
        running: overviewRoot.fetchRequested
        property string buffer: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => clientsProcess.buffer += data
        }

        onExited: {
            if (buffer.length > 0) {
                try {
                    let raw = JSON.parse(buffer.trim())
                    overviewRoot.allClients = raw
                    processClients()
                } catch(e) {
                    console.warn("OverviewPanel: clients parse error:", e)
                    overviewRoot.allClients = []
                }
            }
            buffer = ""
            overviewRoot.fetchRequested = false
        }
    }

    // Map workspace to vdesk.
    // Supports both plugin names (Grid-1) and numeric Hyprland workspaces.
    function workspaceToVdesk(workspace) {
        if (!workspace) return -1

        let name = String(workspace.name || "")
        let gridMatch = name.match(/Grid-(\d+)/)
        if (gridMatch) {
            return parseInt(gridMatch[1])
        }

        let wsId = Number(workspace.id)
        if (isNaN(wsId) || wsId < 1) {
            let parsedFromName = parseInt(name)
            if (!isNaN(parsedFromName) && parsedFromName >= 1) {
                wsId = parsedFromName
            } else {
                return -1
            }
        }

        return Math.floor((wsId - 1) / monitorCount) + 1
    }

    // Process clients into windowsByVdesk structure
    function processClients() {
        let grouped = {}
        for (let i = 1; i <= 9; i++) grouped[i] = []

        allClients.forEach((win, i) => {
            let vd = -1
            if (win.vdesk !== undefined) {
                vd = parseInt(win.vdesk)
            } else if (win.workspace) {
                vd = workspaceToVdesk(win.workspace)
            }

            if (vd >= 1 && vd <= 9) {
                let hasGeometry = !!(win.at && win.size)
                let rawX = hasGeometry ? win.at[0] : 20
                let rawY = hasGeometry ? win.at[1] : (i % 5) * 24
                let rawW = hasGeometry ? win.size[0] : 360
                let rawH = hasGeometry ? win.size[1] : 120

                // On multi-monitor setups, squeeze horizontal geometry into a single-monitor canvas.
                // This keeps all vdesk windows visible in one cell without pushing secondary monitor
                // windows to the far-right edge.
                let horizontalCompression = monitorCount > 1 ? monitorCount : 1
                let renderX = hasGeometry ? (rawX / horizontalCompression) : rawX
                let renderW = hasGeometry ? Math.max(80, rawW / horizontalCompression) : rawW

                grouped[vd].push({
                    address: win.address,
                    title: win.title || "Untitled",
                    class: win.class || "unknown",
                    hasGeometry: hasGeometry,
                    x: rawX,
                    y: rawY,
                    width: rawW,
                    height: rawH,
                    renderX: renderX,
                    renderY: rawY,
                    renderWidth: renderW,
                    renderHeight: rawH,
                    workspace: win.workspace ? win.workspace.name : ("vdesk-" + vd)
                })
            }
        })

        // If a vdesk has heavily overlapping geometry (common with tiled/fullscreen windows),
        // spread thumbnails in a compact internal grid for a clearer overview.
        for (let vd = 1; vd <= 9; vd++) {
            let list = grouped[vd]
            if (!list || list.length <= 1) continue

            let geometryKeys = {}
            let uniqueCount = 0
            for (let j = 0; j < list.length; j++) {
                let w = list[j]
                let key = [
                    Math.round((w.renderX || 0) / 20),
                    Math.round((w.renderY || 0) / 20),
                    Math.round((w.renderWidth || 0) / 20),
                    Math.round((w.renderHeight || 0) / 20)
                ].join(":")
                if (!geometryKeys[key]) {
                    geometryKeys[key] = true
                    uniqueCount++
                }
            }

            let overlapLikely = uniqueCount <= Math.ceil(list.length / 2)
            if (!overlapLikely) continue

            let cols = list.length >= 4 ? 2 : 1
            let rows = Math.ceil(list.length / cols)

            let canvasW = Math.max(800, Math.floor(referenceMonitorWidth * 0.92))
            let canvasH = Math.max(420, Math.floor(referenceMonitorHeight * 0.82))
            let gapX = 50
            let gapY = 42
            let tileW = Math.max(260, Math.floor((canvasW - gapX * (cols + 1)) / cols))
            let tileH = Math.max(120, Math.floor((canvasH - gapY * (rows + 1)) / rows))

            for (let j = 0; j < list.length; j++) {
                let col = j % cols
                let row = Math.floor(j / cols)
                list[j].renderX = gapX + col * (tileW + gapX)
                list[j].renderY = gapY + row * (tileH + gapY)
                list[j].renderWidth = tileW
                list[j].renderHeight = tileH
            }
        }

        windowsByVdesk = grouped
    }

    onAllWindowsChanged: {
        allClients = allWindows || []
        processClients()
    }

    // ═══ IPC SYNC ═══
    Process {
        id: socket2Listener
        command: ["sh", "-c", "socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock -"]
        running: overviewRoot.visible

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                let parts = data.trim().split(">>")
                if (parts.length < 1) return
                let event = parts[0]

                // Re-query on relevant events
                if (event === "openwindow" || event === "closewindow" ||
                    event === "movewindow" || event === "workspace" || event === "focusedmon") {
                    overviewRoot.fetchRequested = true
                }
            }
        }
    }

    // Initial load when visible
    onVisibleChanged: {
        if (visible) {
            allClients = allWindows || []
            processClients()
            focusedVdeskIndex = -1
        }
    }

    PanelWindow {
        id: overviewPanel
        property var modelData
        screen: modelData

        function cellAtPoint(px, py) {
            // Returns vdesk id 1-9 or 0
            for (let i = 0; i < 9; i++) {
                let cell = cellRepeater.itemAt(i)
                if (!cell) continue

                let mapped = cell.mapToItem(keyInputLayer, 0, 0)
                if (px >= mapped.x && px < mapped.x + cell.width &&
                    py >= mapped.y && py < mapped.y + cell.height) {
                    return i + 1
                }
            }
            return 0
        }

        visible: overviewRoot.visible
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; left: true }
        margins {
            top: (screen.height - implicitHeight) / 2
            left: (screen.width - implicitWidth) / 2
        }

        implicitWidth: gridContainer.width + 56
        implicitHeight: gridContainer.height + 100
        color: "transparent"

        // Click outside to close
        MouseArea {
            anchors.fill: parent
            onClicked: overviewRoot.toggleRequested()
        }

        Item {
            id: keyInputLayer
            anchors.fill: parent
            focus: overviewPanel.visible

            // ═══ KEYBOARD NAVIGATION ═══
            Keys.onPressed: (event) => {
                // Escape: close
                if (event.key === Qt.Key_Escape) {
                    overviewRoot.toggleRequested()
                    event.accepted = true
                    return
                }

                // Tab: cycle through vdesks
                if (event.key === Qt.Key_Tab) {
                    overviewRoot.focusedVdeskIndex = (overviewRoot.focusedVdeskIndex + 1) % 9
                    event.accepted = true
                    return
                }

                // Enter: activate focused vdesk
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    if (overviewRoot.focusedVdeskIndex >= 0) {
                        overviewRoot.vdeskActivated(overviewRoot.focusedVdeskIndex + 1)
                        overviewRoot.toggleRequested()
                    }
                    event.accepted = true
                    return
                }

                // Arrow keys: grid navigation
                if (overviewRoot.focusedVdeskIndex < 0) {
                    overviewRoot.focusedVdeskIndex = overviewRoot.activeVdesk - 1
                }

                let col = overviewRoot.focusedVdeskIndex % 3
                let row = Math.floor(overviewRoot.focusedVdeskIndex / 3)

                if (event.key === Qt.Key_Left) {
                    if (col > 0) col--
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    if (col < 2) col++
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    if (row > 0) row--
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    if (row < 2) row++
                    event.accepted = true
                }

                overviewRoot.focusedVdeskIndex = row * 3 + col
            }
        }

        Shortcut { sequence: "Escape"; onActivated: overviewRoot.toggleRequested() }

        // ═══ FRAME & CONTENT ═══
        MetallicFrame {
            id: outerFrame
            anchors.fill: parent
            radius: 12
            showScrews: true
            screwSize: 8
            screwMargin: 10

            // Panel open/close animation
            opacity: overviewRoot.visible ? 1.0 : 0.0
            scale: overviewRoot.visible ? 1.0 : 0.92

            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            DisplayArea {
                id: innerDisplay
                anchors.fill: parent
                anchors.margins: 6
                radius: 8

                // Header
                HeaderBar {
                    id: overviewHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 44
                    radius: parent.radius
                    title: "SYSTEM OVERVIEW"
                    subtitle: "VIRTUAL DESKTOP GRID"
                    iconSize: 22
                }

                // ═══ 3x3 GRID ═══
                Item {
                    id: gridContainer
                    anchors.top: overviewHeader.bottom
                    anchors.topMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: grid.width
                    height: grid.height

                    // Compute scale factor (primary monitor)
                    property real monitorWidth: overviewPanel.screen.width
                    property real monitorHeight: overviewPanel.screen.height
                    property real cellContentWidth: 184  // 200 - 16 for margins
                    property real cellContentHeight: 98  // 140 - 26 header - 16 margins
                    property real _scale: Math.min(cellContentWidth / monitorWidth, cellContentHeight / monitorHeight)

                    Grid {
                        id: grid
                        columns: 3
                        spacing: 10

                        Repeater {
                            id: cellRepeater
                            model: 9

                            Rectangle {
                                id: vdeskCell
                                required property int index
                                readonly property int vdeskNum: index + 1
                                readonly property bool isActive: vdeskNum === overviewRoot.activeVdesk
                                readonly property bool isKeyboardFocused: index === overviewRoot.focusedVdeskIndex
                                readonly property var cellWindows: overviewRoot.windowsByVdesk[vdeskNum] || []
                                readonly property bool isDragTarget: overviewRoot._drag.active && overviewRoot._drag.dstVdesk === vdeskNum

                                width: 200
                                height: 140
                                radius: 6

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: isActive ? Theme.lambdaDark : Theme.cellBackground }
                                    GradientStop { position: 0.5; color: isActive ? Theme.lambda : Theme.backgroundPanel }
                                    GradientStop { position: 1.0; color: isActive ? Theme.lambdaDark : Theme.background }
                                }

                                border.width: isKeyboardFocused ? 3 : (isActive ? 2 : 1)
                                border.color: isKeyboardFocused ? Theme.lambdaLight : (isActive ? Theme.lambda : Theme.cellBorder)

                                // Drag target highlight
                                Behavior on border.color { ColorAnimation { duration: 80 } }

                                // Cell header
                                Rectangle {
                                    id: cellHeader
                                    anchors.top: parent.top
                                    width: parent.width
                                    height: 26
                                    radius: parent.radius

                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: vdeskCell.isActive ? Theme.lambdaDark : (isDragTarget ? Theme.hoverBackground : Theme.backgroundPanel) }
                                        GradientStop { position: 1.0; color: vdeskCell.isActive ? Theme.lambdaMid : (isDragTarget ? Theme.cellBackground : Theme.background) }
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        width: parent.width
                                        height: parent.radius
                                        color: vdeskCell.isActive ? Theme.lambdaMid : (isDragTarget ? Theme.cellBackground : Theme.background)
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "VDESK " + vdeskCell.vdeskNum + " [" + vdeskCell.cellWindows.length + "]"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: vdeskCell.isActive ? Theme.accentText : Theme.textSecondary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            overviewRoot.vdeskActivated(vdeskCell.vdeskNum)
                                            overviewRoot.toggleRequested()
                                        }
                                    }
                                }

                                // Window content area
                                Item {
                                    id: windowContent
                                    anchors.top: cellHeader.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    clip: true

                                    // Window thumbnails
                                    Repeater {
                                        model: vdeskCell.cellWindows

                                        Item {
                                            id: windowThumb
                                            required property var modelData
                                            required property int index
                                            readonly property bool hasGeometry: modelData.hasGeometry === true
                                            readonly property real stackOffsetX: hasGeometry ? ((index % 4) * 5) : 0
                                            readonly property real stackOffsetY: hasGeometry ? ((index % 4) * 3) : 0
                                            readonly property real geomX: modelData.renderX !== undefined ? modelData.renderX : modelData.x
                                            readonly property real geomY: modelData.renderY !== undefined ? modelData.renderY : modelData.y
                                            readonly property real geomW: modelData.renderWidth !== undefined ? modelData.renderWidth : modelData.width
                                            readonly property real geomH: modelData.renderHeight !== undefined ? modelData.renderHeight : modelData.height

                                            // Compute scaled position
                                            property real scaledX: hasGeometry ? (geomX * gridContainer._scale + stackOffsetX) : 0
                                            property real scaledY: hasGeometry ? (geomY * gridContainer._scale + stackOffsetY) : 0
                                            property real scaledW: hasGeometry ? Math.max(24, geomW * gridContainer._scale) : (windowContent.width - 4)
                                            property real scaledH: hasGeometry ? Math.max(14, geomH * gridContainer._scale) : 16

                                            x: hasGeometry
                                                ? Math.min(Math.max(0, scaledX), Math.max(0, windowContent.width - 24))
                                                : 2
                                            y: hasGeometry
                                                ? Math.min(Math.max(0, scaledY), Math.max(0, windowContent.height - 14))
                                                : (index * 18)
                                            width: hasGeometry
                                                ? Math.max(24, Math.min(scaledW, windowContent.width - x))
                                                : Math.max(24, windowContent.width - 4)
                                            height: hasGeometry
                                                ? Math.max(14, Math.min(scaledH, windowContent.height - y))
                                                : 16

                                            Rectangle {
                                                id: thumbRect
                                                anchors.fill: parent
                                                color: Theme.cellBackground
                                                border.width: 1
                                                border.color: Theme.lambda
                                                radius: 2
                                                opacity: overviewRoot._drag.active && overviewRoot._drag.addr === modelData.address ? 0.3 : 1.0

                                                Behavior on opacity { NumberAnimation { duration: 100 } }

                                                // Window title
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.class
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 8
                                                    color: Theme.text
                                                    elide: Text.ElideRight
                                                    width: parent.width - 4
                                                    horizontalAlignment: Text.AlignHCenter
                                                }

                                                // Resize handle (bottom-right corner)
                                                Rectangle {
                                                    id: resizeHandle
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    width: 8
                                                    height: 8
                                                    color: Theme.lambda
                                                    visible: parent.width > 16 && parent.height > 16

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.SizeFDiagCursor

                                                        property real startX: 0
                                                        property real startY: 0

                                                        onPressed: (mouse) => {
                                                            startX = mouse.x
                                                            startY = mouse.y
                                                            overviewRoot._resize.active = true
                                                            overviewRoot._resize.addr = modelData.address
                                                            overviewRoot._resize.vdesk = vdeskCell.vdeskNum
                                                            overviewRoot._resize.startX = mouse.x
                                                            overviewRoot._resize.startY = mouse.y
                                                            overviewRoot._resize.startW = modelData.width
                                                            overviewRoot._resize.startH = modelData.height
                                                            overviewRoot._resize.currentW = modelData.width
                                                            overviewRoot._resize.currentH = modelData.height
                                                        }

                                                        onPositionChanged: (mouse) => {
                                                            if (overviewRoot._resize.active) {
                                                                let deltaX = mouse.x - startX
                                                                let deltaY = mouse.y - startY
                                                                let deltaRealX = deltaX / gridContainer._scale
                                                                let deltaRealY = deltaY / gridContainer._scale

                                                                overviewRoot._resize.currentW = Math.max(60, overviewRoot._resize.startW + deltaRealX)
                                                                overviewRoot._resize.currentH = Math.max(40, overviewRoot._resize.startH + deltaRealY)
                                                            }
                                                        }

                                                        onReleased: {
                                                            if (overviewRoot._resize.active) {
                                                                Hyprland.dispatch(
                                                                    "resizewindowpixel exact " +
                                                                    Math.floor(overviewRoot._resize.currentW) + " " +
                                                                    Math.floor(overviewRoot._resize.currentH) +
                                                                    ",address:" + overviewRoot._resize.addr
                                                                )

                                                                overviewRoot._resize.active = false
                                                                overviewRoot.fetchRequested = true
                                                            }
                                                        }
                                                    }
                                                }

                                                // Drag MouseArea
                                                MouseArea {
                                                    id: dragArea
                                                    anchors.fill: parent
                                                    anchors.rightMargin: resizeHandle.visible ? 8 : 0
                                                    anchors.bottomMargin: resizeHandle.visible ? 8 : 0
                                                    hoverEnabled: true
                                                    cursorShape: Qt.OpenHandCursor

                                                    property real pressX: 0
                                                    property real pressY: 0
                                                    property bool dragging: false

                                                    onPressed: (mouse) => {
                                                        // Convert to root coordinates
                                                        let rootPos = mapToItem(keyInputLayer, mouse.x, mouse.y)
                                                        pressX = rootPos.x
                                                        pressY = rootPos.y
                                                        dragging = false

                                                        overviewRoot._drag.startX = rootPos.x
                                                        overviewRoot._drag.startY = rootPos.y
                                                        overviewRoot._drag.addr = modelData.address
                                                        overviewRoot._drag.srcVdesk = vdeskCell.vdeskNum
                                                        overviewRoot._drag.originalX = modelData.x
                                                        overviewRoot._drag.originalY = modelData.y
                                                        overviewRoot._drag.originalW = modelData.width
                                                        overviewRoot._drag.originalH = modelData.height
                                                    }

                                                    onPositionChanged: (mouse) => {
                                                        if (!overviewRoot._drag.active && !dragging) {
                                                            let rootPos = mapToItem(keyInputLayer, mouse.x, mouse.y)
                                                            let dx = rootPos.x - pressX
                                                            let dy = rootPos.y - pressY

                                                            // Threshold: 8px
                                                            if (Math.sqrt(dx*dx + dy*dy) > 8) {
                                                                dragging = true
                                                                overviewRoot._drag.active = true
                                                                overviewRoot._drag.ghostW = windowThumb.width
                                                                overviewRoot._drag.ghostH = windowThumb.height
                                                            }
                                                        }

                                                        if (overviewRoot._drag.active) {
                                                            let rootPos = mapToItem(keyInputLayer, mouse.x, mouse.y)
                                                            overviewRoot._drag.ghostX = rootPos.x - windowThumb.width / 2
                                                            overviewRoot._drag.ghostY = rootPos.y - windowThumb.height / 2

                                                            // Detect destination cell
                                                            overviewRoot._drag.dstVdesk = overviewPanel.cellAtPoint(rootPos.x, rootPos.y)
                                                        }
                                                    }

                                                    onReleased: {
                                                        if (!overviewRoot._drag.active) {
                                                            // Just a click - do nothing or select
                                                            overviewRoot._drag.addr = ""
                                                            return
                                                        }

                                                        // Drop action
                                                        if (overviewRoot._drag.dstVdesk !== overviewRoot._drag.srcVdesk && overviewRoot._drag.dstVdesk > 0) {
                                                            // Move to different vdesk
                                                            VDeskHelper.moveWindowToDesk(overviewRoot._drag.addr, overviewRoot._drag.dstVdesk)
                                                        } else if (overviewRoot._drag.dstVdesk === overviewRoot._drag.srcVdesk) {
                                                            // Reposition within same vdesk
                                                            let newX = Math.floor(overviewRoot._drag.originalX + (overviewRoot._drag.ghostX - overviewRoot._drag.startX) / gridContainer._scale)
                                                            let newY = Math.floor(overviewRoot._drag.originalY + (overviewRoot._drag.ghostY - overviewRoot._drag.startY) / gridContainer._scale)

                                                            Hyprland.dispatch(
                                                                "movewindowpixel exact " + newX + " " + newY +
                                                                ",address:" + overviewRoot._drag.addr
                                                            )
                                                        }

                                                        // Reset drag state
                                                        overviewRoot._drag.active = false
                                                        overviewRoot._drag.addr = ""
                                                        overviewRoot._drag.dstVdesk = 0
                                                        dragging = false

                                                        overviewRoot.fetchRequested = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Footer
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Theme.tagline
                    font.family: Theme.fontMono
                    font.pixelSize: 7
                    font.letterSpacing: 1
                    color: Theme.textMuted
                }
            }
        }

        // ═══ GHOST ITEM (DRAG OVERLAY) ═══
        Rectangle {
            id: ghostItem
            visible: overviewRoot._drag.active
            x: overviewRoot._drag.ghostX
            y: overviewRoot._drag.ghostY
            width: overviewRoot._drag.ghostW
            height: overviewRoot._drag.ghostH
            color: Theme.lambda
            opacity: 0.75
            radius: 2
            z: 999

            border.width: 2
            border.color: Theme.lambdaLight

            Text {
                anchors.centerIn: parent
                text: "↻"
                font.family: Theme.fontMono
                font.pixelSize: 20
                color: Theme.accentText
            }
        }
    }

}
