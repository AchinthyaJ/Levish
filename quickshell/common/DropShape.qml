// The silhouette of a drop-down panel that grows out of an island. The top edge
// sits flush against the bar and flares outward through concave fillets, so the
// panel reads as part of the island. The bottom corners use `radius`.
import QtQuick

Canvas {
    id: drop
    property real fillet: 14
    property real radius: 26
    property string fillColor: "#16262e"
    property string edgeColor: "#2f4f5b"

    onFilletChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onEdgeColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const F = fillet, R = radius, W = width, H = height
        const x0 = F, x1 = W - F

        // Filled silhouette, including the fillets that flare into the island.
        ctx.beginPath()
        ctx.moveTo(0, 0)
        ctx.quadraticCurveTo(x0, 0, x0, F)
        ctx.lineTo(x0, H - R)
        ctx.arcTo(x0, H, x0 + R, H, R)
        ctx.lineTo(x1 - R, H)
        ctx.arcTo(x1, H, x1, H - R, R)
        ctx.lineTo(x1, F)
        ctx.quadraticCurveTo(x1, 0, W, 0)
        ctx.closePath()
        ctx.fillStyle = fillColor
        ctx.fill()

        // Hairline edge down the sides and bottom only; the top stays seamless with the island.
        ctx.beginPath()
        ctx.moveTo(x0, F)
        ctx.lineTo(x0, H - R)
        ctx.arcTo(x0, H, x0 + R, H, R)
        ctx.lineTo(x1 - R, H)
        ctx.arcTo(x1, H, x1, H - R, R)
        ctx.lineTo(x1, F)
        ctx.strokeStyle = edgeColor
        ctx.lineWidth = 1
        ctx.stroke()
    }
}
