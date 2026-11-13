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
var barHeight    = 44
var barGap       = 16    // space between islands (spreads them across the bar)
var barEdge      = 0     // islands sit on the top edge
var islandPad    = 7   // inner horizontal padding of each island (narrower islands)

// Drop-down panels grow out of an island: concave fillets join the island's
// bottom edge, and the bottom corners use dropRadius.
var fillet       = 14
var dropRadius   = 26
