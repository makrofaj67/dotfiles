import QtQuick
import "../.."

// Teal gradient separator line
Rectangle {
    id: root
    height: 1
    radius: 1

    property bool fadeEdges: true

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: root.fadeEdges ? "transparent" : Theme.lambdaDark }
        GradientStop { position: root.fadeEdges ? 0.2 : 0.0; color: Theme.lambdaDark }
        GradientStop { position: 0.5; color: Theme.lambda }
        GradientStop { position: root.fadeEdges ? 0.8 : 1.0; color: Theme.lambdaDark }
        GradientStop { position: 1.0; color: root.fadeEdges ? "transparent" : Theme.lambdaDark }
    }
}
