pragma Singleton
import QtQuick

QtObject {
    // ═══════════════════════════════════════════════════════════════
    //  VOID TERMINAL THEME — derin mavi-siyah · fosfor teal
    //  Hyprland kenarlık renkleri için: ~/.config/hypr/colors.conf
    //  QML panel renkleri burada tanımlı; tutarlı kalmaya dikkat et.
    // ═══════════════════════════════════════════════════════════════

    // ▓▓▓ CORE PALETTE - Void / Deep Space ▓▓▓
    readonly property color background: "#030810"        // Deep void black-blue
    readonly property color backgroundAlt: "#060f1c"     // Slightly lighter void
    readonly property color backgroundPanel: "#050d18"   // Panel background

    // ▓▓▓ BAR / CELL COLORS ▓▓▓
    readonly property color barBackground: "#02060e"     // Nearly black
    readonly property color cellBackground: "#0a1628"    // Deep blue cell
    readonly property color activeBackground: "#00e5b8"  // Phosphor teal active
    readonly property color hoverBackground: "#0d1f30"   // Hover dark blue
    readonly property color cellBorder: "#0f2030"        // Cell border blue

    // ▓▓▓ TEAL ACCENT PALETTE (replaces orange lambda) ▓▓▓
    readonly property color lambda: "#00e5b8"            // Phosphor teal (main accent)
    readonly property color lambdaDark: "#00b890"        // Dark teal
    readonly property color lambdaMid: "#00ccaa"         // Mid teal
    readonly property color lambdaLight: "#22ffdd"       // Light teal
    readonly property color lambdaGlow: "#44ffee"        // Glow teal
    readonly property color lambdaBevel: "#88ffee"       // Bevel highlight teal

    // ▓▓▓ DANGER PALETTE (replaces blood-red) ▓▓▓
    readonly property color blood: "#004a6a"             // Muted deep teal-blue (danger)
    readonly property color bloodDark: "#002a40"         // Dark danger
    readonly property color bloodBright: "#0077aa"       // Bright danger

    // ▓▓▓ FRAME PALETTE (replaces rust) ▓▓▓
    readonly property color rust: "#0d2035"              // Dark blue frame
    readonly property color rustLight: "#1a3a55"         // Lighter blue frame
    readonly property color rustMid: "#142840"           // Mid blue frame
    readonly property color rustDark: "#0a1828"          // Dark blue frame
    readonly property color rustDeep: "#040c18"          // Deepest blue frame

    // ▓▓▓ PANEL DISPLAY COLORS ▓▓▓
    readonly property color displayDark: "#010408"       // Deepest display
    readonly property color displayMid: "#040c18"        // Mid display
    readonly property color displayLight: "#081422"      // Light display
    readonly property color displayBorder: "#0f2a40"     // Display border
    readonly property color displayBorderActive: lambda  // Active border

    // ▓▓▓ HEADER TEXT ▓▓▓
    readonly property color headerText: "#ccffee"        // Light teal text on dark header
    readonly property color headerTextDim: "#559988"     // Dimmer header text

    // ▓▓▓ CONTENT TEXT ▓▓▓
    readonly property color contentText: "#a0c8c0"       // Soft teal-white content text
    readonly property color contentTextDim: "#446a66"    // Dim content text

    // ▓▓▓ CORNER DECORATIONS ▓▓▓
    readonly property color screwBg: rustDark
    readonly property color screwBorder: "#1a3a55"
    readonly property color screwSlot: "#081428"

    // ▓▓▓ ACCENT alias ▓▓▓
    readonly property color accent: lambda
    readonly property color accentText: "#030810"

    // ▓▓▓ TEXT HIERARCHY ▓▓▓
    readonly property color text: "#b0d8d0"              // Main text — pale teal-white
    readonly property color textPrimary: "#b0d8d0"       // Alias
    readonly property color textSecondary: "#6a9a94"     // Secondary
    readonly property color textMuted: "#2a4a48"         // Muted
    readonly property color textDim: "#1a3030"           // Very dim
    readonly property color activeText: "#eefffc"        // Active / bright
    readonly property color textDanger: bloodBright      // Danger text

    // ▓▓▓ BORDERS & SEPARATORS ▓▓▓
    readonly property color separator: "#0f2030"         // Separator line
    readonly property color borderNormal: "#142840"      // Normal border
    readonly property color borderActive: lambda         // Active border
    readonly property color borderDanger: blood          // Danger border

    // ▓▓▓ VDESK BUTTONS ▓▓▓
    readonly property color vdeskActive: lambda
    readonly property color vdeskInactive: "#0a1a2a"
    readonly property color vdeskActiveText: "#030810"
    readonly property color vdeskInactiveText: textSecondary

    // ▓▓▓ INDICATORS ▓▓▓
    readonly property color indicatorColor: "#00e5b8"    // Phosphor teal indicator
    readonly property color indicatorActive: "#00e5b8"
    readonly property color indicatorEmpty: "transparent"
    readonly property color warning: bloodBright
    readonly property color success: "#00e5b8"

    // ▓▓▓ HEADER STYLES ▓▓▓
    readonly property color headerBackground: "#040e1c"  // Dark blue header
    readonly property color headerBorder: lambdaDark

    // ▓▓▓ DEBUG ▓▓▓
    readonly property color debugBackground: "#003355"
    readonly property color debugText: "#00ffcc"

    // ▓▓▓ OPACITY ▓▓▓
    readonly property real backgroundOpacity: 0.85
    readonly property real panelOpacity: 0.80

    // ▓▓▓ BLUR-FRIENDLY PANEL BACKGROUNDS ▓▓▓
    // These variants include an alpha channel so Hyprland's layer blur
    // is visible through the panel surfaces (frosted-glass effect).
    // Format: #AARRGGBB  (AA = alpha byte, 00=fully transparent, ff=opaque)
    readonly property color panelFill:   "#d8050d18"   // α=0xd8 ≈ 85 % opaque — DisplayArea body
    readonly property color frameFill:   "#cc0d2035"   // α=0xcc ≈ 80 % opaque — MetallicFrame fill
    readonly property color displayFill: "#c4010408"   // α=0xc4 ≈ 77 % opaque — DisplayArea dark stops

    // ▓▓▓ BORDER RADIUS - Minimal/Clean ▓▓▓
    readonly property int radiusSmall: 3
    readonly property int radiusMedium: 5
    readonly property int radiusLarge: 8
    readonly property int barRadius: 5

    // ▓▓▓ SPACING ▓▓▓
    readonly property int spacingSmall: 4
    readonly property int spacingMedium: 8
    readonly property int spacingLarge: 12

    // ▓▓▓ ANIMATION ▓▓▓
    readonly property int animFast: 100
    readonly property int animNormal: 150
    readonly property int animSlow: 250

    // ▓▓▓ TYPOGRAPHY ▓▓▓
    readonly property string fontMono: "JetBrains Mono"
    readonly property string fontUI: "Inter"

    // ▓▓▓ SYMBOLS - Void Terminal Icons ▓▓▓
    readonly property string sawblade: "·"               // Minimal dot (replaces ⚙)
    readonly property string lambdaSymbol: "◈"           // Void marker
    readonly property string skull: "◇"
    readonly property string hazard: "◈"
    readonly property string warning_icon: "⚠"
    readonly property string bullet: "·"
    readonly property string arrow: "▶"
    readonly property string cross: "✕"
    readonly property string check: "✓"

    // ▓▓▓ DECORATIVE TEXT ▓▓▓
    readonly property string tagline: "void://terminal.init"
    readonly property string classified: "[ ENCRYPTED ]"
    readonly property string blackMesa: "VOID TERMINAL"
}
