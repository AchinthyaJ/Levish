# Levish Feature Audit (Stage A)

Status: audit only. No product code was changed for this document.
Reference: Noctalia v5 docs (docs.noctalia.dev) and repo README, read on 2026-11-15.
Noctalia pages **not read**: Night Light, Notifications, Lock screen, Shell keybinds, Control Center shortcuts, all Services pages, Plugins. Rows that depend on them are marked *unverified*.
Levish code read: `backend/*.py`, `quickshell/shell.qml`, `ThemeStore.qml`, `SettingsWindow.qml`, `WallpaperService.qml`, `Dock.qml`, config files. Control Center, Launcher, PerfPanel, and most settings pages were **not** read line by line. Their "Working" claims are unverified.
Environment: Hyprland 0.57.2 and `qs` (noctalia-qs 0.0.12) are installed. The shell was not launched during this audit.

## 1. Architecture findings

| # | Finding | Evidence | Severity |
|---|---|---|---|
| A1 | Two config owners for the same file. QML `ThemeStore` owns `config/config.json`. Python `backend/config.py` also reads it, with a different `DEFAULTS` schema (for example `bar.height` 42, `theme.bg_primary`). Keys do not agree. | `backend/config.py` DEFAULTS vs `ThemeStore.qml` schema | High |
| A2 | Unit test fails on the live config: `cfg.get("bar.height")` returns 36, test expects 42. Tests read the user's real file instead of a fixture. | `python3 -m unittest discover -s tests` → 1 failure out of 10 | High |
| A3 | `WallpaperService` overwrites `~/.config/hypr/hyprpaper.conf` on every apply. It discards any user hyprpaper config. | `WallpaperService.qml` apply() | High |
| A4 | Wallpaper folder is spliced into a `sh -c` string without escaping. A folder name containing `"` or `$(...)` executes. Same in `Wallpaper.qml` scan. | `WallpaperService.qml` scan(), `settings/pages/Wallpaper.qml:34-45` | High (security) |
| A5 | Hardcoded paths: `/home/achinthyaj`, `Minecraft-Horizon`, `My Death/Leviathan/assets` are scanned for wallpapers. Must go. | `WallpaperService.qml:37-49`, `Wallpaper.qml:34-45` | Medium |
| A6 | Settings is split across three sources: QML `ThemeStore`, Python `Config`, and `config/settings.json`. The last appears unused by the code read. | grep of `settings.json` | Medium |
| A7 | Legacy Eww stack still shipped: `eww/`, `scripts/popup.sh`, `scripts/build-css.sh`, `install.sh` installs eww. README describes Eww. Quickshell is the live shell. | `install.sh:59-70`, README | Medium (confusing, dead code) |
| A8 | Backend state goes through `/tmp/levish/*.json` files plus a Unix socket. Several QML readers use `FileView` with `watchChanges`. Works, but polling and file-based IPC are fragile. | `Data.qml`, `ControlCenter.qml:60-76` | Medium |
| A9 | Dock uses a layer-shell mask with a 1-timer hide/reveal. This is the likely cause of the reported random disappearance. Not reproduced yet. | `dock/Dock.qml:36-69` | Open |
| A10 | `shell.qml` builds the Settings window with `ShellRoot`-level state. Its `open` and `visible` are kept in sync by hand. | `shell.qml`, `SettingsWindow.qml:44-46` | Low |
| A11 | Settings search matches page titles and per-page keywords only. It does not index individual settings. | `SettingsWindow.qml` results | Medium |
| A12 | `ThemeStore` writes are atomic and back up a corrupt file before the first save. Good. The schema-driven design is the right base to keep. | `ThemeStore.qml` | Keep |

## 2. Feature matrix

Legend. Exists: Yes / Partial / No. Condition: Working / Partial / Broken / Unverified / Missing. Action: Keep / Fix / Improve / Add.

### Shell-wide and configuration

