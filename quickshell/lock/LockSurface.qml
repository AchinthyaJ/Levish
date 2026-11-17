import QtQuick
import Quickshell
import Quickshell.Wayland
import "background"
import "layouts"
import "../common/Theme.js" as Theme

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property var themeStore
    required property var store
    required property var pam
    required property var weatherService

    color: "transparent"

    readonly property real screenScale: Math.min(1.4, Math.max(0.75, (root.height > 0 ? root.height : 1080) / 1080))
    readonly property string chosenLayout: (themeStore && themeStore.lockLayout) ? themeStore.lockLayout : "cinematic"

    // Atmospheric Background
    LockBackground {
        id: bg
        themeStore: root.themeStore
        screen: root.screen
        active: root.visible
        opacity: 0
    }

    // Main Interactive Content Area with Key Capture
    Item {
        id: contentContainer
        anchors.fill: parent
        opacity: 0
        scale: 0.96
        focus: true

        Component.onCompleted: forceActiveFocus()
        onActiveFocusChanged: {
            if (!activeFocus) forceActiveFocus()
        }

        Keys.onPressed: (event) => {
            if (root.pam) {
                root.pam.handleKey(event)
            }
        }

        Loader {
            id: layoutLoader
            anchors.fill: parent
            asynchronous: false

            sourceComponent: {
                if (root.chosenLayout === "editorial") return editorialComp
                if (root.chosenLayout === "minimal") return minimalComp
                if (root.chosenLayout === "split") return splitComp
                return cinematicComp
            }
        }

        Component {
            id: cinematicComp
            CinematicCenter {
                themeStore: root.themeStore
                store: root.store
                pam: root.pam
                weatherService: root.weatherService
                screen: root.screen
                screenScale: root.screenScale
            }
        }

        Component {
            id: editorialComp
            EditorialLeft {
                themeStore: root.themeStore
                store: root.store
                pam: root.pam
                weatherService: root.weatherService
                screen: root.screen
                screenScale: root.screenScale
            }
        }

        Component {
            id: minimalComp
            MinimalLayout {
                themeStore: root.themeStore
                store: root.store
                pam: root.pam
                weatherService: root.weatherService
                screen: root.screen
                screenScale: root.screenScale
            }
        }

        Component {
            id: splitComp
            SplitFocus {
                themeStore: root.themeStore
                store: root.store
                pam: root.pam
                weatherService: root.weatherService
                screen: root.screen
                screenScale: root.screenScale
            }
        }
    }

    // Smooth Appearance Transition
    ParallelAnimation {
        id: enterAnim
        running: true

        NumberAnimation {
            target: bg
            property: "opacity"
            from: 0; to: 1
            duration: (root.themeStore && root.themeStore.lockReducedMotion) ? 100 : 320
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: contentContainer
            property: "opacity"
            from: 0; to: 1
            duration: (root.themeStore && root.themeStore.lockReducedMotion) ? 100 : 360
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: contentContainer
            property: "scale"
            from: (root.themeStore && root.themeStore.lockReducedMotion) ? 1.0 : 0.96
            to: 1.0
            duration: Theme.dur(360)
            easing.type: Easing.OutCubic
        }
    }

    // Smooth Unlock Transition
    SequentialAnimation {
        id: exitAnim

        ParallelAnimation {
            NumberAnimation {
                target: contentContainer
                property: "opacity"
                to: 0
                duration: (root.themeStore && root.themeStore.lockReducedMotion) ? 80 : 220
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: contentContainer
                property: "scale"
                to: (root.themeStore && root.themeStore.lockReducedMotion) ? 1.0 : 0.96
                duration: Theme.dur(220)
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: bg
                property: "opacity"
                to: 0
                duration: (root.themeStore && root.themeStore.lockReducedMotion) ? 80 : 200
                easing.type: Easing.InCubic
            }
        }

        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }

    Connections {
        target: root.pam
        function onSuccess() {
            exitAnim.restart()
        }
    }
}
