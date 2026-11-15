import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"

// Appearance settings. Accent, glass and dock opacity are read live by the bar, the dock and the launcher.
// Fixed design tokens in common/Theme.js are not editable here on purpose.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    property string keywords: "appearance accent colour color theme opacity glass dock transparency hex"
    readonly property var resetPaths: ["theme.accent", "theme.opacity", "dock.opacity"]
    readonly property color accent: themeStore.accentColor
    readonly property var swatches: [
        { name: "Aqua", hex: "#c8f7ef" }, { name: "Turquoise", hex: "#2dd4bf" },
        { name: "Cyan", hex: "#38bdf8" }, { name: "Blue", hex: "#60a5fa" },
        { name: "Purple", hex: "#a78bfa" }, { name: "Green", hex: "#34d399" },
        { name: "Orange", hex: "#fb923c" }, { name: "Red", hex: "#f87171" }
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
            title: "Accent colour"
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
                            border.color: "#f5f9fd"
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
                    font.pixelSize: 12
                    color: "#f5f9fd"
                    placeholderText: "#rrggbb"
                    background: Rectangle { radius: 8; color: "#14ffffff"; border.color: "#22ffffff" }
                    onEditingFinished: {
                        page.hexError = ""
                        if (!page.themeStore.set("theme.accent", text.trim())) page.hexError = "Use a 6-digit hex colour."
                    }
                }
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
        }
    }
}