| Feature (Noctalia ref) | Exists | Condition | Action |
|---|---|---|---|
| Central config with validation, defaults, atomic save | Partial (QML only) | Working; Python side conflicts (A1) | Fix: one owner |
| Config migration and versioning | No | Missing | Add |
| Backup on corrupt config | Yes | Working | Keep |
| Reset page / reset all | Partial | Works in ThemeStore; reset-section UI exists | Keep, extend |
| Import / export config | No | Missing | Add |
| Hot reload on file change | Yes | Working (FileView watch) | Keep |
| IPC (`qs ipc`) | Yes (`levish` target) | Partial; limited functions | Improve |
| Diagnostics, logs, service health | No | Missing | Add |
| Shell UI scale, corner-radius scale | Partial (radius only) | Partial | Add |
| Transparency mode (solid / soft / glass) | No | Missing | Add |
| Animation enable / speed | No | Missing | Add |
| Reduced motion | No | Missing | Add |
| Font family | Partial (`theme.font_family`) | Working, not exposed in UI? (unverified) | Improve |
| Language / time and date format | Partial (clock only) | Partial | Improve |
| Offline mode / telemetry | No | Missing; Levish sends nothing, so mark as N/A | Document |
| Keybinds editor with conflict detection | Partial (`shortcuts` list in config.json, not applied from QML) | Broken: the list is not consumed | Fix |

### Bar

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Top bar, island layout | Yes | Working | Keep |
| Height, clock format, date and seconds toggles | Yes | Working (ThemeStore) | Keep |
| GPU and temp toggles | Yes | Working | Keep |
| Workspace dot size and radius | Yes | Working | Keep |
| Position top / bottom / left / right | No | Missing | Add |
| Width, margins, padding, opacity, blur, border | Partial (opacity only) | Partial | Add |
| Per-monitor bar | No | Missing | Add |
| Multiple bars / widget ordering / visibility | No | Missing | Add |
| Widgets: active window | Yes | Working (`active_window.json`) | Keep |
| Widgets: volume, network, bluetooth, battery | Yes | Working per backend, unverified in UI | Verify |
| Widgets: tray | No | Missing | Add |
| Widgets: media, notifications, caffeine, night light, keyboard layout, lock keys, privacy, screenshot, session, theme-mode, weather, sysmon, taskbar, custom button, spacer, text, audio visualizer | No | Missing | Add (Stage C/E) |
| Visual bar editor | No | Missing | Add |

### Dock

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Enable / disable | Yes | Working | Keep |
| Auto-hide | Yes | Partial (A9) | Fix |
| Always visible | Yes (inverse of auto-hide) | Working | Keep |
| Position top / bottom / left / right | No (bottom only) | Missing | Add |
| Icon size, margin, opacity | Yes | Working | Keep |
| Spacing, padding, radius, border, shadow | No | Missing | Add |
| Magnification, active / inactive scale | No | Missing | Add |
| Running indicators, instance count | Partial (`running` dots) | Partial | Improve |
| Pinned apps, reordering | Partial (pinned-apps.json) | Partial; drag-reorder unverified | Improve |
| Per-monitor dock | Partial (`dock.monitor`) | Partial | Improve |
| Smart auto-hide (hide when workspace has windows) | No | Missing | Add |
| Launcher button placement | Partial (`LauncherButton.qml`) | Partial | Improve |

### Launcher

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Grid and list views | Yes | Working per config (unverified in UI) | Keep |
| Columns | Yes | Working | Keep |
| Desktop-entry discovery | Yes (`launcher_apps.py`, `apps.py`) | Working (unverified) | Keep |
| Search and recent apps | Yes | Working (unverified) | Keep |
| Fuzzy search, keyboard navigation | Unverified | Unverified | Verify |
| Pinning, hiding, sorting | Partial | Partial | Improve |
| Calculator, emoji, clipboard history, wallpaper provider, window provider, session provider | No | Missing | Add |
| Search prefixes (`/`, `calc`, `emo`) | No | Missing | Add |
| Full vs simple layout | No | Missing | Add |
| Application actions | No | Missing | Add |

### Control Center

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Wi-Fi toggle, list, connect | Yes (`nm.py`, `connect_wifi`) | Backend present; UI unverified | Verify |
| Bluetooth power, devices, pair / connect | Yes (`bluez.py`) | Backend present; UI unverified | Verify |
| Audio output and volume, mute | Yes (`pipewire.py`) | Backend present; UI unverified | Verify |
| Per-application audio | No | Missing | Add |
| Audio input device | No | Missing | Add |
| Brightness | Yes (`brightness.py`) | Working per backend, unverified | Verify |
| Battery, power profiles | Yes (`battery.py`, `profiles.py`) | Working per backend, unverified | Verify |
| Media controls (MPRIS) | Yes (`mpris.py`, `MediaCard.qml`) | Unverified | Verify |
| Night light | No | Missing (Noctalia unverified) | Add |
| Caffeine (idle inhibit) | No | Missing | Add |
| Do Not Disturb | No (no notification daemon in repo) | Missing | Add |
| Weather, calendar, notifications, screen time | No | Missing | Add |
| Network details (IP, SSID, speed) | Partial | Partial | Improve |

