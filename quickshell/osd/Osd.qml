// On-screen display for volume, brightness and keyboard layout.
//
// Event-driven, no polling:
// • Volume and brightness come from the backend's state files (/tmp/levish/audio.json and
//   brightness.json). The backend rewrites them when the hardware changes, and FileView watches
//   them with inotify. The OSD only shows when a value actually changed, so the first load at
//   startup stays silent.
// • Keyboard layout comes from Hyprland's activelayout event.
// The window is click-through and never takes focus.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../common" as C
import "../common/Theme.js" as Theme

PanelWindow {
    id: osd
    required property var themeStore

    property string kind: ""          // "volume" | "brightness" | "keyboard"
    property real level: 0            // 0–100; unused for keyboard
    property bool muted: false
    property string label: ""
    property bool shownNow: false

    visible: shownNow
    color: "transparent"
    exclusiveZone: 0
    focusable: false
    WlrLayershell.namespace: "levish-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors { bottom: true }
    margins { bottom: 110 }
    implicitWidth: 300
    implicitHeight: 62
    mask: Region {}                   // click-through

    // Last values seen, so only real changes show the OSD.
    property var lastAudio: null
    property var lastBrightness: null

    function show(k, lvl, text, isMuted) {
        const gate = k === "volume" ? osd.themeStore.osdVolume
                   : (k === "brightness" ? osd.themeStore.osdBrightness : osd.themeStore.osdKeyboard)
        if (!gate) return
        osd.kind = k
        osd.level = lvl
        osd.label = text
        osd.muted = !!isMuted
        osd.shownNow = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: osd.themeStore.osdTimeout
        onTriggered: osd.shownNow = false
    }

    function _parse(raw) {
        try { return JSON.parse(raw) } catch (e) { return null }
    }

    // ── Volume ──────────────────────────────────────────────────────────────
    FileView {
        id: audioFile
        path: "/tmp/levish/audio.json"
        watchChanges: true
        printErrors: false
        onLoaded: osd._audio(text())
        onFileChanged: reload()
    }
    function _audio(raw) {
        const d = osd._parse(raw)
        if (!d || typeof d.volume !== "number") return
        const cur = { volume: Math.round(d.volume), muted: !!d.muted }
        const prev = osd.lastAudio
        osd.lastAudio = cur
        if (prev === null) return
        if (prev.volume === cur.volume && prev.muted === cur.muted) return
        osd.show("volume", cur.muted ? 0 : cur.volume, cur.muted ? "Muted" : (cur.volume + "%"), cur.muted)
    }

    // ── Brightness ──────────────────────────────────────────────────────────
    FileView {
        id: brightnessFile
        path: "/tmp/levish/brightness.json"
        watchChanges: true
        printErrors: false
        onLoaded: osd._brightness(text())
        onFileChanged: reload()
    }
    function _brightness(raw) {
        const d = osd._parse(raw)
        if (!d || typeof d.percent !== "number") return
        const cur = Math.round(d.percent)
        const prev = osd.lastBrightness
        osd.lastBrightness = cur
        if (prev === null || prev === cur) return
        osd.show("brightness", cur, cur + "%", false)
    }

    // ── Keyboard layout ─────────────────────────────────────────────────────
    // Hyprland sends activelayout>>KEYBOARD,LAYOUT; the layout name is the last field.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return
            const parts = event.data.split(",")
            const layout = parts[parts.length - 1].trim()
            if (layout !== "") osd.show("keyboard", 0, layout.toUpperCase(), false)
        }
    }

    // ── View ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.glass
        border.color: Theme.glassEdge
        border.width: 1

        RowLayout {
            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
            spacing: 14

            C.Icon {
                visible: osd.kind !== "keyboard"
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                kind: osd.kind === "brightness" ? "sun" : (osd.muted ? "mute" : "volume")
                tint: osd.themeStore.accentColor
            }

            Rectangle {
                visible: osd.kind !== "keyboard"
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: Theme.track
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, osd.level / 100))
                    height: parent.height
                    radius: 3
                    color: osd.themeStore.accentColor
                    Behavior on width { NumberAnimation { duration: Theme.durationBase; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                Layout.fillWidth: osd.kind === "keyboard"
                Layout.minimumWidth: 52
                horizontalAlignment: Text.AlignRight
                text: osd.label
                color: Theme.text
                font.pixelSize: Theme.fontBody
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }
}
