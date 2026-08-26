pragma Singleton
import QtQuick

QtObject {
    readonly property color base:     "#0d0b09"
    readonly property color border:   "#ff9a2f"
    readonly property color text:     "#f1e6d8"
    readonly property color background:  "#0d0b09"


    // Active Button
    readonly property color activeButtonBackground: "#ff9a2f"
    readonly property color activeButtonText: "#221812"
    readonly property color activeButtonBorder: "#221812"
    readonly property color activePressedButtonBackground: "#e08520"
    readonly property color activePressedButtonText: "#221812"
    readonly property color activePressedButtonBorder: "#221812"

    // Passive Button
    readonly property color passiveButtonBackground: "#221812"
    readonly property color passiveButtonText: "#ff9a2f"
    readonly property color passiveButtonBorder: "#221812"
    readonly property color passivePressedButtonBackground: "#f1e6d8"
    readonly property color passivePressedButtonText: "#221812"
    readonly property color passivePressedButtonBorder: "#221812"

    readonly property color mantle:   "#221812"
    readonly property color surface0: "#c4be53"
    readonly property color overlay0: "#8d887f"
    readonly property color blue:     "#ff9a2f"
    readonly property color mauve:    "#d51110"
    readonly property color green:    "#eff0f1"
    readonly property color primary: "#ff9a2f"
    readonly property color primaryContainer: "#ff9a2f"
    readonly property color secondary: "#221812"
    readonly property string fontFamily: "Hack"
    readonly property color surface1: "#1a1613"
    readonly property color surface2: "#2a221d"
    readonly property color subtext0: "#8d887f"
    readonly property color error: "#d51110"
    readonly property color outline: "#7f8c8d"
    readonly property color outlineVariant: "#463222"
}
