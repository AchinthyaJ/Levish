import QtQuick
import Quickshell
import Quickshell.Io

// Shared state read from the Python backend (/tmp/levish/*.json).
// The backend already polls the hardware; this only watches its files.
Item {
    id: root
    property var metrics: ({ cpu_percent: 0, cpu_per_core: [], ram_percent: 0,
                             ram_used_gb: 0, ram_total_gb: 0, cpu_temp: null,
                             gpu_percent: null, gpu_temp: null,
                             net_up_mbps: 0, net_down_mbps: 0 })
    property var battery: ({ percent: 0, charging: false })
    property var network: ({ connected: false, ssid: "" })
    property var audio:   ({ volume: 0, muted: false })
    property string activeTitle: ""
    property string activeClass: ""
    property string cpuModel: "CPU"
    property string uptime: ""
    property string disk: "0"
    property string diskText: ""

    FileView {
        path: "/tmp/levish/metrics.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.metrics = JSON.parse(text()) } catch (e) {} }
    }
    FileView {
        path: "/tmp/levish/battery.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.battery = JSON.parse(text()) } catch (e) {} }
    }
    FileView {
        path: "/tmp/levish/network.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.network = JSON.parse(text()) } catch (e) {} }
    }
    FileView {
        path: "/tmp/levish/active_window.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { const w = JSON.parse(text()); root.activeTitle = w.title || ""; root.activeClass = w.class || "" } catch (e) {} }
    }
    FileView {
        path: "/tmp/levish/audio.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.audio = JSON.parse(text()) } catch (e) {} }
    }

    // Slow-changing values: read once, refresh every 30 s.
    Process {
        id: slow
        command: ["sh", "-c",
            "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//';" +
            "uptime -p | sed 's/up //';" +
            "df -h --output=used,size / | tail -1 | awk '{print $1\" / \"$2}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n")
                root.cpuModel = lines[0] || "CPU"
                root.uptime = lines[1] || ""
                root.diskText = lines[2] || ""
            }
        }
    }
    // Disk percent on its own so no other line can leak into it.
    Process {
        id: diskPct
        command: ["sh", "-c", "df --output=pcent / | tail -1 | tr -dc 0-9"]
        stdout: StdioCollector {
            onStreamFinished: root.disk = this.text.trim() || "0"
        }
    }
    Timer {
        interval: 30000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { slow.running = false; slow.running = true; diskPct.running = false; diskPct.running = true }
    }
}
