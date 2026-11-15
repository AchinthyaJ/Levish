// Notification service: owns org.freedesktop.Notifications for the session, keeps a bounded history
// of closed notifications, and exposes do-not-disturb. Popups are drawn by NotificationPopups.qml.
//
// Behaviour:
// • A notification received while do-not-disturb is on, or while notifications are disabled in
//   Settings, is recorded in the history but never tracked, so no popup is shown for it.
// • Every other notification is tracked by the server until it closes. The popup window shows
//   the tracked list.
// • Do-not-disturb is runtime state: it is not written to config.json.
// • History lives in memory and is cleared when the shell restarts.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: svc
    required property var themeStore

    property bool doNotDisturb: false
    property var history: []           // newest first; each entry is a plain object
    readonly property int historyLimit: 100
    readonly property alias server: server
    readonly property int liveCount: tracker.count

    function setDoNotDisturb(on) { svc.doNotDisturb = !!on }

    function _record(n, status, reason) {
        const entry = {
            id: n.id,
            app: n.appName || n.desktopEntry || "Application",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency,
            status: status,                       // "shown" | "suppressed"
            reason: reason || "",
            time: Qt.formatTime(new Date(), "HH:mm:ss")
        }
        svc.history = [entry].concat(svc.history).slice(0, svc.historyLimit)
    }

    function clearHistory() { svc.history = [] }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        persistenceSupported: true
        bodyMarkupSupported: false
        bodyImagesSupported: false
        bodyHyperlinksSupported: false
        imageSupported: false

        onNotification: (n) => {
            const suppressed = svc.doNotDisturb || !svc.themeStore.notificationsEnabled
            if (suppressed) {
                svc._record(n, "suppressed", svc.doNotDisturb ? "do not disturb" : "notifications off")
                n.tracked = false
                return
            }
            n.tracked = true
        }
    }

    // One entry per tracked notification. Its Connections record the notification into history
    // when it closes, whether the user dismissed it, it expired, or the app closed it.
    Instantiator {
        id: tracker
        model: server.trackedNotifications
        delegate: Connections {
            required property var modelData
            target: modelData
            function onClosed(reason) {
                svc._record(modelData, "shown", reason !== undefined ? String(reason) : "")
            }
        }
    }
}
