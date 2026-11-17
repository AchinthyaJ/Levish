// Levish theme — one place for every color, radius and size.
.pragma library

var panel      = "#1a1f2a"
var panelTop   = "#2a3950"
// The one surface used by every island AND every drop-down, so they read as one piece.
var glass      = "#d916262e"
var glassEdge  = "#33ffffff"   // the one border used everywhere
var card       = "#1fc8f7ef"
// solid palette for the performance overlay and control center
var solidPanel     = "#16262e"
var solidCard      = "#213842"
var solidEdge      = "#2f4f5b"
var solidPanelEdge = "#2f4f5b"   // alias kept for PerfPanel compatibility
var solidCardEdge  = "#2a4452"   // slightly lighter card border
var cardStroke = "#14ffffff"
var text       = "#f5f9fd"
var muted      = "#9fb0c6"
var track      = "#22ffffff"
var badge      = "#0e1420"

// accents: usage arcs and values only
var cpu = "#c8f7ef"
var gpu = "#c8f7ef"
var storage = "#c8f7ef"
var network = "#c8f7ef"
var memory = "#c8f7ef"
var accent  = "#c8f7ef"   // aqua

var radiusIsland = 22
var radiusCard   = 26   // squircle-like
var radiusBadge  = 20
var barHeight    = 34
var barGap       = 16    // space between islands (spreads them across the bar)
var barEdge      = 0     // islands sit on the top edge
var islandPad    = 7   // inner horizontal padding of each island (narrower islands)

// Drop-down panels grow out of an island: concave fillets join the island's
// bottom edge, and the bottom corners use dropRadius.
var fillet       = 14
var dropRadius   = 26

// ── Dock ──────────────────────────────────────────────────────
// Neutral dark glass. Deliberately NOT tinted by the turquoise accent.
var dockGlass     = "#c2111316"   // translucent charcoal; wallpaper shows through
var dockEdge      = "#2cffffff"   // hairline border
var dockShadow    = "#14000000"   // very faint layers beneath the glass
var dockHover     = "#22ffffff"   // backdrop behind a hovered cell
var dockActive    = "#14ffffff"   // backdrop behind the focused app
var dockDot       = "#e8ffffff"   // running indicator
var dockRule      = "#26ffffff"   // separator between groups
var dockTipBg     = "#e6121417"   // tooltip
var dockRadius   = 22            // glass corner radius, matches the top-bar islands
var dockCellPad   = 12            // room around each icon (horizontal)
var dockInnerPad  = 8             // space between glass edge and cells
var dockShadowPad = 8             // transparent window margin that holds the shadow
var dockTipRoom   = 40            // headroom above the glass for tooltips and hover zoom
var dockZoom      = 1.12          // hover enlargement: restrained, not a bounce

// ── Settings application tokens ───────────────────────────────
// Shared by every Settings page so the window reads as part of Levish. Use these names, not
// hex literals, in quickshell/settings. Levels run from the window background up to the
// strongest surface.
var windowBg      = "#14161c"   // window background, behind everything
var sidebarBg     = "#0f1116"   // navigation column
var surface       = "#12ffffff" // grouped card fill
var surfaceHover  = "#14ffffff" // hovered row or chip
var surfaceEdge   = "#18ffffff" // card border and dividers
var controlFill   = "#14ffffff" // input and button background
var controlEdge   = "#22ffffff" // input and button border
var iconTile      = "#1f2a33"   // icon background tile
var textPrimary   = "#f5f9fd"   // same as text
var textSecondary = "#c9d6e8"   // values and descriptions
var textMuted     = "#9fb0c6"   // same as muted
var ok            = "#34d399"   // healthy or valid state
var warning       = "#fb923c"   // needs attention, not broken
var danger        = "#f0708a"   // broken or invalid state
var dangerSoft    = "#22f0708a" // error banner fill
var dangerEdge    = "#55f0708a" // error banner border
var focusRing     = accent      // keyboard focus and selection

// Type scale (pixels). Use these, not ad-hoc sizes.
var fontCaption = 10
var fontSmall   = 12
var fontBody    = 13
var fontTitle   = 15
var fontPage    = 18

// Spacing scale (pixels).
var space1 = 4
var space2 = 8
var space3 = 12
var space4 = 16
var space5 = 24

// Radii for settings controls and surfaces.
var radiusControl = 9
var radiusRow     = 10
var radiusCardSet = 14

// Motion (milliseconds). Reduced motion sets these to 0 in code that reads them.
var durationFast = 120
var durationBase = 180
// Scale for short UI animations. ThemeStore sets it to 0 when reduced motion is on.
var motionScale = 1.0
// Duration in ms for a short animation, honouring reduced motion. Use for literal durations.
function dur(ms) { return Math.round(ms * motionScale) }
// Text size scale from theme.font_scale. Applied to literal pixel sizes via fs(px).
var fontScale = 1.0
function fs(px) { return Math.round(px * fontScale * 10) / 10 }
