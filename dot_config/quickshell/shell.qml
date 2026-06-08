import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
// import QtQuick.Controls.Basic

ShellRoot
{
    id: shellRoot

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
                    shellRoot.parsedClients = data.clients || []
                    shellRoot.parsedWorkspaces = data.workspaces || []
                    shellRoot.parsedMonitors = data.monitors || []
                    topBar.rebuildWsCards()
                    windowSwitcher.rebuildWsCards()
                }
                catch(e)
                {
                    console.log("aajsonFetcher JSON Parse Error:", e)
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

    PanelWindow
    {
        id: topBar

        implicitHeight:27
        implicitWidth: 1920
        anchors.top: true
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        // WlrLayershell.exclusiveZone: 0
        function rebuildWsCards()
        {
            let i = 0
            while(workspaceButtonsRow.children.length > i)
            {
                workspaceButtonsRow.children[i].destroy()
                i++
            }

            i = 0
            while (shellRoot.parsedWorkspaces.length > i)
            {
                workspaceButtonComponent.createObject(workspaceButtonsRow, {
                        workspaceid: shellRoot.parsedWorkspaces[i]["id"],
                        allClients: shellRoot.parsedClients
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

                text: clientClassName
                font.pixelSize: 14
                color: Theme.text
                topPadding: 4
                font.family: "Hack"
            }
        }
    }

    PanelWindow
    {
        id: windowSwitcherPanel

        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: 0
        implicitWidth: windowSwitcher.width
        implicitHeight: windowSwitcher.height

        Rectangle
        {
            id: windowSwitcher

            property var isVisible: true

            color: "transparent"
            // border.color: Theme.border
            // radius: 10
            width: workspaceCardsRow.width + 60
            height: workspaceCardsRow.height + 40
            visible: isVisible
            // anchors.centerIn: parent

            Row
            {
                id: workspaceCardsRow
                anchors.centerIn: parent
                height:108
                spacing: 20
            }

            Component
            {
                id: workspaceCardComponent

                Rectangle
                {
                    id: workspaceCardComponentRectangle
                    property var workspaceid: null
                    property var allclients: null

                    width: 192
                    height: 108
                    color: "transparent"
                    // border.color: Theme.base
                    // border.width: 14

                    Item
                    {
                        Component.onCompleted:
                        {
                            let i = 0

                            while(i < workspaceCardComponentRectangle.children.length)
                            {
                                if (workspaceid === allclients[i]["workspace"]["id"])
                                    workspaceCardComponentRectangle.children[i].destroy()
                                i++
                            }
                            let j = 0
                            i = 0
                            while (i < allclients.length)
                            {
                                if (workspaceid === allclients[i]["workspace"]["id"])
                                {
                                    clientCardComponent.createObject(workspaceCardComponentRectangle, {
                                        clientAtx: allclients[i]["at"][0],
                                        clientAty: allclients[i]["at"][1],
                                        clientSizex: allclients[i]["size"][0],
                                        clientSizey: allclients[i]["size"][1],
                                        clientClass: allclients[i]["class"],
                                        clientTitle: allclients[i]["title"],
                                        clientAddress: allclients[i]["address"]
                                    })
                                    j++
                                    // console.log(allclients[i]["title"] + "------------------\n" + "X coordinate: " + allclients[i]["at"][0] + "\nY coordinate: " + allclients[i]["at"][1] + "\n X size:" + allclients[i]["size"][0] + "\nY size: " + allclients[i]["size"][1])
                                }
                                i++
                            }
                        }
                    }
                }
            }

            Component
            {
                id: clientCardComponent

                Rectangle
                {
                    property var clientAtx: null
                    property var clientAty: null
                    property var clientSizex: null
                    property var clientSizey: null
                    property var clientClass: null
                    property var clientTitle: null
                    property var clientAddress: null

                    color: Theme.background 
                    border.color: Theme.border
                    radius: 5
                    x: clientAtx / 10
                    y: clientAty / 10
                    width: clientSizex / 10
                    height: clientSizey / 10

                    Text
                    {
                        id: jalem
                        anchors.centerIn: parent
                        text: clientClass
                        color: Theme.text 
                        font.pixelSize: 12
                    }

                    MouseArea
                    {
                        anchors.fill: parent
                        // preventStealing: true
                        onEntered:
                        {
                            windowFocusDispatcher.running = true
                        }
                    }

                    Process
                    {
                        id: windowFocusDispatcher
                        command: ["sh", "-c", "hyprctl dispatch " + "\"hl.dsp.focus({window=\'address:" + clientAddress + "\'})\""]
                    }

                }
            }
            


            function rebuildWsCards()
            {
                let i = 0
                while(i < workspaceCardsRow.children.length)
                {
                    workspaceCardsRow.children[i].destroy()
                    i++
                }

                i = 0
                while(i < shellRoot.parsedWorkspaces.length)
                {
                    workspaceCardComponent.createObject(workspaceCardsRow, {
                            workspaceid: shellRoot.parsedWorkspaces[i]["id"],
                            allclients: shellRoot.parsedClients
                        })
                    i++
                }
            }

            Timer
            {
                id: uiUpdaterroot
                repeat: true
                running:
                {
                    if (windowSwitcher.isVisible === true)
                        true
                    else
                        false
                }
                onTriggered:
                {
                    uiUpdater.running = true
                }
            }

            Timer
            {
                id: uiUpdater
                repeat:
                {
                    if (windowSwitcher.isVisible === true)
                        true
                    else
                        false
                }
                running: true
                interval: 100
                onTriggered:
                {
                    jsonFetcher.running = true
                }
            }

            IpcHandler
            {
                target: "windowSwitcher"
                function toggleVisibility()
                {
                    // if (windowSwitcher.isVisible === false)
                    //     jsonFetcher.running = true
                    // else
                    //     jsonFetcher.running = false
                    windowSwitcher.isVisible = !windowSwitcher.isVisible
                }
            }
        }
    }
}
