import QtQuick
import "../.."

// Minimal dark header bar with teal accent line
Rectangle {
    id: root
    height: 44
    radius: 8

    property string title: "HEADER"
    property string subtitle: ""
    property string leftIcon: ""
    property string rightIcon: ""
    property int iconSize: 16
    property bool showSeparator: true

    color: Theme.headerBackground

    // Top teal accent line
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        radius: parent.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.2; color: Theme.lambda }
            GradientStop { position: 0.8; color: Theme.lambda }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.8
    }

    // Header content
    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: root.leftIcon
            font.pixelSize: root.iconSize
            font.family: Theme.fontMono
            color: Theme.lambda
            visible: root.leftIcon !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: root.title
                font.family: Theme.fontMono
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 2
                color: Theme.headerText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
                font.family: Theme.fontMono
                font.pixelSize: 8
                font.letterSpacing: 1
                color: Theme.headerTextDim
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        Text {
            text: root.rightIcon
            font.pixelSize: root.iconSize
            font.family: Theme.fontMono
            color: Theme.lambda
            visible: root.rightIcon !== ""
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Bottom separator line (teal)
    Rectangle {
        visible: root.showSeparator
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.2; color: Theme.lambdaDark }
            GradientStop { position: 0.5; color: Theme.lambda }
            GradientStop { position: 0.8; color: Theme.lambdaDark }
            GradientStop { position: 1.0; color: "transparent" }
        }
        opacity: 0.7
    }
}
