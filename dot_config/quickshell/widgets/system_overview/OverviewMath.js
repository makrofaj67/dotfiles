function workspaceToVdesk(workspace, monitorCount) {
    if (!workspace)
        return -1

    const name = String(workspace.name || "")
    const gridMatch = name.match(/Grid-(\d+)/)
    if (gridMatch)
        return parseInt(gridMatch[1])

    let wsId = Number(workspace.id)
    if (isNaN(wsId) || wsId < 1) {
        const parsedFromName = parseInt(name)
        if (!isNaN(parsedFromName) && parsedFromName >= 1)
            wsId = parsedFromName
        else
            return -1
    }

    return Math.floor((wsId - 1) / monitorCount) + 1
}

function initialGrouped() {
    const grouped = {}
    for (let i = 1; i <= 9; i++)
        grouped[i] = []
    return grouped
}

function detectOverlapKey(win) {
    return [
        Math.round((win.renderX || 0) / 20),
        Math.round((win.renderY || 0) / 20),
        Math.round((win.renderWidth || 0) / 20),
        Math.round((win.renderHeight || 0) / 20)
    ].join(":")
}

function applyOverlapFallback(grouped, referenceMonitorWidth, referenceMonitorHeight) {
    for (let vd = 1; vd <= 9; vd++) {
        const list = grouped[vd]
        if (!list || list.length <= 1)
            continue

        const geometryKeys = {}
        let uniqueCount = 0

        for (let i = 0; i < list.length; i++) {
            const key = detectOverlapKey(list[i])
            if (!geometryKeys[key]) {
                geometryKeys[key] = true
                uniqueCount++
            }
        }

        const overlapLikely = uniqueCount <= Math.ceil(list.length / 2)
        if (!overlapLikely)
            continue

        const cols = list.length >= 4 ? 2 : 1
        const rows = Math.ceil(list.length / cols)

        const canvasW = Math.max(800, Math.floor(referenceMonitorWidth * 0.92))
        const canvasH = Math.max(420, Math.floor(referenceMonitorHeight * 0.82))
        const gapX = 50
        const gapY = 42
        const tileW = Math.max(260, Math.floor((canvasW - gapX * (cols + 1)) / cols))
        const tileH = Math.max(120, Math.floor((canvasH - gapY * (rows + 1)) / rows))

        for (let i = 0; i < list.length; i++) {
            const col = i % cols
            const row = Math.floor(i / cols)
            list[i].renderX = gapX + col * (tileW + gapX)
            list[i].renderY = gapY + row * (tileH + gapY)
            list[i].renderWidth = tileW
            list[i].renderHeight = tileH
        }
    }
}

function mapClientToWindow(client, index, monitorCount) {
    const hasGeometry = !!(client.at && client.size)
    const rawX = hasGeometry ? client.at[0] : 20
    const rawY = hasGeometry ? client.at[1] : (index % 5) * 24
    const rawW = hasGeometry ? client.size[0] : 360
    const rawH = hasGeometry ? client.size[1] : 120

    const horizontalCompression = monitorCount > 1 ? monitorCount : 1
    const renderX = hasGeometry ? (rawX / horizontalCompression) : rawX
    const renderW = hasGeometry ? Math.max(80, rawW / horizontalCompression) : rawW

    return {
        address: client.address,
        title: client.title || "Untitled",
        class: client.class || "unknown",
        hasGeometry: hasGeometry,
        x: rawX,
        y: rawY,
        width: rawW,
        height: rawH,
        renderX: renderX,
        renderY: rawY,
        renderWidth: renderW,
        renderHeight: rawH,
        workspace: client.workspace ? client.workspace.name : ""
    }
}

function buildWindowsByVdesk(allClients, monitorCount, referenceMonitorWidth, referenceMonitorHeight) {
    const grouped = initialGrouped()

    for (let i = 0; i < allClients.length; i++) {
        const client = allClients[i]

        let vd = -1
        if (client.vdesk !== undefined)
            vd = parseInt(client.vdesk)
        else if (client.workspace)
            vd = workspaceToVdesk(client.workspace, monitorCount)

        if (vd < 1 || vd > 9)
            continue

        const mapped = mapClientToWindow(client, i, monitorCount)
        if (!mapped.workspace)
            mapped.workspace = "vdesk-" + vd

        grouped[vd].push(mapped)
    }

    applyOverlapFallback(grouped, referenceMonitorWidth, referenceMonitorHeight)
    return grouped
}
