// Squircle-style card: large radius, frosted fill, subtle inner stroke.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme

Rectangle {
    default property alias content: inner.data
    implicitWidth: 200
    implicitHeight: 100
    radius: 30
    color: Theme.solidCard
    border.color: Theme.solidCardEdge
    border.width: 1
    Item { id: inner; anchors.fill: parent; anchors.margins: 12 }
}
