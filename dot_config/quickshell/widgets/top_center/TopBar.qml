import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../.."
import "../shared"

// ═══════════════════════════════════════════════════════════
// TOP BAR - 3x3 Virtual Desktop Grid (Hover to reveal)
// ═══════════════════════════════════════════════════════════

Variants {
    id: topBarRoot
    // Multi-monitor: show on every connected screen
    model: Quickshell.screens
    
    // Required bindings from parent
    required property int activeVdesk
    required property var populatedVdesks
    
    // Signals to parent
    signal vdeskClicked(int vdeskNum)
    signal vdeskRightClicked(int vdeskNum, real globalX, real globalY, var screen)
    
    function isPopulated(vdeskNum) { return populatedVdesks[vdeskNum] === true }

    PanelWindow {
        id: bar
        property var modelData
        screen: modelData
        property bool hovered: false
        
        exclusionMode: ExclusionMode.Ignore
        anchors { top: true }
        
        margins { left: (screen.width - implicitWidth) / 2 }
        
        implicitWidth: gridContainer.width + 16
        implicitHeight: gridContainer.height + 12
        color: "transparent"
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: bar.hovered = true
            onExited: bar.hovered = false
            
            Rectangle {
                anchors.fill: parent
                radius: Theme.radiusLarge
                opacity: bar.hovered ? Theme.backgroundOpacity : 0
                color: Theme.barBackground
                border.width: 1
                border.color: Theme.separator
                
                // Üst ışık efekti (Bevel)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Theme.lambda
                    opacity: 0.3
                }
                
                Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                
                Grid {
                    id: gridContainer
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: bar.hovered ? 6 : -height
                    columns: 3
                    rows: 3
                    spacing: Theme.spacingSmall
                    
                    Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    
                    Repeater {
                        model: 9
                        
                        Rectangle {
                            id: vdeskButton
                            required property int index
                            readonly property int vdeskNum: index + 1
                            readonly property bool isActive: vdeskNum === topBarRoot.activeVdesk
                            readonly property bool hasWindows: topBarRoot.isPopulated(vdeskNum)
                            
                            width: 26
                            height: 26
                            radius: Theme.radiusSmall
                            color: isActive ? Theme.vdeskActive : Theme.vdeskInactive
                            
                            // Minimal void-terminal vdesk indicator
                            Text {
                                id: vdeskLabel
                                anchors.centerIn: parent
                                text: vdeskButton.isActive ? vdeskButton.vdeskNum : "·"
                                color: vdeskButton.isActive ? Theme.vdeskActiveText : Theme.vdeskInactiveText
                                font.pixelSize: vdeskButton.isActive ? 13 : 11
                                font.bold: vdeskButton.isActive
                                font.family: Theme.fontMono
                            }
                            
                            // Köşe numarası
                            Text {
                                anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 2
                                text: vdeskButton.vdeskNum
                                color: vdeskButton.isActive ? Theme.vdeskActiveText : Theme.textDim
                                font.pixelSize: 8; font.bold: true; opacity: 0.8
                            }
                            
                            // Doluluk İndikatörü
                            Rectangle {
                                width: 4; height: 4; radius: 2
                                anchors.top: parent.top; anchors.left: parent.left; anchors.margins: 2
                                color: vdeskButton.hasWindows ? Theme.indicatorActive : "transparent"
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        let globalPos = mapToGlobal(mouse.x, mouse.y)
                                        topBarRoot.vdeskRightClicked(vdeskButton.vdeskNum, globalPos.x, globalPos.y, bar.screen)
                                    } else if (!vdeskButton.isActive) {
                                        topBarRoot.vdeskClicked(vdeskButton.vdeskNum)
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
