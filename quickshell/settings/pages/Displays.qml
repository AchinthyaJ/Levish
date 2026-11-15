import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme

// Displays: the monitors Hyprland reports, read-only. Changing a display needs a confirm-or-revert
// step, so the controls are not offered until that exists.
Flickable {
    id: page
    property var themeStore
    property var hypr                  // HyprQuery
    property string pageId: ""
    property string keywords: "display displays monitor monitors screen resolution refresh rate scale position hyprland output"
    readonly property var resetPaths: []
    readonly property color accent: themeStore.accentColor

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        SettingsCard {
            title: "Monitors"
            SettingsRow {
                label: !page.hypr ? "Hyprland not connected"
                     : page.hypr.status === "loading" ? "Reading monitors…"
                     : page.hypr.status === "error" ? "Could not read monitors"
                     : (page.hypr.monitors.length + " connected")
                hint: page.hypr && page.hypr.status === "error" ? page.hypr.error : "Read from Hyprland. Changes are not available here yet."
                SettingsButton { text: "Refresh"; onClicked: page.hypr.refresh() }
            }
        }

        Repeater {
            model: page.hypr ? page.hypr.monitors : []
            delegate: SettingsCard {
                required property var modelData
                title: modelData.name + (modelData.focused ? "  ·  focused" : "")

                SettingsRow { label: "Display"; hint: modelData.description
                    Text { text: modelData.width + " × " + modelData.height; color: Theme.textSecondary; font.pixelSize: Theme.fontSmall } }
                SettingsRow { label: "Refresh rate"
                    Text { text: Number(modelData.refreshRate).toFixed(2) + " Hz"; color: Theme.textSecondary; font.pixelSize: Theme.fontSmall } }
                SettingsRow { label: "Scale"
                    Text { text: Number(modelData.scale).toFixed(2) + "×"; color: Theme.textSecondary; font.pixelSize: Theme.fontSmall } }
                SettingsRow { label: "Position"
                    Text { text: modelData.x + ", " + modelData.y; color: Theme.textSecondary; font.pixelSize: Theme.fontSmall } }
                SettingsRow { label: "Available modes"
                    Text {
                        Layout.maximumWidth: 300
                        text: (modelData.availableModes || []).slice(0, 6).join("   ")
                        color: Theme.muted; font.pixelSize: Theme.fontCaption
                        wrapMode: Text.Wrap
                    } }
            }
        }
    }
}
