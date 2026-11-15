import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Item {
    id: root

    required property WlSessionLock lock
    property string status: "idle" // "idle" | "authenticating" | "error" | "success"
    property string buffer: ""
    property string errorMessage: ""
    property int failedAttempts: 0
    readonly property bool isAuthenticating: passwd.active

    signal failed
    signal success

    function handleKey(event) {
        if (passwd.active || status === "success")
            return

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            submit()
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = ""
            } else if (buffer.length > 0) {
                buffer = buffer.slice(0, -1)
            }
        } else if (event.key === Qt.Key_Escape) {
            buffer = ""
            if (status === "error") {
                status = "idle"
                errorMessage = ""
            }
        } else if (event.text && /^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text
            if (status === "error") {
                status = "idle"
                errorMessage = ""
            }
        }
    }

    function submit() {
        if (passwd.active || status === "success")
            return

        if (buffer.length === 0) {
            errorMessage = "Please enter password"
            status = "error"
            failed()
            errorResetTimer.restart()
            return
        }

        status = "authenticating"
        errorMessage = ""
        passwd.start()
    }

    function reset() {
        buffer = ""
        status = "idle"
        errorMessage = ""
        if (passwd.active) {
            passwd.abort()
        }
    }

    PamContext {
        id: passwd

        config: "passwd"
        configDirectory: {
            const url = Qt.resolvedUrl("pam").toString().replace(/^file:\/\//, "")
            return url
        }

        onMessageChanged: {
            if (message && message.length > 0) {
                if (messageIsError) {
                    root.errorMessage = message
                }
            }
        }

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root.buffer)
                // Clear the buffer in memory immediately after submitting response to PAM
                root.buffer = ""
            }
        }

        onCompleted: (res) => {
            root.buffer = ""
            if (res === PamResult.Success) {
                root.status = "success"
                root.errorMessage = ""
                root.success()
            } else {
                root.status = "error"
                root.failedAttempts++
                if (res === PamResult.MaxTries) {
                    root.errorMessage = "Maximum attempts reached. Please wait."
                } else if (res === PamResult.Error) {
                    root.errorMessage = "Authentication error occurred."
                } else {
                    root.errorMessage = "Incorrect password. Please try again."
                }
                root.failed()
                errorResetTimer.restart()
            }
        }

        onError: (err) => {
            root.buffer = ""
            root.status = "error"
            root.errorMessage = "PAM Error: " + PamError.toString(err)
            root.failed()
            errorResetTimer.restart()
        }
    }

    Timer {
        id: errorResetTimer
        interval: 3500
        repeat: false
        onTriggered: {
            if (root.status === "error") {
                root.status = "idle"
                root.errorMessage = ""
            }
        }
    }
}
