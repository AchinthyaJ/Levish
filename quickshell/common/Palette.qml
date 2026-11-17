// The live colour palette. Every colour a component draws from the palette is a property here, so
// a change in Settings reaches the whole shell at once. Values come from the configuration through
// ThemeStore; Theme.js supplies the defaults when there is no store (for example in unit tests).
//
// Overlays (borders, hover tints, separators) are the palette's ink colour at a fixed opacity, so
// a light palette gets dark overlays and a dark palette gets light ones.
pragma Singleton
import QtQuick
import "Theme.js" as Theme

QtObject {
    id: palette

    // Set once by ThemeStore when it loads.
    property var store: null

    // ── Base colours (opaque, from the configuration) ───────────────────────
    readonly property color window: store ? store.paletteWindow : Theme.windowBg
    readonly property color sidebar: store ? store.paletteSidebar : Theme.sidebarBg
    readonly property color text: store ? store.paletteText : Theme.text
    readonly property color textPrimary: text
    readonly property color textSecondary: store ? store.paletteTextSecondary : Theme.textSecondary
    readonly property color muted: store ? store.paletteMuted : Theme.muted
    readonly property color ink: store ? store.paletteInk : "#ffffff"
    readonly property color iconTile: store ? store.paletteIconTile : Theme.iconTile
    readonly property color ok: store ? store.paletteOk : Theme.ok
    readonly property color warning: store ? store.paletteWarning : Theme.warning
    readonly property color danger: store ? store.paletteDanger : Theme.danger
    // Solid cards (the performance tiles and similar panels).
    readonly property color card: store ? store.paletteCard : Theme.solidCard
    readonly property color cardEdge: store ? store.paletteCardEdge : Theme.solidCardEdge
    readonly property color accent: store ? store.accentColor : Theme.accent

    // ── Glass surfaces: base colour plus the configured opacity ──────────────
    readonly property color glass: store ? store.glassColor : Theme.glass
    readonly property color dockGlass: store ? store.dockGlass : Theme.dockGlass
    readonly property color dockTip: Qt.rgba(dockBaseRgb.r, dockBaseRgb.g, dockBaseRgb.b, 0.9)
    readonly property color dockBaseRgb: store ? store.dockBase : Theme.dockGlass

    // ── Overlays: ink at the opacities the design uses ───────────────────────
    readonly property color surface: Qt.rgba(ink.r, ink.g, ink.b, 0.07)
    readonly property color surfaceHover: Qt.rgba(ink.r, ink.g, ink.b, 0.08)
    readonly property color surfaceEdge: Qt.rgba(ink.r, ink.g, ink.b, 0.09)
    readonly property color controlFill: Qt.rgba(ink.r, ink.g, ink.b, 0.08)
    readonly property color controlEdge: Qt.rgba(ink.r, ink.g, ink.b, 0.13)
    readonly property color track: Qt.rgba(ink.r, ink.g, ink.b, 0.13)
    readonly property color glassEdge: Qt.rgba(ink.r, ink.g, ink.b, 0.2)
    readonly property color dockEdge: Qt.rgba(ink.r, ink.g, ink.b, 0.17)
    readonly property color dockHover: Qt.rgba(ink.r, ink.g, ink.b, 0.13)
    readonly property color dockActive: Qt.rgba(ink.r, ink.g, ink.b, 0.08)
    readonly property color dockRule: Qt.rgba(ink.r, ink.g, ink.b, 0.15)
    readonly property color dockDot: Qt.rgba(ink.r, ink.g, ink.b, 0.91)
}
