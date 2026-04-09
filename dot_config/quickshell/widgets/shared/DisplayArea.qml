import QtQuick
import "../.."

// Deep void background gradient — blue-black display area, semi-transparent
// for Hyprland blur (frosted-glass effect).
Rectangle {
    id: root
    radius: 8

    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.displayFill }
        GradientStop { position: 0.1; color: Theme.panelFill }
        GradientStop { position: 0.9; color: Theme.panelFill }
        GradientStop { position: 1.0; color: Theme.displayFill }
    }
}