### Notifications and OSD

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Notification daemon, popups, history | No | Missing | Add (Stage D) |
| DND, clear all, grouping, actions | No | Missing | Add |
| OSD (volume, brightness, media, keyboard layout) | Partial (`scripts/osd_listener.py` exists; no OSD QML in tree) | Unverified | Verify, then Add |

### Wallpaper

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Wallpaper apply via hyprpaper | Yes | Working, but clobbers user config (A3) | Fix |
| Fit modes (cover, contain, stretch, tile) | Yes | Partial. Noctalia names differ (crop/fit/span/repeat); hyprpaper supports its own set | Improve |
| Folder scan and browse | Yes | Broken-risk (A4, A5) | Fix |
| Auto-rotate with interval | Yes | Working per code | Keep |
| Favourites, history, search, categories | No | Missing | Add |
| Per-monitor wallpaper | No | Missing | Add |
| Transitions | No (hyprpaper transitions not used) | Missing | Add |
| Wallpaper-derived palette | No | Missing | Add |
| Random wallpaper | Yes (`randomize`) | Working | Keep |
| Desktop widgets (add / move / resize / layouts) | No | Missing | Add (Stage E) |

### Settings application

| Feature | Exists | Condition | Action |
|---|---|---|---|
| Native FloatingWindow, resizable, min size | Yes | Working | Keep |
| Sidebar navigation, Escape to close | Yes | Working | Keep |
| Settings search | Partial (A11) | Partial | Improve |
| Overview page | Yes | Partial. Shows config dump style data; not the dashboard the brief asks for | Improve |
| Appearance page | Yes | Partial (accent, opacity, radius, font) | Improve |
| Top bar page | Yes | Partial | Improve |
| Dock page | Yes | Partial | Improve |
| Launcher page | Yes | Partial | Improve |
| Wallpaper page | Yes | Partial, with A4/A5 risk | Fix |
| About page | Yes | Working | Keep |
| Live preview | No | Missing | Add |
| Keyboard navigation through settings | Partial | Unverified | Verify |
| Basic / advanced mode | No | Missing | Add |
| Design system tokens | Partial (`Theme.js`, hardcoded colors in `SettingsWindow.qml`) | Partial. Hex literals scattered across files | Fix |

### Not present in the repo at all (Noctalia features)

| Feature | Condition | Action |
|---|---|---|
| Displays and monitor arrangement, with rollback | Missing. Noctalia has no dedicated Displays page; only per-monitor overrides | Add (Stage D). Use `hyprctl` with a confirm-or-revert timer |
| Keyboard layout and repeat settings | Missing | Add |
| Lock screen | Missing | Add (Stage E). Use an existing locker (`hyprlock`) rather than building auth |
| Session panel and actions | Partial (`PowerMenu.qml`) | Improve |
| Clipboard history | Missing | Add |
| Screenshot tool | Missing | Add |
| Window switcher | Missing | Add |
| Hot corners | Missing | Add |
| Privacy indicators (mic, camera, screen share) | Missing | Add. Only where PipeWire exposes the state |
| Plugins | Missing | Add (Stage F) |
| Calendar and weather | Partial (`scripts/calendar_data.py` for calendar in PerfPanel) | Improve; weather missing |
| Media widget and MPRIS | Partial | Verify and improve |
| Performance dashboard | Yes (`PerfPanel.qml`, `backend/system/metrics.py`) | Keep; check pause-when-hidden and polling |

## 3. Platform limitations to document

- Hyprland has no per-window or per-app audio API. Per-application audio must go through PipeWire node matching.
- Hyprpaper supports a limited set of fit modes and no animated transitions. The Noctalia transition list cannot be matched exactly.
- Camera and microphone privacy indicators depend on PipeWire and portal state. Some apps bypass both, so the indicator can miss them.
- Display rotation and scale changes need `hyprctl keyword monitor` or the monitor config. Changes are not persistent unless the config file is rewritten, which needs the same rollback path.
- Lock screen authentication must stay with a standard PAM-backed locker.

## 4. Recommended order

