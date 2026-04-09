import QtQuick
import "../.."

// Minimal outer frame — subtle dark border, void terminal style
Rectangle {
    id: root
    radius: 12

    property bool showScrews: true
    property int screwMargin: 10
    property int screwSize: 8

    color: Theme.frameFill   // semi-transparent — lets Hyprland blur show through
    border.width: 1
    border.color: Theme.borderNormal

    // Top teal accent highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: Theme.lambdaDark }
            GradientStop { position: 0.7; color: Theme.lambdaDark }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.5
    }

    // ▓▓▓ CORNER MARKERS (subtle dots instead of screws) ▓▓▓
    Repeater {
        model: root.showScrews ? 4 : 0
        Rectangle {
            width: root.screwSize; height: root.screwSize; radius: root.screwSize / 2
            color: Theme.screwBg
            border.width: 1
            border.color: Theme.screwBorder

            x: (index % 2 === 0) ? root.screwMargin : root.width - root.screwMargin - width
            y: (index < 2) ? root.screwMargin : root.height - root.screwMargin - height

            // Teal center dot
            Rectangle {
                anchors.centerIn: parent
                width: 3; height: 3; radius: 1.5
                color: Theme.lambdaDark
                opacity: 0.7
            }
        }
    }
}
