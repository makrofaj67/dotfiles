import QtQuick
import "../.."

Item {
    id: root

    required property var windowData
    required property int windowIndex
    required property int vdeskNum
    required property real viewScale
    required property real contentWidth
    required property real contentHeight
    required property Item mapTarget
    required property var dragState
    required property var resizeState
    required property var cellAtPointFn

    signal requestMoveToDesk(string address, int dstVdesk)
    signal requestMoveInDesk(string address, int x, int y)
    signal requestResize(string address, real width, real height)
    signal requestRefresh()

    readonly property bool hasGeometry: !!(
        root.windowData && (
            root.windowData.hasGeometry ||
            ((root.windowData.width || 0) > 0 && (root.windowData.height || 0) > 0)
        )
    )
    readonly property real stackOffsetX: hasGeometry ? ((windowIndex % 4) * 5) : 0
    readonly property real stackOffsetY: hasGeometry ? ((windowIndex % 4) * 3) : 0
    readonly property real geomX: (root.windowData && root.windowData.renderX !== undefined) ? root.windowData.renderX : (root.windowData ? root.windowData.x : 0)
    readonly property real geomY: (root.windowData && root.windowData.renderY !== undefined) ? root.windowData.renderY : (root.windowData ? root.windowData.y : 0)
    readonly property real geomW: (root.windowData && root.windowData.renderWidth !== undefined) ? root.windowData.renderWidth : (root.windowData ? root.windowData.width : 0)
    readonly property real geomH: (root.windowData && root.windowData.renderHeight !== undefined) ? root.windowData.renderHeight : (root.windowData ? root.windowData.height : 0)
    readonly property string windowAddress: root.windowData && root.windowData.address ? String(root.windowData.address) : ""
    readonly property string windowClass: root.windowData && root.windowData.class ? String(root.windowData.class) : "window"
    readonly property bool canDispatch: windowAddress.length > 0

    property real scaledX: hasGeometry ? (geomX * viewScale + stackOffsetX) : 0
    property real scaledY: hasGeometry ? (geomY * viewScale + stackOffsetY) : 0
    property real scaledW: hasGeometry ? Math.max(24, geomW * viewScale) : (contentWidth - 4)
    property real scaledH: hasGeometry ? Math.max(14, geomH * viewScale) : 16

    x: hasGeometry
        ? Math.min(Math.max(0, scaledX), Math.max(0, contentWidth - 24))
        : 2
    y: hasGeometry
        ? Math.min(Math.max(0, scaledY), Math.max(0, contentHeight - 14))
        : (windowIndex * 18)
    width: hasGeometry
        ? Math.max(24, Math.min(scaledW, contentWidth - x))
        : Math.max(24, contentWidth - 4)
    height: hasGeometry
        ? Math.max(14, Math.min(scaledH, contentHeight - y))
        : 16
    implicitWidth: width
    implicitHeight: height

    Rectangle {
        id: thumbRect
        anchors.fill: parent
        color: Theme.cellBackground
        border.width: 1
        border.color: Theme.lambda
        radius: 2
        opacity: root.dragState.active && root.dragState.addr === root.windowAddress ? 0.3 : 1.0

        Behavior on opacity { NumberAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            text: root.windowClass
            font.family: Theme.fontMono
            font.pixelSize: 8
            color: Theme.text
            elide: Text.ElideRight
            width: parent.width - 4
            horizontalAlignment: Text.AlignHCenter
        }

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
                    if (!root.canDispatch)
                        return

                    startX = mouse.x
                    startY = mouse.y
                    root.resizeState.active = true
                    root.resizeState.addr = root.windowAddress
                    root.resizeState.vdesk = root.vdeskNum
                    root.resizeState.startX = mouse.x
                    root.resizeState.startY = mouse.y
                    root.resizeState.startW = root.windowData.width || 100
                    root.resizeState.startH = root.windowData.height || 100
                    root.resizeState.currentW = root.windowData.width || 100
                    root.resizeState.currentH = root.windowData.height || 100
                }

                onPositionChanged: (mouse) => {
                    if (root.resizeState.active) {
                        let deltaX = mouse.x - startX
                        let deltaY = mouse.y - startY
                        let deltaRealX = deltaX / root.viewScale
                        let deltaRealY = deltaY / root.viewScale

                        root.resizeState.currentW = Math.max(60, root.resizeState.startW + deltaRealX)
                        root.resizeState.currentH = Math.max(40, root.resizeState.startH + deltaRealY)
                    }
                }

                onReleased: {
                    if (root.resizeState.active) {
                        root.requestResize(root.resizeState.addr, root.resizeState.currentW, root.resizeState.currentH)
                        root.resizeState.active = false
                        root.requestRefresh()
                    }
                }
            }
        }

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
            enabled: root.canDispatch

            onPressed: (mouse) => {
                if (!root.windowData)
                    return

                let rootPos = mapToItem(root.mapTarget, mouse.x, mouse.y)
                pressX = rootPos.x
                pressY = rootPos.y
                dragging = false

                root.dragState.startX = rootPos.x
                root.dragState.startY = rootPos.y
                root.dragState.addr = root.windowAddress
                root.dragState.srcVdesk = root.vdeskNum
                root.dragState.originalX = root.windowData.x
                root.dragState.originalY = root.windowData.y
                root.dragState.originalW = root.windowData.width
                root.dragState.originalH = root.windowData.height
            }

            onPositionChanged: (mouse) => {
                if (!root.dragState.active && !dragging) {
                    let rootPos = mapToItem(root.mapTarget, mouse.x, mouse.y)
                    let dx = rootPos.x - pressX
                    let dy = rootPos.y - pressY

                    if (Math.sqrt(dx * dx + dy * dy) > 8) {
                        dragging = true
                        root.dragState.active = true
                        root.dragState.ghostW = root.width
                        root.dragState.ghostH = root.height
                    }
                }

                if (root.dragState.active) {
                    let rootPos = mapToItem(root.mapTarget, mouse.x, mouse.y)
                    root.dragState.ghostX = rootPos.x - root.width / 2
                    root.dragState.ghostY = rootPos.y - root.height / 2
                    root.dragState.dstVdesk = root.cellAtPointFn(rootPos.x, rootPos.y)
                }
            }

            onReleased: {
                if (!root.dragState.active) {
                    root.dragState.addr = ""
                    return
                }

                if (root.dragState.dstVdesk !== root.dragState.srcVdesk && root.dragState.dstVdesk > 0) {
                    root.requestMoveToDesk(root.dragState.addr, root.dragState.dstVdesk)
                } else if (root.dragState.dstVdesk === root.dragState.srcVdesk) {
                    let newX = Math.floor(root.dragState.originalX + (root.dragState.ghostX - root.dragState.startX) / root.viewScale)
                    let newY = Math.floor(root.dragState.originalY + (root.dragState.ghostY - root.dragState.startY) / root.viewScale)
                    root.requestMoveInDesk(root.dragState.addr, newX, newY)
                }

                root.dragState.active = false
                root.dragState.addr = ""
                root.dragState.dstVdesk = 0
                dragging = false
                root.requestRefresh()
            }
        }
    }
}
