pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."

Singleton {
    id: notifManager

    property bool dndEnabled: false
    property int dndRemainingSeconds: 0
    property string dndDurationLabel: "Off"
    property var popups: []
    property var historyList: []
    property var collapsedGroups: ({})
    property int unreadCount: 0
    property bool isCenterVisible: false
    property bool isGroupedView: true
    property string searchQuery: ""
    property var configRules: ({ "enableSound": true, "rules": [] })

    // DND Countdown Timer
    Timer {
        interval: 1000
        repeat: true
        running: notifManager.dndEnabled && notifManager.dndRemainingSeconds > 0
        onTriggered: {
            notifManager.dndRemainingSeconds = notifManager.dndRemainingSeconds - 1;
            if (notifManager.dndRemainingSeconds <= 0) {
                notifManager.dndEnabled = false;
                notifManager.dndDurationLabel = "Off";
            }
        }
    }

    function setDndMode(minutes, label) {
        if (minutes === 0) {
            dndEnabled = false;
            dndRemainingSeconds = 0;
            dndDurationLabel = "Off";
        } else if (minutes === -1) {
            dndEnabled = true;
            dndRemainingSeconds = 0;
            dndDurationLabel = "Infinite";
        } else {
            dndEnabled = true;
            dndRemainingSeconds = minutes * 60;
            dndDurationLabel = label || (minutes + "m");
        }
    }

    function getDndStatusString() {
        if (!dndEnabled) return "";
        if (dndRemainingSeconds > 0) {
            var mins = Math.floor(dndRemainingSeconds / 60);
            var secs = dndRemainingSeconds % 60;
            return "DND: " + mins + "m " + (secs < 10 ? "0" : "") + secs + "s left";
        }
        return "DND: Active (Infinite)";
    }

    property int rulesVersion: 0

    // Rules loader process
    Process {
        id: rulesProc
        command: ["cat", "/home/rakman/.config/quickshell/notifications/rules.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text && text.trim()) {
                        notifManager.configRules = JSON.parse(text.trim());
                        notifManager.rulesVersion++;
                    }
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
    }

    function saveRulesToFile() {
        try {
            var jsonStr = JSON.stringify(notifManager.configRules, null, 2);
            var p = Qt.createQmlObject('import Quickshell.Io; Process { }', notifManager);
            p.command = ["sh", "-c", "cat << 'EOF' > /home/rakman/.config/quickshell/notifications/rules.json\n" + jsonStr + "\nEOF"];
            p.running = true;
        } catch(e) {}
    }

    function setAppRule(appName, settings) {
        var rules = (notifManager.configRules && notifManager.configRules.rules) ? notifManager.configRules.rules.slice() : [];
        var found = false;
        for (var i = 0; i < rules.length; i++) {
            if (rules[i].matchApp && rules[i].matchApp.toLowerCase() === appName.toLowerCase()) {
                rules[i] = Object.assign({}, rules[i], settings);
                found = true;
                break;
            }
        }
        if (!found) {
            var newRule = Object.assign({ matchApp: appName }, settings);
            rules.push(newRule);
        }
        notifManager.configRules = Object.assign({}, notifManager.configRules, { rules: rules });
        notifManager.rulesVersion++;
        saveRulesToFile();
    }

    function getAppRule(appName) {
        if (!notifManager.configRules || !notifManager.configRules.rules) return null;
        for (var i = 0; i < notifManager.configRules.rules.length; i++) {
            var r = notifManager.configRules.rules[i];
            if (r.matchApp && r.matchApp.toLowerCase() === appName.toLowerCase()) {
                return r;
            }
        }
        return null;
    }

    // Background Package Update Checker (yay -Qu)
    property int pendingUpdatesCount: 0
    property var pendingUpdatesList: []

    Process {
        id: updateCheckProc
        command: ["sh", "-c", "yay -Qu 2>/dev/null"]
        stdout: SplitParser {
            onRead: data => {
                if (data && data.trim()) {
                    var lines = data.trim().split("\n").filter(l => l.trim().length > 0);
                    notifManager.pendingUpdatesCount = lines.length;
                    notifManager.pendingUpdatesList = lines;
                    if (lines.length > 0) {
                        notifManager.dispatchUpdateNotification(lines.length);
                    }
                }
            }
        }
    }

    Timer {
        id: updateTimer
        interval: 7200000 // 2 hours
        repeat: true
        running: true
        onTriggered: updateCheckProc.running = true
    }

    Timer {
        id: startupUpdateTimer
        interval: 10000 // 10 seconds after startup
        running: true
        repeat: false
        onTriggered: updateCheckProc.running = true
    }

    function dispatchUpdateNotification(count) {
        var notif = {
            id: 999901,
            appName: "Pacman",
            appIcon: "",
            glyph: "󰏖",
            summary: "System Updates Available",
            body: "<b>" + count + "</b> package updates are ready to install.",
            image: "",
            urgency: 1,
            isPersistent: false,
            progress: -1,
            time: Qt.formatDateTime(new Date(), "HH:mm"),
            hasInlineReply: false,
            actions: [
                {
                    identifier: "update",
                    text: "Update Now",
                    actionRef: {
                        invoke: () => {
                            runHook("kitty -e yay -Syu");
                        }
                    }
                },
                {
                    identifier: "view",
                    text: "View List",
                    actionRef: {
                        invoke: () => {
                            runHook("kitty -e sh -c 'yay -Qu; echo \"\"; read -p \"Press Enter to close...\"'");
                        }
                    }
                }
            ],
            rawNotif: null
        };
        pushPopup(notif);
        var h = historyList.slice();
        // Remove existing update notification if present
        for (var i = h.length - 1; i >= 0; i--) {
            if (h[i].id === 999901) h.splice(i, 1);
        }
        h.unshift(notif);
        historyList = h;
    }

    NotificationServer {
        id: server
        keepOnReload: false
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: (notification) => {
            var app = notification.appName || "System";
            var sum = notification.summary || "";
            var bod = notification.body || "";
            var urg = notification.urgency !== undefined ? notification.urgency : 1;
            var isSilent = false;
            var isBlocked = false;
            var customHook = "";

            // Check custom rules engine
            if (notifManager.configRules && notifManager.configRules.rules) {
                for (var r = 0; r < notifManager.configRules.rules.length; r++) {
                    var rule = notifManager.configRules.rules[r];
                    var matchesApp = rule.matchApp && app.toLowerCase().indexOf(rule.matchApp.toLowerCase()) !== -1;
                    var matchesSummary = rule.matchSummaryRegex && (new RegExp(rule.matchSummaryRegex, "i")).test(sum);
                    var matchesBody = rule.matchBodyRegex && (new RegExp(rule.matchBodyRegex, "i")).test(bod);

                    if (matchesApp || matchesSummary || matchesBody) {
                        if (rule.block) { isBlocked = true; break; }
                        if (rule.silent) isSilent = true;
                        if (rule.setUrgency !== undefined) urg = rule.setUrgency;
                        if (rule.hookCmd) customHook = rule.hookCmd;
                    }
                }
            }

            if (isBlocked) return;

            // Extract Progress hint if provided
            var progressVal = -1;
            if (notification.hints) {
                if (notification.hints["value"] !== undefined) {
                    progressVal = parseInt(notification.hints["value"]);
                } else if (notification.hints["percentage"] !== undefined) {
                    progressVal = parseInt(notification.hints["percentage"]);
                }
            }

            // Extract actions
            var actList = [];
            if (notification.actions) {
                for (var i = 0; i < notification.actions.length; i++) {
                    var a = notification.actions[i];
                    actList.push({
                        identifier: a.identifier || "",
                        text: a.text || "Action",
                        actionRef: a
                    });
                }
            }

            var d = new Date();
            var hours = d.getHours();
            var mins = d.getMinutes();
            var timeStr = (hours < 10 ? "0" + hours : hours) + ":" + (mins < 10 ? "0" + mins : mins);

            // Contextual glyph mapping
            var glyph = getContextualGlyph(app, sum);

            var item = {
                id: notification.id || Date.now(),
                appName: app,
                appIcon: notification.appIcon || "",
                glyph: glyph,
                summary: sum,
                body: bod,
                image: notification.image || "",
                urgency: urg,
                isPersistent: (urg === 2),
                progress: progressVal,
                time: timeStr,
                hasInlineReply: notification.hasInlineReply || false,
                inlineReplyPlaceholder: notification.inlineReplyPlaceholder || "Type a reply...",
                actions: actList,
                rawNotif: notification
            };

            // 1. Record in History (newest on top)
            var h = notifManager.historyList.slice();
            h.unshift(item);
            if (h.length > 100) {
                h.pop();
            }
            notifManager.historyList = h;

            // 2. Push to Toast Popups if not DND and not silent
            if (!notifManager.dndEnabled && !isSilent) {
                notifManager.pushPopup(item);
            }

            // 3. Sound / Scriptable Hooks
            if (urg === 2 && notifManager.configRules && notifManager.configRules.enableSound && notifManager.configRules.criticalSoundCommand) {
                runHook(notifManager.configRules.criticalSoundCommand);
            }
            if (customHook.length > 0) {
                runHook(customHook);
            }

            notifManager.unreadCount = notifManager.unreadCount + 1;
        }
    }

    function runHook(cmd) {
        try {
            var p = Qt.createQmlObject('import Quickshell.Io; Process { }', notifManager);
            p.command = ["sh", "-c", cmd];
            p.running = true;
        } catch(e) {}
    }

    function getContextualGlyph(appName, summary) {
        var str = (appName + " " + summary).toLowerCase();
        if (str.indexOf("spotify") !== -1 || str.indexOf("music") !== -1 || str.indexOf("vlc") !== -1 || str.indexOf("audio") !== -1) return "󰝚";
        if (str.indexOf("discord") !== -1 || str.indexOf("telegram") !== -1 || str.indexOf("slack") !== -1 || str.indexOf("chat") !== -1) return "󰭹";
        if (str.indexOf("pacman") !== -1 || str.indexOf("update") !== -1 || str.indexOf("system") !== -1 || str.indexOf("package") !== -1) return "󰏖";
        if (str.indexOf("battery") !== -1 || str.indexOf("power") !== -1 || str.indexOf("charge") !== -1) return "󰁹";
        if (str.indexOf("wifi") !== -1 || str.indexOf("network") !== -1 || str.indexOf("bluetooth") !== -1) return "󰖩";
        if (str.indexOf("download") !== -1 || str.indexOf("file") !== -1) return "󰇚";
        if (str.indexOf("firefox") !== -1 || str.indexOf("chrome") !== -1 || str.indexOf("browser") !== -1) return "󰈹";
        if (str.indexOf("terminal") !== -1 || str.indexOf("bash") !== -1 || str.indexOf("alacritty") !== -1 || str.indexOf("kitty") !== -1) return "󰞷";
        return "󰂚";
    }

    // Filtered history according to search query
    readonly property var filteredHistory: {
        var q = searchQuery.trim().toLowerCase();
        if (q.length === 0) return historyList;
        return historyList.filter(item => {
            var app = (item.appName || "").toLowerCase();
            var sum = (item.summary || "").toLowerCase();
            var bod = (item.body || "").toLowerCase();
            return app.indexOf(q) !== -1 || sum.indexOf(q) !== -1 || bod.indexOf(q) !== -1;
        });
    }

    // Filtered grouped list
    readonly property var groupedHistory: {
        var groups = [];
        var groupMap = {};
        var list = filteredHistory;

        for (var i = 0; i < list.length; i++) {
            var item = list[i];
            var app = item.appName || "System";
            if (!groupMap[app]) {
                groupMap[app] = {
                    appName: app,
                    appIcon: item.appIcon || "",
                    glyph: item.glyph || "󰂚",
                    items: [],
                    isCollapsed: !!collapsedGroups[app]
                };
                groups.push(groupMap[app]);
            }
            groupMap[app].items.push(item);
        }
        return groups;
    }

    function toggleGroupCollapse(appName) {
        var map = Object.assign({}, collapsedGroups);
        map[appName] = !map[appName];
        collapsedGroups = map;
    }

    function pushPopup(item) {
        var arr = popups.slice();
        for (var i = arr.length - 1; i >= 0; i--) {
            if (arr[i].id === item.id) {
                arr.splice(i, 1);
            }
        }
        arr.push(item);
        if (arr.length > 5) {
            arr.shift();
        }
        popups = arr;
    }

    function removePopup(id) {
        var arr = popups.slice();
        for (var i = arr.length - 1; i >= 0; i--) {
            if (arr[i].id === id) {
                arr.splice(i, 1);
                break;
            }
        }
        popups = arr;
    }

    function removeHistory(id) {
        var arr = historyList.slice();
        for (var i = arr.length - 1; i >= 0; i--) {
            if (arr[i].id === id) {
                arr.splice(i, 1);
                break;
            }
        }
        historyList = arr;
        removePopup(id);
    }

    function clearAppGroup(appName) {
        var arr = [];
        for (var i = 0; i < historyList.length; i++) {
            if (historyList[i].appName !== appName) {
                arr.push(historyList[i]);
            } else {
                removePopup(historyList[i].id);
            }
        }
        historyList = arr;
    }

    function clearAll() {
        popups = [];
        historyList = [];
        collapsedGroups = ({});
        unreadCount = 0;
    }

    function toggleCenter() {
        isCenterVisible = !isCenterVisible;
        if (isCenterVisible) {
            unreadCount = 0;
            searchQuery = "";
        }
    }
}
