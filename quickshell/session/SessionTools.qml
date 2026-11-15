// Session toggles: caffeine (keep the screen awake) and night light (hyprsunset).
//
// • Caffeine is runtime state. It holds a systemd idle inhibitor while on and is not saved.
// • Night light is saved in config.json. While on, one hyprsunset process runs with the chosen temperature.
// Both are plain processes: turning them off stops them.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: svc
    required property var themeStore

    property bool caffeine: false
    // "off" | "on" | "unavailable"
    property string nightStatus: "off"

    function setCaffeine(on) { svc.caffeine = !!on }

    // Caffeine: a systemd idle inhibitor for as long as the process runs.
    Process {
        id: caffeineProc
        running: svc.caffeine
        command: ["systemd-inhibit", "--what=idle", "--who=Levish", "--why=Caffeine is on in Levish Settings", "--mode=block", "sleep", "infinity"]
        onExited: (code) => {
            // If the inhibitor dies on its own, reflect that: caffeine is no longer on.
            if (svc.caffeine) svc.caffeine = false
            if (code !== 0 && code !== 143 && code !== 15) console.warn("caffeine: systemd-inhibit exited with " + code)
        }
    }

    // Night light: hyprsunset as a background process.
    Process {
        id: nightProc
        stderr: StdioCollector { id: nightErr }
        onExited: (code) => {
            // Our own stop (restart or turning off) is expected and must not be reported as a failure.
            if (svc._stoppingNight) { svc._stoppingNight = false; return }
            if (!svc.themeStore.nightlightEnabled) { svc.nightStatus = "off"; return }
            if (code !== 0) { svc.nightStatus = "unavailable"; console.warn("night light: " + nightErr.text) }
        }
    }
    property bool _stoppingNight: false

    // Starts, restarts or stops night light to match the saved setting.
    function applyNightLight() {
        if (nightProc.running) { svc._stoppingNight = true; nightProc.running = false }
        if (!svc.themeStore.nightlightEnabled) { svc.nightStatus = "off"; return }
        nightProc.command = ["hyprsunset", "-t", String(svc.themeStore.nightlightTemp)]
        nightProc.running = true
        svc.nightStatus = "on"
    }

    Component.onCompleted: applyNightLight()
    Connections {
        target: svc.themeStore
        function onNightlightEnabledChanged() { svc.applyNightLight() }
        function onNightlightTempChanged() { svc.applyNightLight() }
    }
}
