import QtQuick
import "../.."

// ═══════════════════════════════════════════════════════════
// GLITCH LAYER — scanlines · glitch bars · subtle grain
// Overlay on top of any element for "void terminal" feel.
// Usage: add as a sibling over a Rectangle, set anchors.fill.
// ═══════════════════════════════════════════════════════════
Item {
    id: root
    clip: true

    // Tunable properties
    property real scanlineOpacity: 0.06
    property real glitchOpacity: 0.18
    property real grainOpacity: 0.04
    property int  scanlineSpacing: 3        // pixels between scanlines
    property int  glitchIntervalMs: 4000    // average time between glitch events
    property real glitchBar2Offset: 0.7    // second bar fires at this fraction of glitchIntervalMs
    property bool enableScanlines: true
    property bool enableGlitch: true
    property bool enableGrain: true

    // ── 1. SCANLINES ────────────────────────────────────────
    Item {
        id: scanlines
        anchors.fill: parent
        visible: root.enableScanlines
        clip: true

        // A single thin stripe tile repeated over the whole area
        Repeater {
            model: Math.ceil(root.height / root.scanlineSpacing) + 1
            Rectangle {
                x: 0
                y: index * root.scanlineSpacing
                width: root.width
                height: 1
                color: "#00ffcc"
                opacity: root.scanlineOpacity
            }
        }
    }

    // ── 2. GRAIN OVERLAY ────────────────────────────────────
    // Simulated with a faint semi-transparent noise pattern using
    // two offset rectangles so it stays cheap (no Canvas/shader).
    Item {
        id: grainOverlay
        anchors.fill: parent
        visible: root.enableGrain
        opacity: root.grainOpacity

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            // Fine dot grid approximation
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "#00ffcc" }
                GradientStop { position: 0.25; color: "transparent" }
                GradientStop { position: 0.5;  color: "#00ffcc" }
                GradientStop { position: 0.75; color: "transparent" }
                GradientStop { position: 1.0;  color: "#00ffcc" }
            }
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0;  color: "#00ffcc" }
                GradientStop { position: 0.33; color: "transparent" }
                GradientStop { position: 0.66; color: "#00ffcc" }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }
    }

    // ── 3. GLITCH BARS ──────────────────────────────────────
    // Two horizontal bars that flash briefly at random Y positions.
    Item {
        id: glitchContainer
        anchors.fill: parent
        visible: root.enableGlitch
        clip: true

        // Per-bar state — holds the computed pause duration for the current loop
        QtObject {
            id: bar1State
            property int pauseMs: root.glitchIntervalMs
        }
        QtObject {
            id: bar2State
            property int pauseMs: Math.round(root.glitchIntervalMs * root.glitchBar2Offset)
        }

        Rectangle {
            id: glitchBar1
            x: 0
            y: 0
            width: root.width
            height: 0
            color: Theme.lambda
            opacity: 0

            SequentialAnimation {
                id: glitchAnim1
                loops: Animation.Infinite

                // Randomize the next pause duration before waiting
                ScriptAction {
                    script: {
                        bar1State.pauseMs = root.glitchIntervalMs + Math.round((Math.random() - 0.5) * root.glitchIntervalMs * 0.4)
                    }
                }
                PauseAnimation { duration: bar1State.pauseMs }
                ScriptAction {
                    script: {
                        glitchBar1.y = Math.random() * (root.height - 8)
                        glitchBar1.height = 1 + Math.random() * 3
                    }
                }
                NumberAnimation { target: glitchBar1; property: "opacity"; to: root.glitchOpacity; duration: 30 }
                PauseAnimation { duration: 60 }
                NumberAnimation { target: glitchBar1; property: "opacity"; to: 0; duration: 80 }
            }
        }

        Rectangle {
            id: glitchBar2
            x: 0
            y: 0
            width: root.width
            height: 0
            color: Theme.lambda
            opacity: 0

            SequentialAnimation {
                id: glitchAnim2
                loops: Animation.Infinite

                // Randomize the next pause duration before waiting
                ScriptAction {
                    script: {
                        bar2State.pauseMs = Math.round(root.glitchIntervalMs * root.glitchBar2Offset)
                            + Math.round((Math.random() - 0.5) * root.glitchIntervalMs * 0.3)
                    }
                }
                PauseAnimation { duration: bar2State.pauseMs }
                ScriptAction {
                    script: {
                        glitchBar2.y = Math.random() * (root.height - 8)
                        glitchBar2.height = 1 + Math.random() * 2
                    }
                }
                NumberAnimation { target: glitchBar2; property: "opacity"; to: root.glitchOpacity * 0.7; duration: 25 }
                PauseAnimation { duration: 40 }
                NumberAnimation { target: glitchBar2; property: "opacity"; to: 0; duration: 60 }
            }
        }
    }

    Component.onCompleted: {
        if (root.enableGlitch) {
            glitchAnim1.start()
            glitchAnim2.start()
        }
    }
}
