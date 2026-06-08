import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets

PanelWindow
{
    id: topBar

    implicitHeight:27
    implicitWidth: 1920
    anchors.top: true
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    // WlrLayershell.exclusiveZone: 0
    
    property var parsedClients: []
    property var parsedWorkspaces: []
    property var parsedMonitors: []

    Process
    {
        id: jsonFetcher
        command: ["sh", "-c", "echo \"{\\\"clients\\\": $(hyprctl clients -j), \\\"workspaces\\\": $(hyprctl workspaces -j), \\\"monitors\\\": $(hyprctl monitors -j)}\""]
        running: true
        stdout: StdioCollector
        {
            onStreamFinished:
            {
                try
                {
                    var data = JSON.parse(text)
                    topBar.parsedClients = data.clients || []
                    topBar.parsedWorkspaces = data.workspaces || []
                    topBar.parsedMonitors = data.monitors || []
                    topBar.rebuildWsCards()
                }
                catch(e)
                {
                    console.log("jsonFetcher JSON Parse Error:", e)
                }
            }
        }
    }

    Process
    {
        id: eventListener
        command: ["sh", "-c", "ncat 127.0.0.1 23456"]
        running: true
        stdout: SplitParser
        {
            splitMarker: "\n"
            onRead: function(data)
            {
                var line = data
                var idx = line.indexOf(">>")
                if (idx !== -1)
                {
                    var eventName = line.substring(0, idx)
                    var data = line.substring(idx + 2)
                    if (["closewindow" ,"openwindow", "movewindow", "destroyworkspace", "createworkspace"].indexOf(eventName) !== -1)
                    {
                        jsonFetcher.running = false
                        jsonFetcher.running = true
                    }
                }
            }
        }
    }

    function rebuildWsCards()
    {
        let i = 0
        while(workspaceButtonsRow.children.length > i)
        {
            workspaceButtonsRow.children[i].destroy()
            i++
        }

        i = 0
        while (topBar.parsedWorkspaces.length > i)
        {
            workspaceButtonComponent.createObject(workspaceButtonsRow, {
                    workspaceid: topBar.parsedWorkspaces[i]["id"],
                    allClients: topBar.parsedClients
                })
            i++
        }
    }

    Row
    {
        id: workspaceButtonsRow

        spacing: 5
        anchors.centerIn: parent

    }

    Rectangle
    {
        id: dateTime

        height: 26
        width: 210
        radius: 4

        property var dateString: null
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 5
        color: Theme.base
        border.color: Theme.border 
        
        Component
        {
            id: dateComponent

            Text
            {
                id: dateText
                anchors.centerIn: parent
                text: dateTime.dateString
                color: Theme.text
                font.pixelSize: 14
                topPadding: 4
                font.family: "Hack"
            }
        }

        Timer
        {
            running: true
            repeat: true
            interval: 1000
            onTriggered:
            {
                clockWatcher.running = true
            }
        }

        function ticktock()
        {
            let i = 0
            
            while(dateTime.children.length > i)
            {
                dateComponent.children[i].destroy()
                i++
            }
            dateComponent.createObject(dateTime, {

            })
        }

        Process
        {
            id: clockWatcher
            command: ["sh", "-c", "date '+[%u] %x %R:%S'"]
            stdout: StdioCollector
            {
                onStreamFinished:
                {
                    try
                    {
                        dateTime.dateString = text
                        dateTime.ticktock()
                    }
                    catch(e)
                    {
                        // console.log("date fetch problem", e)
                    }
                }
            }
        }
    }

    Rectangle
    {
        anchors.right: parent.right
        y: 6
        color: Theme.border
        height: 19
        width: children[0].width + 10
        anchors.rightMargin: 5

        radius: 10

        Slider
        {
            id: brightnessSlider
            anchors.centerIn: parent

            width: 120
            height: 26
            from: 0
            to: 64764
            stepSize: 648
            onMoved:
            {
                setBrightness.running = true
            }

            Process
            {
                id: getBrightness
                command: ["sh", "-c", "brightnessctl get"]
                running: true
                stdout: StdioCollector
                {
                    onStreamFinished:
                    {
                        try
                        {   
                            var data = text
                            brightnessSlider.value = data
                        }
                        catch (e)
                        {
                            // console.log(e)
                        }
                    }
                }
            }

            function setBrightnessJS()
            {
                
            }

            Process
            {
                id: setBrightness
                command: ["sh", "-c", "brightnessctl set " + brightnessSlider.value]
                running: false
                stdout: StdioCollector
                {
                    onStreamFinished:
                    {
                        try
                        {   
                            // console.log(setBrightness.command)
                        }
                        catch (e)
                        {
                            console.log(e)
                        }
                    }
                }

            }
        }
    }

    Component
    {
        id: workspaceButtonComponent

        Button
        {
            property var workspaceid: null
            property var allClients: null
            
            height: 26
            width: buttonArea.width + 9

            onClicked:
            {
                hyprctlDispatcher.running = true
            }

            Process
            {
                id: hyprctlDispatcher
                command: ["sh", "-c", "hyprctl dispatch" + " '" + "hl.dsp.focus({ workspace = " + workspaceid + "})'"]
                running: false
            }
            
            Row
            {
                id: buttonArea
                anchors.verticalCenter: parent.verticalCaskaydiaCove

                // rightPadding: 5
                leftPadding: 6
                spacing: 4

                Text
                {
                    anchors.verticalCenter: parent.verticalCenter
                    text: workspaceid + ""
                    color: Theme.text 
                    font.pixelSize: 14
                    topPadding: 4
                    font.family: "Hack"
                }

                Component.onCompleted:
                {
                    let i = 0
                    while(i < allClients.length)
                    {
                        if (allClients[i]["workspace"]["id"] === workspaceid)
                        {
                            clientIconComponent.createObject(buttonArea, {
                                    clientClassName: allClients[i]["class"]
                                })
                        }
                        i++
                    }
                }
            }
        }

    }

    Component
    {
        id: clientIconComponent

        Text
        {
            property var clientClassName: null

            // source:"/home/rakman/.local/share/icons/buuf-nestort/apps/" + clientClassName + ".png"
            text: clientClassName
            font.pixelSize: 14
            color: Theme.text
            topPadding: 4
            font.family: "Hack"
        }
    }
}
