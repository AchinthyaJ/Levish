import QtQuick
import Quickshell.Io
import "../../common/Theme.js" as Theme
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common" as Pal

// Appearance settings. Accent, glass and dock opacity are read live by the bar, the dock and the launcher.
// Fixed design tokens in common/Theme.js are not editable here on purpose.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string wallMsg: ""
    property string keywords: "appearance accent colour color theme opacity glass dock transparency hex corner radius rounded"
    readonly property var resetPaths: ["theme.accent", "theme.opacity", "dock.opacity", "theme.radius", "theme.border", "theme.font_scale", "theme.font_family", "ui.reduced_motion",
        "palette.window", "palette.sidebar", "palette.bar", "palette.dock", "palette.text", "palette.text_secondary", "palette.muted", "palette.ink", "palette.icon_tile", "palette.ok", "palette.warning", "palette.danger"]
    readonly property color accent: themeStore.accentColor
    readonly property var swatches: [
        { name: "Aqua", hex: Pal.Palette.accent }, { name: "Turquoise", hex: "#2dd4bf" },
        { name: "Cyan", hex: "#38bdf8" }, { name: "Blue", hex: "#60a5fa" },
        { name: "Purple", hex: "#a78bfa" }, { name: "Green", hex: Pal.Palette.ok },
        { name: "Orange", hex: Pal.Palette.warning }, { name: "Red", hex: Pal.Palette.danger }
    ]
    property string hexError: ""

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        SettingsCard {
            title: "Colour palette"
            SettingsRow {
                label: "Preset"
                hint: "A complete palette in one step. Light and dark presets are included. You can still change each colour below."
                SettingsChoice { accent: page.accent
                    options: page.themeStore.presetNames.map(n => ({ value: n, label: n }))
                    current: ""
                    onPicked: (v) => page.themeStore.applyPreset(v) }
            }
            SettingsRow {
                label: "Window background"
                ColorField { themeStore: page.themeStore; path: "palette.window"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Settings sidebar"
                ColorField { themeStore: page.themeStore; path: "palette.sidebar"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Top bar background"
                ColorField { themeStore: page.themeStore; path: "palette.bar"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Dock background"
                ColorField { themeStore: page.themeStore; path: "palette.dock"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Primary text"
                ColorField { themeStore: page.themeStore; path: "palette.text"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Secondary text"
                ColorField { themeStore: page.themeStore; path: "palette.text_secondary"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Muted text"
                ColorField { themeStore: page.themeStore; path: "palette.muted"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Ink (borders and tints)"
                ColorField { themeStore: page.themeStore; path: "palette.ink"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Icon tile"
                ColorField { themeStore: page.themeStore; path: "palette.icon_tile"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Healthy"
                ColorField { themeStore: page.themeStore; path: "palette.ok"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Warning"
                ColorField { themeStore: page.themeStore; path: "palette.warning"; accent: page.accent; width: 180 }
            }
            SettingsRow {
                label: "Danger"
                ColorField { themeStore: page.themeStore; path: "palette.danger"; accent: page.accent; width: 180 }
            }
        }

        SettingsCard {
            title: "Accent colour"
            // Takes the average colour of the current wallpaper (ImageMagick), with its saturation raised.
            Process {
                id: wallColor
                stdout: StdioCollector { id: wallColorOut }
                stderr: StdioCollector { id: wallColorErr }
                onExited: (code) => {
                    const m = /#([0-9a-fA-F]{6})/.exec(wallColorOut.text)
                    if (code === 0 && m) {
                        page.themeStore.set("theme.accent", "#" + m[1].toLowerCase())
                        page.wallMsg = "Accent set from the wallpaper."
                    } else {
                        page.wallMsg = "Could not read the wallpaper colour (is ImageMagick installed?)."
                    }
                }
            }
            SettingsRow {
                label: "From wallpaper"
                hint: "Sets the accent to the average colour of the current wallpaper."
                SettingsButton {
                    text: wallColor.running ? "Reading…" : "Use wallpaper colour"
                    onClicked: {
                        page.wallMsg = ""
                        wallColor.command = ["magick", page.themeStore.wallpaperPath, "-modulate", "100,150", "-resize", "1x1!", "txt:-"]
                        wallColor.running = true
                    }
                }
            }
            Text {
                visible: page.wallMsg !== ""
                Layout.fillWidth: true
                text: page.wallMsg
                color: Pal.Palette.muted
                font.pixelSize: Theme.fs(12)
                wrapMode: Text.Wrap
            }
            SettingsRow {
                label: "Preset"
                hint: "Used for active controls and highlights across the shell."
                Row {
                    spacing: 8
                    Repeater {
                        model: page.swatches
                        delegate: Rectangle {
                            required property var modelData
                            width: 22; height: 22; radius: 11
                            color: modelData.hex
                            border.width: page.themeStore.accentColor === modelData.hex ? 2 : 0
                            border.color: Pal.Palette.textPrimary
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.themeStore.set("theme.accent", modelData.hex)
                            }
                        }
                    }
                }
            }
            SettingsRow {
                label: "Custom colour"
                hint: page.hexError !== "" ? page.hexError : "Hex, for example #7aa2f7."
                TextField {
                    width: 120; height: 30
                    text: page.themeStore.accentColor
                    font.pixelSize: Theme.fs(12)
                    color: Pal.Palette.textPrimary
                    placeholderText: "#rrggbb"
                    background: Rectangle { radius: 8; color: Pal.Palette.controlFill; border.color: Pal.Palette.controlEdge }
                    onEditingFinished: {
                        page.hexError = ""
                        if (!page.themeStore.set("theme.accent", text.trim())) page.hexError = "Use a 6-digit hex colour."
                    }
                }
            }
        }

        SettingsCard {
            title: "Typography and edges"
            SettingsRow {
                label: "Text size"
                hint: "Scales the text across Levish. Applies in full after the shell restarts."
                SettingsSlider { from: 80; to: 140; step: 5; suffix: "%"; accent: page.accent
                    value: page.themeStore.fontScale * 100
                    onCommitted: (v) => page.themeStore.set("theme.font_scale", v / 100) }
            }
            SettingsRow {
                label: "Font family"
                hint: "Used on the lock screen. Other text uses the system default for now."
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 9
                color: Pal.Palette.controlFill
                border.color: fontField.activeFocus ? page.accent : Pal.Palette.controlEdge
                TextField {
                    id: fontField
                    anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                    text: page.themeStore.fontFamily
                    placeholderText: "JetBrains Mono"
                    placeholderTextColor: Pal.Palette.muted
                    color: Pal.Palette.text
                    font.pixelSize: Theme.fs(12)
                    background: Item {}
                    onEditingFinished: page.themeStore.set("theme.font_family", text)
                }
            }
            SettingsRow {
                label: "Border visibility"
                hint: "How strong the thin edges of the dock and panels are."
                SettingsSlider { from: 0; to: 100; step: 1; suffix: "%"; accent: page.accent
                    value: page.themeStore.borderStrength * 100
                    onCommitted: (v) => page.themeStore.set("theme.border", v / 100) }
            }
        }

        SettingsCard {
            title: "Glass"
            SettingsRow {
                label: "Bar and island opacity"
                hint: "How much wallpaper shows through the top bar."
                SettingsSlider { from: 30; to: 100; step: 1; suffix: "%"; accent: page.accent
                    value: page.themeStore.glassOpacity * 100
                    onCommitted: (v) => page.themeStore.set("theme.opacity", v / 100) }
            }
            SettingsRow {
                label: "Dock opacity"
                SettingsSlider { from: 30; to: 100; step: 1; suffix: "%"; accent: page.accent
                    value: page.themeStore.dockOpacity * 100
                    onCommitted: (v) => page.themeStore.set("dock.opacity", v / 100) }
            }
            SettingsRow {
                label: "Corner radius"
                hint: "Roundness of the dock. Each value is in pixels."
                SettingsSlider { from: 4; to: 28; step: 1; suffix: " px"; accent: page.accent
                    value: page.themeStore.cornerRadius
                    onCommitted: (v) => page.themeStore.set("theme.radius", v) }
            }
        }

        SettingsCard {
            title: "Motion"
            SettingsRow {
                label: "Reduced motion"
                hint: "Turns off the short transitions in the shell and Settings. Changes apply in full after the shell restarts."
                SettingsToggle { accent: page.accent; checked: page.themeStore.reducedMotion
                    onToggled: (v) => page.themeStore.set("ui.reduced_motion", v) }
            }
        }
    }
}
