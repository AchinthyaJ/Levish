import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme
import "../../common" as Pal

// On-screen display settings. Read by osd/Osd.qml through the ThemeStore.
Flickable {
    id: page
    property var themeStore
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "osd on screen display volume brightness keyboard layout popup timeout indicator"
    readonly property var resetPaths: ["osd.volume", "osd.brightness", "osd.keyboard", "osd.timeout_ms"]
    readonly property color accent: themeStore.accentColor

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        SettingsCard {
            title: "Show an indicator when"
            SettingsRow {
                label: "Volume changes"
                hint: "Also shows when the output is muted."
                SettingsToggle { accent: page.accent; checked: page.themeStore.osdVolume
                    onToggled: (v) => page.themeStore.set("osd.volume", v) }
            }
            SettingsRow {
                label: "Brightness changes"
                SettingsToggle { accent: page.accent; checked: page.themeStore.osdBrightness
                    onToggled: (v) => page.themeStore.set("osd.brightness", v) }
            }
            SettingsRow {
                label: "Keyboard layout changes"
                hint: "Shows the layout name, for example US or DE."
                SettingsToggle { accent: page.accent; checked: page.themeStore.osdKeyboard
                    onToggled: (v) => page.themeStore.set("osd.keyboard", v) }
            }
        }

        SettingsCard {
            title: "Timing"
            SettingsRow {
                label: "Time on screen"
                hint: "The indicator hides after this long without a new change."
                SettingsSlider { from: 1; to: 6; step: 0.5; decimals: 1; suffix: " s"; accent: page.accent
                    value: page.themeStore.osdTimeout / 1000
                    onCommitted: (v) => page.themeStore.set("osd.timeout_ms", Math.round(v * 1000)) }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Volume and brightness come from the Levish backend. If the backend is not running, these indicators stay quiet."
            color: Pal.Palette.muted
            font.pixelSize: Theme.fontCaption
            wrapMode: Text.Wrap
        }
    }
}