1. Fix A1 and A2: one config owner, and a test fixture instead of the live file.
2. Fix A3, A4, A5: stop overwriting `hyprpaper.conf`, escape or remove shell interpolation, drop hardcoded paths.
3. Fix the dock visibility cause (A9) before adding dock features.
4. Remove or quarantine the Eww remnants (A7) so the repo describes what runs.
5. Then Stage B (design tokens and Settings window), followed by the feature stages in the brief.

## 5. Open items

- Verify the Control Center, launcher, and OSD in a running session. Nothing in this table was run.
- Read the unread Noctalia pages (Night Light, Notifications, Lock screen, Services, Plugins) and update rows marked *unverified*.
- The uncommitted working-tree changes (Wallpaper page, WallpaperService, Icon, ThemeStore, shell.qml) were not modified by this audit. Review them before committing.

## 6. Progress log

### Pass 1 (fixes A1–A5)

- A1 done. `backend/config.py` defaults cut to backend-owned keys (`metrics_interval`). ThemeStore remains the only owner of theme, bar, dock and wallpaper defaults. Config and pinned-app paths are injectable.
- A2 done. `tests/test_backend.py` config tests use a temp directory. Suite: 14 tests, all pass, and `config/config.json` is byte-identical before and after the run.
- A3 done. Wallpaper apply writes `$XDG_STATE_HOME/levish/hyprpaper.conf` (default `~/.local/state/levish`). `~/.config/hypr/hyprpaper.conf` is never written. Note: an `exec-once hyprpaper` line that reads the old user file will now show a different wallpaper until the shell applies its own.
- A4 done. Folder and image paths are passed as positional arguments (`$1`, `$@`), never spliced into shell text. Checked with a folder named `evil $(touch PWNED) "q" dir`: no injected file created.
- A5 done. Scan roots are system wallpaper dirs, `$XDG_PICTURES_DIR` (or `~/Pictures`) and the user's custom folder. The Minecraft/Leviathan paths are gone.
- Hyprpaper `fit_mode` receives `fill` for ThemeStore's `stretch`.

Not yet done: A6–A11, the dock visibility fix (A9, see below), Eww removal (A7, awaiting decision), and any Stage B work.

### Dock visibility (A9): not reproduced

Candidate causes read from code, none confirmed:

1. `dock/DockSettings.qml` `targetScreens` is a binding that returns a new array on every re-evaluation. `shell.qml` uses it as the `Variants` model. If the Variants delegate recreates dock windows on array identity, every dock window is torn down and rebuilt on any screen or monitor-setting change.
2. `dock/Dock.qml` changes the input mask between the full window and a 16 px strip when auto-hide state flips. Reveal depends on a 600 ms hide timer and a hover handler on the strip.

Next step: reproduce by toggling a monitor or changing `dock.monitor` in a running session, watching the `levish-dock` layer surface count with `hyprctl layers`.

### Test-run side effect (disclosed)

My first unit-test run in this session used the original test file, whose `test_config_set_get` wrote through the live `config/config.json`. That rewrote the file with the old Python defaults and `theme.font_size = 14`. I restored the file to the content read at session start. The current test suite no longer touches it.

### Pass 2 (dock hover, settings fit)

- Dock hides on hover (A9, reproduced by reading the code, fixed): the only reveal handler sat on a sibling of the dock body. The hover-enabled app cells beside it took the pointer, so the handler reported "not hovered" and the 600 ms hide timer fired. Fix: separate hover handlers on the reveal strip and on the dock body feed one `pointerInside` check. Not yet confirmed in a live session.
- Settings content overflow (fixed by code reading, not screenshot): minimum width lowered to 640 with a compact icon-rail sidebar below 820 px. The wallpaper filter and folder rows wrap (`Flow`), and the slider shrinks with its row. Minimum height is 520.
- qmllint: edited files pass with no errors. This does not validate Quickshell-specific types.
- Not verified: no live screenshot or pointer test. Those were stopped by the user's request, so the fixes above are untested in the running session.

### Phase 2 (visual identity)

Done:
- Settings design tokens in `quickshell/common/Theme.js`: window/sidebar/surface levels, text tiers, status colours (ok, warning, danger), type scale, spacing scale, radii, durations. All 28 token names used in Settings are defined (checked).
- Every hardcoded chrome colour in `quickshell/settings` now uses a token. Accent swatch colours stay literal on purpose: they are the user's choices.
- Overview is a dashboard: hero with live accent and glass values, summary tiles (top bar, dock, launcher, glass), wallpaper preview with an error and empty state, clickable accent swatches, backend running check (pid file), config health, recent changes, shortcuts.
- Recent changes: `ThemeStore.setMany` records the last 8 changes for this session only. Not persisted.
- Overview states no release version, because the repository does not define one.

