// Unit tests for quickshell/common/ConfigSchema.js: the rules that decide which config values the
// shell accepts. Run with: node --test tests/
// The module is plain JavaScript with no Qt dependency, so it is loaded into a sandbox here.
const { test } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const src = fs.readFileSync(path.join(__dirname, "..", "quickshell", "common", "ConfigSchema.js"), "utf8")
const ctx = {}
vm.runInNewContext(src + ";this.api = { schema, schemaPaths, coerce, migrate, validate, load, serialize, writeFor, rawFor, CONFIG_VERSION };", ctx)
const api = ctx.api
const entry = (p) => api.schema[p]

test("every schema entry has a valid default and bounds", () => {
  for (const p of api.schemaPaths()) {
    const e = entry(p)
    assert.ok(e.prop, p + " has no prop")
    if (e.kind === "enum") assert.ok(e.choices.includes(e.def), p + " default not in choices")
    if (e.kind === "int" || e.kind === "real") {
      assert.ok(e.min <= e.def && e.def <= e.max, p + " default outside bounds")
    }
  }
})

test("an empty document yields every default and no rejections", () => {
  const r = api.load("{}")
  for (const p of api.schemaPaths()) assert.equal(r.values[p], entry(p).def, p)
  assert.deepEqual([...r.rejected], [])
  assert.equal(r.doc.config_version, api.CONFIG_VERSION)
})

test("numeric values are clamped to their bounds", () => {
  assert.equal(api.coerce(entry("bar.height"), 5), 28)
  assert.equal(api.coerce(entry("bar.height"), 999), 60)
  assert.equal(api.coerce(entry("bar.height"), 40.6), 41)
  assert.equal(api.coerce(entry("theme.opacity"), 2), 1.0)
  assert.equal(api.coerce(entry("theme.opacity"), -1), 0.3)
})

test("numeric strings are accepted, booleans and non-numbers are rejected", () => {
  assert.equal(api.coerce(entry("bar.height"), "40"), 40)
  assert.equal(api.coerce(entry("bar.height"), true), undefined)
  assert.equal(api.coerce(entry("bar.height"), "tall"), undefined)
  assert.equal(api.coerce(entry("bar.height"), NaN), undefined)
})

test("enum values must be one of the choices", () => {
  assert.equal(api.coerce(entry("wallpaper.fit"), "contain"), "contain")
  assert.equal(api.coerce(entry("wallpaper.fit"), "spiral"), undefined)
  assert.equal(api.coerce(entry("wallpaper.fit"), 1), undefined)
})

test("colours are normalised to lowercase hex and malformed ones are rejected", () => {
  assert.equal(api.coerce(entry("theme.accent"), " #C8F7EF "), "#c8f7ef")
  assert.equal(api.coerce(entry("theme.accent"), "#fff"), undefined)
  assert.equal(api.coerce(entry("theme.accent"), "red"), undefined)
})

test("strings respect their maximum length", () => {
  assert.equal(api.coerce(entry("lock.custom_greeting"), "hi"), "hi")
  assert.equal(api.coerce(entry("lock.custom_greeting"), "x".repeat(129)), undefined)
  assert.equal(api.coerce(entry("lock.custom_greeting"), 42), undefined)
})

test("invalid values fall back to defaults and are reported by path", () => {
  const r = api.load(JSON.stringify({ bar: { height: "tall", show_date: "yes" }, theme: { accent: "#c8f7ef" } }))
  assert.equal(r.values["bar.height"], 34)
  assert.equal(r.values["bar.show_date"], true)
  assert.equal(r.values["theme.accent"], "#c8f7ef")
  assert.deepEqual([...r.rejected].sort(), ["bar.height", "bar.show_date"])
})

test("a missing key is not reported as rejected", () => {
  const r = api.load(JSON.stringify({ bar: {} }))
  assert.equal(r.values["bar.height"], 34)
  assert.ok(!r.rejected.includes("bar.height"))
})

test("unparseable text and non-object roots throw", () => {
  assert.throws(() => api.load("{ not json"))
  assert.throws(() => api.load("[1,2,3]"))
  assert.throws(() => api.load("null"))
  assert.throws(() => api.load('"text"'))
})

test("unversioned files migrate to the current version", () => {
  const m = api.migrate({ bar: { height: 40 } })
  assert.equal(m.newer, false)
  assert.equal(m.doc.config_version, api.CONFIG_VERSION)
  assert.equal(m.doc.bar.height, 40)
})

test("legacy top-level monitor moves to dock.monitor", () => {
  const m = api.migrate({ monitor: "DP-1" })
  assert.equal(m.doc.dock.monitor, "DP-1")
  assert.equal("monitor" in m.doc, false)
})

test("an existing dock.monitor wins over the legacy key", () => {
  const m = api.migrate({ monitor: "DP-1", dock: { monitor: "eDP-1" } })
  assert.equal(m.doc.dock.monitor, "eDP-1")
})

test("a newer file is reported, returned unchanged and keeps its unknown keys", () => {
  const future = { config_version: 99, future_feature: { on: true }, bar: { height: 40 } }
  const m = api.migrate(future)
  assert.equal(m.newer, true)
  assert.equal(m.doc.config_version, 99)
  assert.equal(JSON.stringify(m.doc.future_feature), JSON.stringify({ on: true }))
})

test("unknown keys survive a save", () => {
  const r = api.load(JSON.stringify({ shortcuts: [{ key: "a" }], metrics_interval: 2 }))
  const text = api.serialize(r.doc)
  const back = JSON.parse(text)
  assert.equal(JSON.stringify(back.shortcuts), JSON.stringify([{ key: "a" }]))
  assert.equal(back.metrics_interval, 2)
})

test("serialize stamps the version and ends with a newline", () => {
  const text = api.serialize({ bar: { height: 40 } })
  assert.ok(text.endsWith("\n"))
  assert.equal(JSON.parse(text).config_version, api.CONFIG_VERSION)
})

test("a saved document loads back to the same values", () => {
  const values = { "bar.height": 44, "theme.accent": "#2dd4bf", "wallpaper.fit": "tile", "lock.weather_units": "F" }
  let doc = {}
  for (const [p, v] of Object.entries(values)) api.writeFor(doc, p, v)
  const back = api.load(api.serialize(doc))
  for (const [p, v] of Object.entries(values)) assert.equal(back.values[p], v, p)
  assert.deepEqual([...back.rejected], [])
})

test("writeFor creates a missing section", () => {
  const doc = {}
  api.writeFor(doc, "nightlight.enabled", true)
  assert.equal(JSON.stringify(doc), JSON.stringify({ nightlight: { enabled: true } }))
})
