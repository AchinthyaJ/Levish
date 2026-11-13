// Smooth stroked icons drawn on a Canvas. Every icon is designed on a 24-unit
// grid with the same round-capped stroke, so the whole set looks uniform.
// Shapes are kept deliberately simple (few vertices) so they read clearly small.
import QtQuick

Canvas {
    id: icon
    property string kind: ""            // see the branches in onPaint
    property string tint: "#f5f9fd"
    property real stroke: 2

    width: 18; height: 18
    antialiasing: true
    onKindChanged: requestPaint()
    onTintChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const s = Math.min(width, height) / 24
        ctx.scale(s, s)
        ctx.strokeStyle = tint
        ctx.fillStyle = tint
        ctx.lineWidth = stroke
        ctx.lineCap = "round"
        ctx.lineJoin = "round"

        function rrect(x, y, w, h, r) {
            ctx.beginPath()
            ctx.moveTo(x + r, y)
            ctx.arcTo(x + w, y, x + w, y + h, r)
            ctx.arcTo(x + w, y + h, x, y + h, r)
            ctx.arcTo(x, y + h, x, y, r)
            ctx.arcTo(x, y, x + w, y, r)
            ctx.closePath()
        }
        function seg(x1, y1, x2, y2) {
            ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke()
        }
        function dot(x, y, r) {
            ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill()
        }
        function poly(pts, filled) {
            ctx.beginPath()
            ctx.moveTo(pts[0][0], pts[0][1])
            for (let i = 1; i < pts.length; i++) ctx.lineTo(pts[i][0], pts[i][1])
            ctx.closePath()
            filled ? ctx.fill() : ctx.stroke()
        }
        // Speaker body shared by the volume icons.
        function speaker() { poly([[3, 9], [7, 9], [12, 5], [12, 19], [7, 15], [3, 15]], false) }

        if (kind === "cpu") {
            // Chip: a softly tinted rounded body, a rounded core and four short pins.
            ctx.globalAlpha = 0.18
            rrect(4.5, 4.5, 15, 15, 4.5); ctx.fill()
            ctx.globalAlpha = 1
            rrect(4.5, 4.5, 15, 15, 4.5); ctx.stroke()
            rrect(8.5, 8.5, 7, 7, 2); ctx.fill()
            seg(12, 1.5, 12, 4); seg(12, 20, 12, 22.5)
            seg(1.5, 12, 4, 12); seg(20, 12, 22.5, 12)
        } else if (kind === "thermo") {
            rrect(9.5, 3, 5, 12, 2.5); ctx.stroke()
            dot(12, 17.5, 3.2)
        } else if (kind === "wifi" || kind === "wifiOff") {
            const a0 = -Math.PI * 3 / 4, a1 = -Math.PI / 4, cy = 19
            for (const r of [14, 9.5, 5]) { ctx.beginPath(); ctx.arc(12, cy, r, a0, a1); ctx.stroke() }
            dot(12, cy, 1.4)
            if (kind === "wifiOff") seg(4, 4, 20, 20)
        } else if (kind === "volume") {
            speaker()
            ctx.beginPath(); ctx.arc(12, 12, 4.5, -0.8, 0.8); ctx.stroke()
            ctx.beginPath(); ctx.arc(12, 12, 8.5, -0.75, 0.75); ctx.stroke()
        } else if (kind === "volLow") {
            speaker()
            ctx.beginPath(); ctx.arc(12, 12, 4.5, -0.8, 0.8); ctx.stroke()
        } else if (kind === "mute") {
            speaker()
            seg(16, 9.5, 21, 14.5); seg(21, 9.5, 16, 14.5)
        } else if (kind === "bolt") {
            poly([[13.2, 2.5], [5.5, 13.5], [11.5, 13.5], [10.6, 21.5], [18.5, 10.2], [12.5, 10.2]], true)
        } else if (kind === "bluetooth") {
            poly([[7, 7.5], [17, 16.5], [12, 21], [12, 3], [17, 7.5], [7, 16.5]], false)
        } else if (kind === "sun") {
            ctx.beginPath(); ctx.arc(12, 12, 4, 0, Math.PI * 2); ctx.stroke()
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4
                seg(12 + Math.cos(a) * 7, 12 + Math.sin(a) * 7, 12 + Math.cos(a) * 9.5, 12 + Math.sin(a) * 9.5)
            }
        } else if (kind === "lock") {
            rrect(5, 11, 14, 10, 2.5); ctx.stroke()
            ctx.beginPath(); ctx.moveTo(8.5, 11); ctx.lineTo(8.5, 8)
            ctx.arc(12, 8, 3.5, Math.PI, 2 * Math.PI); ctx.lineTo(15.5, 11); ctx.stroke()
        } else if (kind === "moon") {
            // Crescent: outer arc on the left, inner arc cutting back in.
            const px = 12 + 8 * Math.cos(0.7), py = 12 + 8 * Math.sin(0.7)
            const ir = Math.hypot(px - 17, py - 12), ia = Math.atan2(py - 12, px - 17)
            ctx.beginPath()
            ctx.arc(12, 12, 8, 0.7, 2 * Math.PI - 0.7, false)
            ctx.arc(17, 12, ir, -ia, ia - 2 * Math.PI, true)
            ctx.stroke()
        } else if (kind === "power") {
            ctx.beginPath(); ctx.arc(12, 12.5, 8, -Math.PI / 2 + 0.5, -Math.PI / 2 - 0.5 + 2 * Math.PI, false); ctx.stroke()
            seg(12, 3, 12, 11.5)
        } else if (kind === "restart") {
            ctx.beginPath(); ctx.arc(12, 12, 8, -1.6, 3.2, false); ctx.stroke()
            seg(12.2, 4, 8.8, 4); seg(12.2, 4, 12.2, 7.2)
        } else if (kind === "play") {
            poly([[8, 5.5], [19, 12], [8, 18.5]], true)
        } else if (kind === "pause") {
            ctx.fillRect(7, 6, 3.6, 12); ctx.fillRect(13.4, 6, 3.6, 12)
        } else if (kind === "prev") {
            poly([[18, 6], [7, 12], [18, 18]], true)
            ctx.fillRect(4, 6, 2.6, 12)
        } else if (kind === "next") {
            poly([[6, 6], [17, 12], [6, 18]], true)
            ctx.fillRect(17.4, 6, 2.6, 12)
        } else if (kind === "close") {
            seg(6, 6, 18, 18); seg(18, 6, 6, 18)
        } else if (kind === "note") {
            dot(8, 17.5, 3)
            seg(11, 17.5, 11, 5); seg(11, 5, 18, 7)
        } else if (kind === "down") {
            seg(12, 4, 12, 19); seg(6.5, 13.5, 12, 19); seg(17.5, 13.5, 12, 19)
        } else if (kind === "up") {
            seg(12, 20, 12, 5); seg(6.5, 10.5, 12, 5); seg(17.5, 10.5, 12, 5)
        }
    }
}
