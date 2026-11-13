// Download history as a smooth line, sampled every backend update.
import QtQuick
import "../common" as C
import "../common/Theme.js" as Theme

Canvas {
    id: graph
    property real value: 0
    property var samples: []
    onValueChanged: {
        samples.push(value)
        if (samples.length > 60) samples.shift()
        requestPaint()
    }
    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        if (samples.length < 2) return
        const peak = Math.max(0.5, Math.max.apply(null, samples))
        ctx.strokeStyle = Theme.network
        ctx.lineWidth = 1.6
        ctx.beginPath()
        for (let i = 0; i < samples.length; i++) {
            const x = i / (samples.length - 1) * width
            const y = height - (samples[i] / peak) * (height - 4) - 2
            i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y)
        }
        ctx.stroke()
    }
}
