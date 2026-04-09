import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "widgets/top_center"
import "widgets/system_overview"
import "widgets/notepad"
import "widgets/void_terminal"
import "widgets/popup"
import "widgets/hud"
import "."

ShellRoot {
    id: root
    
    // --- STATE YÖNETİMİ ---
    property int activeVdesk: 1
    property var populatedVdesks: ({})
    property var allWindows: []
    property var windowList: [] // Sağ tık menüsü için

    // Popup State
    property int contextVdesk: 0
    property bool popupVisible: false
    property var popupScreen: null
    property real popupX: 0
    property real popupY: 0
    // Overview State
    property bool overviewVisible: false
    
    // --- IPC & EVENTS ---
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Vdesk değişimi
            if (event.name === "vdesk") {
                let num = parseInt(event.data)
                if (num >= 1 && num <= 9) root.activeVdesk = num
            }
            // Pencere olayları (Refresh tetikler)
            if (event.name === "openwindow" || event.name === "closewindow" ||
                event.name === "movewindow" || event.name === "workspace" ||
                event.name === "resizewindow" || event.name === "fullscreen") {
                stateTimer.restart()
                allWindowsProcess.start()
            }
            // Özel toggle eventi
            if (event.name === "custom" && event.data === "toggleOverview") {
                root.toggleOverview()
            }
        }
    }
    
    function toggleOverview() {
        root.overviewVisible = !root.overviewVisible
    }
    
    // Kısayol Tanımı
    GlobalShortcut {
        name: "toggleOverview"
        description: "Toggle Steam Overview"
        onPressed: root.toggleOverview()
    }
    
    // Debounce Timer (Event spam'ini önler)
    Timer {
        id: stateTimer
        interval: 200
        onTriggered: stateProcess.running = true
    }

    // Overview açıkken pencere geometrisini canlı tut.
    Timer {
        id: overviewRefreshTimer
        interval: 300
        repeat: true
        running: root.overviewVisible
        onTriggered: allWindowsProcess.start()
    }
    
    // --- PROCESSLER ---

    // Başlangıçta aktif vdesk'i bul
    Process {
        id: initProcess
        command: ["sh", "-c", "hyprctl printdesk | grep -oP 'desk \\K\\d+' | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let num = parseInt(data.trim())
                if (num >= 1 && num <= 9) root.activeVdesk = num
            }
        }
        onRunningChanged: {
            if (!running) {
                stateProcess.running = true
                allWindowsProcess.start()
            }
        }
    }
    
    // [FIX] Buffer Yönetimi İyileştirilmiş Window Fetcher
    Process {
        id: allWindowsProcess
        command: ["/home/rakman/.config/quickshell/scripts/get_all_windows.sh"]
        running: false
        property string buffer: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => allWindowsProcess.buffer += data
        }
        
        onExited: {
            if (buffer.length > 0) {
                try {
                    root.allWindows = JSON.parse(buffer.trim())
                } catch(e) {
                    console.log("Parse error:", e)
                    root.allWindows = []
                }
            }
            buffer = ""
        }
        
        function start() {
            buffer = ""  // Process başlamadan önce temizle
            running = true
        }
    }
    
    // Pencere Taşıma İşlemi
    Process {
        id: moveToVdeskProcess
        property string targetAddress: ""
        property int targetVdesk: 1
        command: ["hyprctl", "dispatch", "movetodesksilent", targetVdesk + ",address:" + targetAddress]
        running: false
        onRunningChanged: {
            if (!running) {
                // [FIX] Manuel refresh kaldırıldı (Hyprland event'i zaten yapacak)
                console.log("Move completed: " + targetAddress + " -> " + targetVdesk)
                
                // [FIX] Taşıma bitti, seçimi sıfırla
                root.selectedWindowAddress = ""
                root.selectedWindowVdesk = 0
            }
        }
    }
    
    // Yardımcı Fonksiyonlar
    function moveWindowToVdesk(address, vdesk) {
        moveToVdeskProcess.targetAddress = address
        moveToVdeskProcess.targetVdesk = vdesk
        moveToVdeskProcess.running = true
    }
    
    // Hangi vdesklerde pencere var?
    Process {
        id: stateProcess
        command: ["sh", "-c", "hyprctl printstate | grep -B2 'Populated: true' | grep -oP '^- \\K\\d+' | tr '\\n' ','"]
        running: false
        stdout: SplitParser {
            onRead: data => {
                let newPopulated = {}
                let nums = data.trim().split(',')
                for (let n of nums) {
                    let num = parseInt(n)
                    if (num >= 1 && num <= 9) newPopulated[num] = true
                }
                root.populatedVdesks = newPopulated
            }
        }
    }
    
    // showWindowMenu için allWindows'dan filtreleyerek liste oluştur (process spawn yok)
    function getWindowsForVdesk(vdeskNum) {
        return root.allWindows.filter(w => w.vdesk === vdeskNum).map(w => ({
            address: w.address,
            title: w.title,
            class: w.class
        }))
    }
    
    function bringWindowHere(address) {
        Hyprland.dispatch("movetoworkspace current,address:" + address)
        Hyprland.dispatch("focuswindow address:" + address)
        root.popupVisible = false
    }
    
    function isPopulated(vdeskNum) { return populatedVdesks[vdeskNum] === true }
    
    function showWindowMenu(vdeskNum, globalX, globalY, screen) {
        if (!isPopulated(vdeskNum)) return
        root.contextVdesk = vdeskNum
        root.popupX = globalX
        root.popupY = globalY
        root.popupScreen = screen
        root.windowList = getWindowsForVdesk(vdeskNum)
        root.popupVisible = true
    }
    
    // ==========================================================
    // UI: TOP BAR - Modular Component
    // ==========================================================
    TopBar {
        activeVdesk: root.activeVdesk
        populatedVdesks: root.populatedVdesks
        
        onVdeskClicked: (vdeskNum) => Hyprland.dispatch("vdesk " + vdeskNum)
        onVdeskRightClicked: (vdeskNum, globalX, globalY, screen) => root.showWindowMenu(vdeskNum, globalX, globalY, screen)
    }
    
    // ==========================================================
    // UI: SAĞ TIK MENÜSÜ (POPUP) - Modular Component
    // ==========================================================
    WindowPopup {
        visible: root.popupVisible
        contextVdesk: root.contextVdesk
        windowList: root.windowList
        popupScreen: root.popupScreen
        
        onWindowClicked: (address) => root.bringWindowHere(address)
        onDismissed: root.popupVisible = false
    }
    
    // ==========================================================
    // UI: OVERVIEW (3x3 GRID) - Modular Component
    // ==========================================================
    OverviewPanel {
        visible: root.overviewVisible
        activeVdesk: root.activeVdesk
        allWindows: root.allWindows

        onToggleRequested: root.toggleOverview()
        onVdeskActivated: (vdeskNum) => Hyprland.dispatch("vdesk " + vdeskNum)
    }

	LabJournal {}
	HevControl {}
	HevHud {}
}
