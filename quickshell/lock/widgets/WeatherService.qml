import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var themeStore: null
    property var weatherData: ({
        temp_c: "--",
        temp_f: "--",
        condition: "Weather Unavailable",
        location: "",
        code: "113",
        sunrise: "",
        sunset: ""
    })
    property bool loading: false

    readonly property string cachePath: "/tmp/levish/weather.json"

    FileView {
        id: cacheView
        path: root.cachePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                if (parsed && parsed.condition) {
                    root.weatherData = parsed
                }
            } catch (e) {}
        }
    }

    function refresh() {
        if (fetchProc.running) return
        const loc = (root.themeStore && root.themeStore.lockWeatherLocation) ? root.themeStore.lockWeatherLocation.trim() : ""
        const url = "wttr.in/" + encodeURIComponent(loc) + "?format=j1"

        const script = "python3 -c '\n" +
            "import urllib.request, json, sys\n" +
            "try:\n" +
            "    req = urllib.request.Request(\"https://" + url + "\", headers={\"User-Agent\": \"curl/7.88.1\"})\n" +
            "    with urllib.request.urlopen(req, timeout=5) as resp:\n" +
            "        data = json.loads(resp.read().decode())\n" +
            "        curr = data.get(\"current_condition\", [{}])[0]\n" +
            "        area = data.get(\"nearest_area\", [{}])[0]\n" +
            "        city = area.get(\"areaName\", [{}])[0].get(\"value\", \"\")\n" +
            "        astro = data.get(\"weather\", [{}])[0].get(\"astronomy\", [{}])[0]\n" +
            "        out = {\n" +
            "            \"temp_c\": curr.get(\"temp_C\", \"--\"),\n" +
            "            \"temp_f\": curr.get(\"temp_F\", \"--\"),\n" +
            "            \"condition\": curr.get(\"weatherDesc\", [{}])[0].get(\"value\", \"\").strip(),\n" +
            "            \"location\": city,\n" +
            "            \"code\": curr.get(\"weatherCode\", \"113\"),\n" +
            "            \"sunrise\": astro.get(\"sunrise\", \"\"),\n" +
            "            \"sunset\": astro.get(\"sunset\", \"\")\n" +
            "        }\n" +
            "        with open(\"/tmp/levish/weather.json\", \"w\") as f:\n" +
            "            json.dump(out, f)\n" +
            "        print(json.dumps(out))\n" +
            "except Exception as e:\n" +
            "    sys.exit(1)\n" +
            "'"

        fetchProc.command = ["sh", "-c", script]
        root.loading = true
        fetchProc.running = true
    }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    const parsed = JSON.parse(this.text.trim())
                    if (parsed && parsed.condition) {
                        root.weatherData = parsed
                    }
                } catch (e) {}
            }
        }
        onExited: (code) => {
            root.loading = false
        }
    }

    // Auto-refresh every 20 minutes (1200000 ms)
    Timer {
        interval: 1200000
        running: root.themeStore ? root.themeStore.lockShowWeather : true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
