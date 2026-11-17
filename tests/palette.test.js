// Tests for the colour palette: presets are complete and valid, the schema defaults match the
// design tokens in Theme.js, and the light preset really is light. Run with: node --test tests/
const { test } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const root = path.join(__dirname, "..", "quickshell", "common")
const schemaSrc = fs.readFileSync(path.join(root, "ConfigSchema.js"), "utf8")
const ctx = {}
vm.runInNewContext(schemaSrc + ";this.api = { schema, presets, coerce, schemaPaths };", ctx)
const { schema, presets, coerce } = ctx.api

const themeSrc = fs.readFileSync(path.join(root, "Theme.js"), "utf8")
const themeHex = (name) => {
  const m = new RegExp("^var " + name + "\\s*=\\s*\"(#[0-9a-fA-F]{6})\"", "m").exec(themeSrc)
  assert.ok(m, "Theme.js has no opaque colour named " + name)
  return m[1].toLowerCase()
}

// Schema key -> Theme.js token it replaces.
const DEFAULTS = {
  "palette.window": "windowBg", "palette.sidebar": "sidebarBg", "palette.bar": null,
  "palette.dock": null, "palette.text": "text", "palette.text_secondary": "textSecondary",
  "palette.muted": "muted", "palette.icon_tile": "iconTile", "palette.ok": "ok",
  "palette.warning": "warning", "palette.danger": "danger",
}
const paletteKeys = Object.keys(schema).filter((k) => k.startsWith("palette."))

test("palette defaults match the design tokens in Theme.js", () => {
  for (const [key, token] of Object.entries(DEFAULTS)) {
    if (token === null) continue
    assert.equal(schema[key].def, themeHex(token), key + " should equal Theme." + token)
  }
})

test("every palette key is a colour with a valid default", () => {
  for (const key of paletteKeys) {
    assert.equal(schema[key].kind, "color", key)
    assert.equal(coerce(schema[key], schema[key].def), schema[key].def, key)
  }
})

test("every preset sets every palette key and only valid values", () => {
  for (const [name, values] of Object.entries(presets)) {
    for (const key of paletteKeys) assert.ok(key in values, name + " is missing " + key)
    for (const [key, value] of Object.entries(values)) {
      assert.ok(key in schema, name + " sets unknown key " + key)
      assert.equal(coerce(schema[key], value), value, name + ": " + key + " = " + value)
    }
  }
})

function luminance(hex) {
  const c = [1, 3, 5].map((i) => parseInt(hex.substr(i, 2), 16) / 255)
  const lin = c.map((v) => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)))
  return 0.2126 * lin[0] + 0.7152 * lin[1] + 0.0722 * lin[2]
}

test("the Light preset has dark text on a light background", () => {
  const p = presets["Light"]
  assert.ok(luminance(p["palette.window"]) > 0.7, "window should be light")
  assert.ok(luminance(p["palette.text"]) < 0.2, "text should be dark")
  assert.ok(luminance(p["palette.ink"]) < 0.2, "ink should be dark, so overlays read on light")
})

test("the dark presets keep light text on a dark background", () => {
  for (const name of ["Levish Aqua", "Midnight", "Warm"]) {
    const p = presets[name]
    assert.ok(luminance(p["palette.window"]) < 0.1, name + " window should be dark")
    assert.ok(luminance(p["palette.text"]) > 0.6, name + " text should be light")
  }
})
