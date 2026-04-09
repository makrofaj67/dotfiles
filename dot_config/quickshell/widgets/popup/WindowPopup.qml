import QtQuick
import Quickshell
import "../.."
import "../shared"

// ═══════════════════════════════════════════════════════════
// WINDOW POPUP - Right-click context menu for vdesk windows
// ═══════════════════════════════════════════════════════════

Variants {
    id: popupRoot
    // Multi-monitor: each screen instance is filtered by popupScreen below
    model: Quickshell.screens
    
    // Required bindings from parent
    required property bool visible
    required property int contextVdesk
    required property var windowList
    required property var popupScreen
    
    // Signals to parent
    signal windowClicked(string address)
    signal dismissed()
    
    PanelWindow {
        id: windowPopup
        property var modelData
        screen: modelData
        
        visible: popupRoot.visible && popupRoot.popupScreen === modelData
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true }
        margins { top: 100; left: (screen.width - implicitWidth) / 2 }
        
        implicitWidth: Math.max(240, windowListColumn.width + 40)
        implicitHeight: Math.min(380, windowListColumn.height + 80)
        color: "transparent"
        
        // ═══ OUTER METALLIC FRAME ═══
        MetallicFrame {
            id: popupOuterFrame
            anchors.fill: parent
            radius: 10
            showScrews: true
            screwSize: 6
            screwMargin: 8
            
            // ▓▓▓ INNER DISPLAY ▓▓▓
            DisplayArea {
                id: popupInnerDisplay
                anchors.fill: parent
                anchors.margins: 5
                radius: 6
                
                // ═══ HEADER BAR ═══
                HeaderBar {
                    id: popupHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36
                    radius: parent.radius
                    
                    title: "VDESK " + popupRoot.contextVdesk
                    subtitle: ""
                    iconSize: 16
                }
                
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onExited: popupRoot.dismissed()
                }
                
                // ═══ WINDOW LIST ═══
                Column {
                    id: windowListColumn
                    anchors.top: popupHeader.bottom
                    anchors.topMargin: 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4
                    
                    Repeater {
                        model: popupRoot.windowList
                        
                        Rectangle {
                            id: popupWindowItem
                            required property var modelData
                            width: 200
                            height: 26
                            radius: 4
                            
                            property bool hovered: popupWindowMouse.containsMouse
                            
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: popupWindowItem.hovered ? Theme.hoverBackground : Theme.cellBackground }
                                GradientStop { position: 1.0; color: popupWindowItem.hovered ? Theme.cellBackground : Theme.background }
                            }
                            border.width: 1
                            border.color: popupWindowItem.hovered ? Theme.lambda : Theme.displayBorder
                            
                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                spacing: 8
                                
                                Text {
                                    text: popupWindowItem.modelData.class || "?"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.lambda
                                    width: 55
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Text {
                                    text: popupWindowItem.modelData.title || "Untitled"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.contentText
                                    width: parent.width - 70
                                    elide: Text.ElideRight
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            
                            MouseArea {
                                id: popupWindowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popupRoot.windowClicked(popupWindowItem.modelData.address)
                            }
                        }
                    }
                    
                    // Empty state
                    Text {
                        visible: popupRoot.windowList.length === 0
                        text: "NO WINDOWS"
                        font.family: Theme.fontMono
                        font.pixelSize: 9
                        color: Theme.rust
                    }
                }
                
                // ═══ FOOTER ═══
                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "CLICK TO BRING HERE"
                    font.family: Theme.fontMono
                    font.pixelSize: 7
                    font.letterSpacing: 1
                    color: Theme.rust
                }
            }
        }
    }
}
