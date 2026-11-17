// Unit tests for quickshell/wallpaper/WallpaperPaths.js: the hyprpaper config written for
// per-monitor wallpapers. Run with: node --test tests/
const { test } = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const src = fs.readFileSync(path.join(__dirname, "..", "quickshell", "wallpaper", "WallpaperPaths.js"), "utf8")
  .replace(/^\.pragma library\s*$/m, "") // QML-only directive, not valid JavaScript
const ctx = {}
vm.runInNewContext(src + ";this.api = { confText, parseMonitors, applyCommand };", ctx)
const api = ctx.api

test("parseMonitors reads name=path pairs and skips malformed items", () => {
  const out = [...api.parseMonitors("DP-1=/a.png; HDMI-A-1=/b.png ;bad;=nopath;eDP-1=")]
  assert.equal(JSON.stringify(out), JSON.stringify([{ monitor: "DP-1", path: "/a.png" }, { monitor: "HDMI-A-1", path: "/b.png" }]))
})

test("parseMonitors keeps an = inside the path", () => {
  const out = [...api.parseMonitors("DP-1=/w/a=b.png")]
  assert.equal(out[0].path, "/w/a=b.png")
})

test("confText writes the general block first, then one block per monitor", () => {
  const text = api.confText([{ monitor: "", path: "/main.png" }, { monitor: "DP-1", path: "/a.png" }], "cover")
  const blocks = text.split("wallpaper {").length - 1
  assert.equal(blocks, 2)
  assert.ok(text.indexOf("path = /main.png") < text.indexOf("monitor = DP-1"))
  assert.ok(text.includes("monitor = \n    path = /main.png"))
  assert.ok(text.includes("fit_mode = cover"))
  assert.ok(text.trimEnd().endsWith("splash = false"))
})

test("stretch is written as hyprpaper's fill", () => {
  assert.ok(api.confText([{ monitor: "", path: "/x.png" }], "stretch").includes("fit_mode = fill"))
})

test("paths are passed as arguments, never spliced into the shell script", () => {
  const evil = '/tmp/$(touch PWNED) "q".png'
  const cmd = api.applyCommand([{ monitor: "", path: evil }], "cover", "/state/hp.conf", "/state/log")
  assert.equal(cmd[0], "sh")
  assert.ok(!cmd[2].includes("PWNED"), "script text must not contain the path")
  assert.ok(cmd[4].includes(evil), "the config text is passed as an argument")
})
