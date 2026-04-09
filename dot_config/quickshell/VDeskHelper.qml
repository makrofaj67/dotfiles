pragma Singleton
import QtQuick
import Quickshell.Io

Item {
    id: vdeskHelper
    visible: false

    // ═══════════════════════════════════════════════════════════
    // VDESK HELPER — Abstraction layer for hyprland-virtual-desktops
    // ═══════════════════════════════════════════════════════════

    signal currentDeskResult(int id)

    property int _switchTargetDesk: 1
    property string _moveTargetAddress: ""
    property int _moveTargetDesk: 1

    Process {
        id: switchDeskProcess
        command: ["hyprctl", "dispatch", "vdesk", String(vdeskHelper._switchTargetDesk)]
        running: false
    }

    Process {
        id: moveDeskProcess
        command: ["hyprctl", "dispatch", "movetodesksilent", String(vdeskHelper._moveTargetDesk) + ",address:" + vdeskHelper._moveTargetAddress]
        running: false
    }

    Process {
        id: getCurrentProcess
        command: ["sh", "-c", "hyprctl printdesk | grep -oP 'desk \\K\\d+' | head -1"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let num = parseInt(data.trim())
                if (num >= 1 && num <= 9) {
                    vdeskHelper.currentDeskResult(num)
                }
            }
        }
    }

    // Switch to a specific vdesk (1-9)
    function switchToDesk(id) {
        if (id < 1 || id > 9) {
            console.warn("VDeskHelper: invalid vdesk id:", id)
            return
        }

        _switchTargetDesk = id
        switchDeskProcess.running = true
    }

    // Move window to a specific vdesk (silent = does not follow)
    function moveWindowToDesk(addr, id) {
        if (id < 1 || id > 9) {
            console.warn("VDeskHelper: invalid vdesk id:", id)
            return
        }
        if (!addr) {
            console.warn("VDeskHelper: missing window address")
            return
        }

        _moveTargetAddress = addr
        _moveTargetDesk = id
        moveDeskProcess.running = true
    }

    // Get current active vdesk
    function getCurrentDesk() {
        getCurrentProcess.running = true
    }
}
