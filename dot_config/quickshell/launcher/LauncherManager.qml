pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: lm

    property bool isOpen: false
    property string searchQuery: ""
    property var allApps: []
    property var clipboardHistory: []
    property int selectedIndex: 0

    // Load applications on startup
    Process {
        id: appScanner
        command: ["/home/rakman/.config/quickshell/launcher/scan-apps.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text && text.trim()) {
                        lm.allApps = JSON.parse(text.trim());
                    }
                } catch(e) {}
            }
        }
        Component.onCompleted: running = true
    }

    // Fetch clipboard history from CopyQ
    Process {
        id: clipboardFetcher
        command: ["copyq", "eval", "var res=[]; for(var i=0; i<Math.min(35, count()); ++i){ var t=str(read(i)); if(t&&t.length>0) res.push({ index: i, text: t }); } JSON.stringify(res);"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text && text.trim()) {
                        lm.clipboardHistory = JSON.parse(text.trim());
                    }
                } catch(e) {}
            }
        }
    }

    function rescan() {
        appScanner.running = false;
        appScanner.running = true;
    }

    function fetchClipboard() {
        clipboardFetcher.running = false;
        clipboardFetcher.running = true;
    }

    function open() {
        searchQuery = "";
        selectedIndex = 0;
        isOpen = true;
        rescan();
        fetchClipboard();
    }

    function close() {
        isOpen = false;
        searchQuery = "";
        selectedIndex = 0;
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function runCmd(cmd) {
        try {
            var p = Qt.createQmlObject('import Quickshell.Io; Process { }', lm);
            p.command = ["sh", "-c", cmd];
            p.running = true;
        } catch(e) {}
    }

    function copyToClipboard(text) {
        try {
            var p = Qt.createQmlObject('import Quickshell.Io; Process { }', lm);
            p.command = ["sh", "-c", "echo -n '" + text.toString().replace(/'/g, "'\\''") + "' | wl-copy"];
            p.running = true;
        } catch(e) {}
    }

    // Mathematical expression evaluator
    function tryEvaluateMath(expr) {
        if (!expr || expr.trim().length === 0) return null;
        var clean = expr.trim().replace(/\^/g, "**");
        // Only allow digits, operators, parens, decimal dots, and Math functions
        if (/^[0-9\.\+\-\*\/\(\)\s\%\^]|Math\.[a-z]+/i.test(clean)) {
            // Must contain at least one operator or function
            if (/[\+\-\*\/\%\^]|Math\./i.test(clean) && /[0-9]/.test(clean)) {
                try {
                    // Safe evaluation
                    var res = Function('"use strict"; return (' + clean + ')')();
                    if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
                        // Round nicely if long float
                        var formatted = (Math.round(res * 100000) / 100000).toString();
                        return formatted;
                    }
                } catch(e) {}
            }
        }
        return null;
    }

    // System commands catalog
    readonly property var systemCommands: [
        {
            keywords: ["lock", "hyprlock", "screen lock"],
            name: "Lock Screen",
            comment: "Lock the current session",
            iconGlyph: "󰌾",
            exec: "loginctl lock-session"
        },
        {
            keywords: ["reboot", "restart", "system restart"],
            name: "Restart Computer",
            comment: "Reboot system",
            iconGlyph: "󰜉",
            exec: "systemctl reboot"
        },
        {
            keywords: ["shutdown", "power off", "turn off", "poweroff", "halt"],
            name: "Shut Down",
            comment: "Power off computer",
            iconGlyph: "󰐥",
            exec: "systemctl poweroff"
        },
        {
            keywords: ["suspend", "sleep"],
            name: "Suspend / Sleep",
            comment: "Put computer to sleep",
            iconGlyph: "󰤄",
            exec: "systemctl suspend"
        },
        {
            keywords: ["logout", "exit", "quit"],
            name: "Log Out",
            comment: "Exit Hyprland session",
            iconGlyph: "󰈆",
            exec: "hyprctl dispatch exit"
        }
    ]

    // Filtered Results List (Apps + Clipboard + Math + System Commands + Web Search)
    readonly property var filteredResults: {
        var rawQuery = searchQuery.trim();
        var q = rawQuery.toLowerCase();
        var results = [];

        // 1. Clipboard History Mode (`cl` or `@` prefix)
        if (q === "cl" || q.startsWith("cl ") || q === "@" || q.startsWith("@ ") || q.startsWith("@")) {
            var clipTerm = "";
            if (q.startsWith("cl ")) clipTerm = q.substring(3).trim();
            else if (q === "cl") clipTerm = "";
            else if (q.startsWith("@ ")) clipTerm = q.substring(2).trim();
            else if (q.startsWith("@")) clipTerm = q.substring(1).trim();

            for (var c = 0; c < clipboardHistory.length; c++) {
                var entry = clipboardHistory[c];
                var rawText = entry.text || "";
                if (clipTerm.length === 0 || rawText.toLowerCase().indexOf(clipTerm) !== -1) {
                    var lines = rawText.trim().split("\n");
                    var firstLine = (lines[0] || "").trim();
                    if (firstLine.length > 65) firstLine = firstLine.substring(0, 65) + "...";
                    if (firstLine.length === 0) firstLine = "(Empty / Whitespace)";
                    
                    var commentInfo = lines.length > 1 
                        ? (lines.length + " lines | " + lines.slice(1).join(" ").trim().substring(0, 50) + "...") 
                        : ("Item #" + (entry.index + 1) + " (" + rawText.length + " chars)");

                    results.push({
                        type: "clipboard",
                        name: firstLine,
                        comment: commentInfo,
                        icon: "",
                        iconGlyph: "󰅍",
                        fullText: rawText,
                        clipboardIndex: entry.index,
                        exec: ""
                    });
                }
            }
            return results;
        }

        // 2. Math Evaluation
        var mathRes = tryEvaluateMath(rawQuery);
        if (mathRes !== null) {
            results.push({
                type: "math",
                name: "= " + mathRes,
                comment: "Press Enter to copy result to clipboard",
                icon: "",
                iconGlyph: "󰪚",
                resultVal: mathRes,
                exec: ""
            });
        }

        if (q.length === 0) {
            // Show all apps
            return results.concat(allApps);
        }

        // 3. Web Search trigger (? or g query)
        if (q.startsWith("? ") || q.startsWith("g ") || q.startsWith("gh ")) {
            var searchEngine = "Google";
            var url = "https://google.com/search?q=";
            var term = rawQuery.substring(2).trim();
            if (q.startsWith("gh ")) {
                searchEngine = "GitHub";
                url = "https://github.com/search?q=";
                term = rawQuery.substring(3).trim();
            }
            if (term.length > 0) {
                results.push({
                    type: "web",
                    name: "Search " + searchEngine + ": \"" + term + "\"",
                    comment: "Open in default browser",
                    icon: "",
                    iconGlyph: "󰊯",
                    exec: "xdg-open '" + url + encodeURIComponent(term) + "'"
                });
            }
        }

        // 4. System Actions
        for (var s = 0; s < systemCommands.length; s++) {
            var sys = systemCommands[s];
            var matched = false;
            for (var k = 0; k < sys.keywords.length; k++) {
                if (sys.keywords[k].indexOf(q) !== -1 || q.indexOf(sys.keywords[k]) !== -1) {
                    matched = true;
                    break;
                }
            }
            if (matched) {
                results.push({
                    type: "system",
                    name: sys.name,
                    comment: sys.comment,
                    icon: "",
                    iconGlyph: sys.iconGlyph,
                    exec: sys.exec
                });
            }
        }

        // 5. App Fuzzy Search (Prioritize exact prefix, then substring)
        var exactPrefixMatches = [];
        var substringMatches = [];

        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i];
            var nameLower = (app.name || "").toLowerCase();
            var execLower = (app.exec || "").toLowerCase();
            var commentLower = (app.comment || "").toLowerCase();
            var kwLower = (app.keywords || "").toLowerCase();

            if (nameLower.startsWith(q)) {
                exactPrefixMatches.push(Object.assign({ type: "app" }, app));
            } else if (nameLower.indexOf(q) !== -1 || execLower.indexOf(q) !== -1 || commentLower.indexOf(q) !== -1 || kwLower.indexOf(q) !== -1) {
                substringMatches.push(Object.assign({ type: "app" }, app));
            }
        }

        return results.concat(exactPrefixMatches).concat(substringMatches);
    }

    function launchItem(item) {
        if (!item) return;
        if (item.type === "clipboard") {
            copyToClipboard(item.fullText);
            runCmd("copyq select(" + item.clipboardIndex + ")");
        } else if (item.type === "math") {
            copyToClipboard(item.resultVal);
        } else if (item.exec && item.exec.length > 0) {
            runCmd(item.exec);
        }
        close();
    }
}
