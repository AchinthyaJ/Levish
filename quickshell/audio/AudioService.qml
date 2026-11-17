// Audio state from PipeWire, through Quickshell's native service (Quickshell.Services.Pipewire).
// One instance is created in shell.qml. It reads nodes and their volume and mute directly from
// PipeWire, so nothing parses command output. Routing a stream to another output is not in this
// API and is not done here.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Item {
    id: svc

    // Every node PipeWire knows about, tracked so their audio properties are valid.
    readonly property var all: Pipewire.nodes ? Pipewire.nodes.values : []
    PwObjectTracker { objects: svc.all }

    readonly property bool ready: Pipewire.ready
    readonly property var defaultOutput: Pipewire.defaultAudioSink
    readonly property var defaultInput: Pipewire.defaultAudioSource

    // Output devices: hardware sinks, not application streams.
    readonly property var outputs: all.filter(n => n.isSink && !n.isStream && !!n.audio)
    // Input devices: capture sources, without the monitor sources PipeWire creates for each output.
    readonly property var inputs: all.filter(n => !n.isSink && !n.isStream && !!n.audio && !isMonitor(n))
    // Applications that are playing audio right now.
    // PipeWire reports a playback stream with isSink set as well as isStream, so the test is the pair.
    // Every playback stream, whatever its state (playing, paused or idle). A stream whose audio data
    // is not readable yet is still listed, with its controls disabled.
    readonly property var streams: all.filter(n => n.isStream && n.isSink)

    function prop(node, key) {
        return node && node.properties ? String(node.properties[key] || "") : ""
    }
    function isMonitor(node) {
        return node.name.indexOf("monitor") >= 0 || prop(node, "media.class") === "Audio/Source/Virtual"
    }
    // Name for a device or a stream, with the most specific label PipeWire has.
    function label(node) {
        if (!node) return ""
        if (node.isStream) return prop(node, "application.name") || node.nickname || node.description || node.name
        return node.description || node.nickname || node.name
    }
    // Icon name from the application, when it sets one (resolved by the icon theme).
    function appIcon(node) {
        return prop(node, "application.icon-name") || prop(node, "application.process.binary") || "audio-x-generic"
    }

    function setDefaultOutput(node) { if (node) Pipewire.preferredDefaultAudioSink = node }
    function setDefaultInput(node) { if (node) Pipewire.preferredDefaultAudioSource = node }

    // Volume is 0 to 1 in PipeWire terms. The settings page shows it as a percentage.
    // ── Per-application output routing ─────────────────────────────────────
    // WirePlumber sends a stream to the output named in the stream's "target.object" key of the
    // "default" metadata. Quickshell cannot write metadata, so pw-metadata does it, one command at a
    // time. An empty target means "follow the default output". The chosen route is also kept here,
    // because the metadata cannot be read back through Quickshell.
    property var routes: ({})            // stream node id -> output node name ("" = default)
    property string routeError: ""
    property var _queue: []

    function routeOf(stream) {
        return stream && routes[stream.id] !== undefined ? routes[stream.id] : ""
    }
    function routeStream(stream, sink) {
        if (!stream) return
        const target = sink ? sink.name : ""
        const r = Object.assign({}, routes); r[stream.id] = target; routes = r
        _enqueue(["pw-metadata", "-n", "default", String(stream.id), "target.object", target, "Spa:String"])
    }
    function _enqueue(cmd) {
        _queue = _queue.concat([cmd])
        _pump()
    }
    function _pump() {
        if (router.running || _queue.length === 0) return
        router.command = _queue[0]
        _queue = _queue.slice(1)
        router.running = true
    }
    Process {
        id: router
        stderr: StdioCollector { id: routerErr }
        onExited: (code) => {
            svc.routeError = code === 0 ? "" : (routerErr.text.trim() || "Could not change the output for this application.")
            svc._pump()
        }
    }

    // Volume and mute are sent with wpctl, which changes the node through PipeWire. Writing
    // node.audio.volume from QML was accepted but did not reach PipeWire in this build. Reading the
    // values stays native, so the sliders follow what PipeWire reports. Commands share one queue.
    function setVolume(node, fraction) {
        if (!node) return
        const pct = Math.round(Math.max(0, Math.min(1, fraction)) * 100)
        _enqueue(["wpctl", "set-volume", String(node.id), pct + "%"])
    }
    function setMuted(node, muted) {
        if (!node) return
        _enqueue(["wpctl", "set-mute", String(node.id), muted ? "1" : "0"])
    }
}