Not done or unverified:
- Settings search across individual settings (currently page titles and keywords only).
- Keyboard navigation through pages.
- Reduced-motion switch: the duration tokens exist but no component reads them yet.
- Visual check of the result: not run in a live session. `qmllint` passes on all Settings files and the new Overview. `qmllint` cannot resolve Quickshell-specific types, so runtime errors are still possible.

### Phase 3, first area: notifications

Done (code written, not yet run in a live session):
- Levish owns `org.freedesktop.Notifications` through Quickshell's `NotificationServer`. Checked before writing: no other daemon was running and nothing else owned the name.
- Popups in a layer-shell window at the configured corner (top or bottom, left or right), clear of the top bar at the top. Each popup shows app, summary, body (plain text only), actions (their `invoke()` runs), and a dismiss button.
- Expiry: the Settings timeout, or the app's timeout if it sets one. Critical notifications never expire. Hovering pauses the timer.
- Do not disturb: runtime state in the service. Not written to config.json.
- Settings are saved to config.json: enabled, timeout (1–60 s), position, and how many popups show at once. Keys are `notifications.*` in ThemeStore.
- History: the last 100 notifications, shown or suppressed (with the reason). Kept in memory for the session, with a Clear button.
- Settings page added to the sidebar, between Wallpaper and About.

Not done in this area:
- Grouping notifications by app.
- App-specific controls (mute one app).
- Inline reply (the server supports it; no UI yet).
- OSD (volume, brightness, keyboard layout), which is a separate Stage D item.
- Per-screen popups: they appear on the compositor's default output.
- Live check: the code is lint-clean, but I have not seen it receive a real notification (for example `notify-send`). That needs a test on your session.
- Lint note: `qmllint` exits 255 on `shell.qml` both before and after my changes, so it does not check that file.

### Phase 3, second area: on-screen display (OSD)

Done (lint-clean, not yet run live):
- `quickshell/osd/Osd.qml`: a click-through overlay above the dock, with an icon, a level bar and a label. Shows for volume (including mute), brightness, and keyboard layout.
- Volume and brightness come from the backend's state files, watched with FileView (inotify). It shows only when a value changes; the first load at startup is silent.
- Keyboard layout comes from Hyprland's `activelayout` event. Event-driven.
- Settings → On-Screen Display: per-event toggles and time on screen (1–6 s). Saved as `osd.*` keys.
- `scripts/launch.sh` no longer starts `scripts/osd_listener.py`. That script polled brightness with a hardcoded `intel_backlight` path, wrote `osd.json`, and nothing read it. The file itself is still in the repo.

Not done or open:
- Media OSD (track changes): needs MPRIS events; the backend exposes track state but not change events.
- `backend/brightness.py` polls sysfs once a second (line ~114). The OSD is event-driven on top of it, but the backend still polls. Removing that poll is a backend change, left for later.
- Whether `backend/audio/pipewire.py` emits on every change depends on its event subscription; not verified in a live session.

### Phase 4, first item: global settings search

Done:
- Search reaches individual settings. Each `SettingsRow` on every page is indexed by its label and hint, read from the live page tree.
- Results show the setting with its page name, and clicking one opens that page.
- Enter in the search box opens the first result.
- Config-key labels (for example recent-change entries) are excluded from the index.
- The walker logic was tested in Node against a simulated tree. The shell reloads with no errors.

Not done:
- Scrolling to and highlighting the exact row after opening a page.
- Keyboard navigation through result lists with arrow keys.
- Basic and advanced modes, live previews, and contextual help beyond the existing row hints.

### Phase 4, second item: keyboard navigation in Settings

Done (reload clean in the shell log; key handlers not exercised live):
- Up and Down move through the sidebar, or through search results when a search is active. The highlighted entry has a focus ring.
- Enter opens the highlighted entry. Escape clears the search, or closes the window when the search is empty.
- Opening a search result for a single setting opens its page and scrolls the setting row into view (the row is 24 px below the top of the page).
- Mouse clicks on the sidebar use the same open path.

Not done:
- Keyboard focus moving into the controls on a page (toggles, sliders). Only the sidebar and results are keyboard-driven.
- Visual highlight on the target row after scrolling.
- Verifying the scroll offset on pages with long content in a live session.
