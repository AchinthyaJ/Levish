import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme

// Night light and caffeine. Night light is saved; caffeine lasts until you turn it off or the shell restarts.
Flickable {
    id: page
    property var themeStore
    property var session               // SessionTools
    property string pageId: ""
    ScrollBar.vertical: PageScrollBar { accent: page.themeStore.accentColor }
    property string keywords: "night light nightlight warm colour color temperature hyprsunset caffeine keep awake screen sleep idle inhibit"
    readonly property var resetPaths: ["nightlight.enabled", "nightlight.temperature"]
    readonly property color accent: themeStore.accentColor

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        SettingsCard {
            title: "Night light"
            SettingsRow {
                label: "Warm the screen colour"
                hint: !page.session ? "" : (page.session.nightStatus === "unavailable"
                     ? "hyprsunset did not start. Check that it is installed."
                     : "Runs hyprsunset with the temperature below.")
                SettingsToggle { accent: page.accent; checked: page.themeStore.nightlightEnabled
                    onToggled: (v) => page.themeStore.set("nightlight.enabled", v) }
            }
            SettingsRow {
                label: "Colour temperature"
                hint: "Lower is warmer. 6500 K is neutral."
                SettingsSlider { from: 2500; to: 6500; step: 100; suffix: " K"; accent: page.accent
                    value: page.themeStore.nightlightTemp
                    onCommitted: (v) => page.themeStore.set("nightlight.temperature", Math.round(v)) }
            }
        }

        SettingsCard {
            title: "Caffeine"
            SettingsRow {
                label: "Keep the screen awake"
                hint: "Stops the idle timer and the screen from sleeping. Not saved: it turns off when the shell restarts."
                SettingsToggle { accent: page.accent; checked: page.session ? page.session.caffeine : false
                    onToggled: (v) => { if (page.session) page.session.setCaffeine(v) } }
            }
        }
    }
}
