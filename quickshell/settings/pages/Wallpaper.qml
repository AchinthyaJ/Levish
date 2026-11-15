import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../components"

// Wallpaper manager: pick an image from the wallpaper folder. The background layer
// (wallpaper/Wallpaper.qml) shows the chosen image on every screen.
Flickable {
    id: page
    property var themeStore
    property string pageId: "wallpaper"
    property string keywords: "wallpaper background image picture folder desktop"
    readonly property var resetPaths: ["wallpaper.path", "wallpaper.folder"]
    readonly property color accent: themeStore.accentColor
    readonly property string folder: themeStore.wallpaperFolder !== "" ? themeStore.wallpaperFolder
                                     : Quickshell.env("HOME") + "/Pictures/wallpapers"
    property var files: []

    function refresh() {
        lister.command = ["sh", "-c",
            "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort",
            "sh", page.folder]
        lister.running = true
    }
    onFolderChanged: refresh()
    Component.onCompleted: refresh()

    // Lists the images in the folder. Runs only when the page or folder changes, never on a timer.
    Process {
        id: lister
        stdout: StdioCollector { id: out }
        onRunningChanged: if (!running) page.files = out.text.split("\n").filter(x => x.length > 0)
    }

    contentHeight: col.implicitHeight + 40
    clip: true

    ColumnLayout {
        id: col
        x: 24; y: 20
        width: page.width - 48
        spacing: 14

        SettingsCard {
            title: "Folder"
            SettingsRow {
                label: "Wallpaper folder"
                hint: page.folder + (page.files.length ? "" : " — no images here yet. Add .jpg, .png or .webp files.")
                TextField {
                    width: 260; height: 30
                    text: page.themeStore.wallpaperFolder !== "" ? page.themeStore.wallpaperFolder : page.folder
                    font.pixelSize: 12
                    color: "#f5f9fd"
                    background: Rectangle { radius: 8; color: "#14ffffff"; border.color: "#22ffffff" }
                    onEditingFinished: page.themeStore.set("wallpaper.folder", text.trim())
                }
            }
            SettingsRow {
                label: "Current wallpaper"
                hint: page.themeStore.wallpaperPath !== "" ? page.themeStore.wallpaperPath : "None. The desktop uses a plain background."
                SettingsButton {
                    visible: page.themeStore.wallpaperPath !== ""
                    text: "Remove"
                    onClicked: page.themeStore.set("wallpaper.path", "")
                }
            }
        }

        SettingsCard {
            title: "Images"
            Flow {
                Layout.fillWidth: true
                spacing: 10
                Repeater {
                    model: page.files
                    delegate: Rectangle {
                        required property string modelData
                        readonly property bool chosen: page.themeStore.wallpaperPath === modelData
                        width: 170; height: 102; radius: 10
                        color: "#14ffffff"
                        border.width: chosen ? 2 : 1
                        border.color: chosen ? page.accent : "#22ffffff"
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + encodeURI(modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 340
                            sourceSize.height: 204
                        }
                        Text {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 6 }
                            text: modelData.split("/").pop()
                            color: "#f5f9fd"
                            font.pixelSize: 10
                            elide: Text.ElideMiddle
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.themeStore.set("wallpaper.path", modelData)
                        }
                    }
                }
            }
        }
    }
}
