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

### Phase 3, third area: clipboard history (text)

Done (clean reload in the shell log; the watcher is not yet exercised live):
- `quickshell/clipboard/ClipboardService.qml`: `wl-paste --watch` runs only while the feature is enabled. It is event-driven, so nothing polls.
- Opt-in: off by default (`clipboard.enabled`). History is memory-only and cleared on shell restart. Nothing is written to disk.
- Text only. Copies over 20 000 characters are skipped. Repeated copies move to the top rather than duplicating.
- Settings → Clipboard: enable switch, items kept (5–200), Copy, Pin/Unpin, Delete, Clear unpinned. Pinned items survive trimming.
- Copy back uses `wl-copy` with the text passed as an argument, so quotes and `$(...)` are treated as text.

Not done:
- Launcher integration (search and paste from the clipboard history).
- Clearing the history on clipboard-manager secret hints (password managers). Not verified.
- Image clipboard entries.

Lesson recorded: Quickshell does not see a folder created after the UI process started. After adding a new folder, restart the UI (`qs -p quickshell -d`). Without a restart, imports of that folder fail and the whole configuration is rejected.

### Bar: tray spacing, left-click menus, duplicate Settings button

Done (clean reload in the shell log; not checked visually):
- Background apps (system tray) sit in a zone matched to the status group: same height and padding, 8 px between icons.
- Left click on a tray app opens its menu when it has one (`display`), or activates it when it has none. Right click opens the menu, or runs the secondary action.
- The Settings gear is removed from the Control Center. The top bar keeps its button, so Settings has one entry point.

Not verified: tooltips on tray icons (tray titles were not checked against this Quickshell build), and how the native menu positions on your monitor layout.

### Tray menus: root cause and fix

- Root cause (from the shell log after clicks): `Cannot display PlatformMenuEntry as quickshell was not started in QApplication mode`. Tray menus need the root file to declare `//@ pragma UseQApplication`. Without it, every left click failed silently.
- Fix: the pragma is now the first line of `quickshell/shell.qml`. The UI was restarted. The log loads with zero errors.
- Tray icon names: icons are now resolved through the icon theme (`Quickshell.iconPath`), since tray icons are usually theme names.
- Registered tray items (checked with `busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems`): Steam and one other app were registered at the time of the check.
- Quickshell registers only `org.kde.StatusNotifierWatcher`, not the freedesktop name. Apps that look only for the freedesktop name will not appear. This was not observed in this session.
- Not verified: the menu itself opening, and its position. Check by left-clicking Steam's tray icon; a menu error would appear in `/run/user/1000/quickshell/by-id/*/log.log`.

### Tray: icons and styled menus (second pass)

- Icons: Quickshell already supplies a usable URL for tray icons (`image://icon/…` for theme names, `image://qspixmap/…` for pixmaps). My earlier `Quickshell.iconPath` wrapper broke them, so it is gone. Verified from the live log: `icon=image://icon/steam_tray_mono?path=…`.
- Menus: the native menu cannot be styled, so the menu is drawn in QML with Levish's glass look.
  - `bar/TrayMenu.qml`: popup under the clicked icon, plus a full-screen click catcher that closes it on any press outside.
  - `bar/TrayMenuEntries.qml`: items from `QsMenuOpener`, with icons, separators, disabled state and submenus expanded inline (recursive).
  - Choosing an item triggers it (`triggered()`) and closes the menu.
- Debug line removed. The UI was restarted; the log loads with zero errors.
- Not verified: clicking an icon and seeing the menu. Known gaps: checkbox and radio items show no check mark yet; the catcher blocks clicks on other windows while a menu is open; there is no keyboard navigation in the menu.

### Batch: keyboard, displays, night light, caffeine

Done (clean reload in the shell log; night light and caffeine not yet switched on live):
- Keyboard & Shortcuts (read-only): lists every Hyprland bind from hyprctl (93 at check time), with conflict detection for the same key combination in the same submap. Editing is not offered.
- Displays (read-only): name, description, resolution, refresh rate, scale, position and available modes for each monitor. Changing a display is not offered (needs confirm-or-revert first).
- Night light: saved in config.json (off by default, 2500–6500 K). Runs hyprsunset, which stays running as a daemon (checked). Restarts when the temperature changes. Reports "unavailable" if hyprsunset fails.
- Caffeine: runtime only. Holds a systemd idle inhibitor while on, released when turned off or the shell restarts.
- Installed: hyprlock, hypridle, hyprsunset.

Still not done (by area): Control Center rework; launcher calculator, emoji, clipboard and wallpaper providers; notification grouping and per-app mute; OSD for media; top bar and dock customisation, including the dock hide bug (blocked on noctalia-qs); wallpaper library, per-monitor and transitions; desktop widgets; lock screen and idle (hyprlock and hypridle installed but not configured); display changes with rollback; privacy indicators; calendar and weather; plugins; profiles, import/export and backup; diagnostics; accessibility (reduced motion, keyboard focus into controls); basic and advanced modes; live previews.

### Lock screen and idle

Done (clean reload; the lock itself has NOT been tested, to avoid locking the session during development):
- quickshell/lock/LockService.qml writes two Levish-owned configs to ~/.local/state/levish: hyprlock.conf (wallpaper background, accent-coloured input field, large clock and date) and hypridle.conf (auto-lock timeout, lock before sleep, resume display). The user config in ~/.config/hypr is never touched.
- Authentication is unchanged: hyprlock still checks the normal password through PAM.
- hypridle runs only when auto-lock is set above 0 minutes or lock-before-sleep is on. Both default to off, so no idle daemon starts by default.
- Settings → Lock & Idle: auto-lock timeout (0–60 min), lock before sleep, Lock now.
- Configs are rewritten when the wallpaper or accent changes.

Not verified: that hyprlock accepts the generated config (only lockable by running it), and that hypridle locks on timeout.

Known gap: the power-menu and Control Center Lock action runs "loginctl lock-session" first, which reports success even when nothing listens for it. It locks only while hypridle is running. Switching that action to the Levish hyprlock config is a separate change, not made yet.

### Lock from the top bar and Control Center

- The power-menu Lock and the Control Center Lock both send the backend "lock" action. backend/power/power.py now starts hyprlock with the Levish config ($XDG_STATE_HOME/levish/hyprlock.conf) first, detached and not awaited, so the menu returns at once.
- A second lock request while the first is still running does nothing.
- Fallbacks if the config or hyprlock is missing: loginctl, then hyprlock with its default config, then swaylock.
- Tested with a fake hyprlock on PATH: the Levish config path is passed and a second request is suppressed. Unit tests pass (14 of 14). The backend was restarted.
- Not tested: an actual lock. Test it by pressing the power-menu Lock and unlocking with your password.

### Release pass (v1.0.0)

- Dock auto-hide (A9, "refuses to hide again"): fixed. Cause: the hover signal read the derived `pointerInside` binding, which still held the previous value at that moment, so a leave event looked like "still inside" and nothing scheduled a hide. Each hover handler now acts on its own `hovered` value, and the hide timer checks both handlers when it fires. Verified against the layer surface height (16 px hidden, 126 px shown): four hover-in and leave cycles all hid correctly; resting in the body kept it open; moving within the body did not hide it; leaving hid it. TEMP trace logs removed. One earlier run stopped revealing on hover; a shell reload cleared it, and the same sequence on a fresh instance did not reproduce it. Watch for it.
- Keyboard brightness keys: added `brightnessUp` and `brightnessDown` IPC functions (5 % steps through the backend's `adjust_brightness`). Added to the Hyprland keybind list. Four rapid presses were all applied (23 % → 3 %) and restored to 23 %.
- Control socket commands now go through an ordered queue, so no relative step is dropped.
- Release cleanup: Eww stack, unrelated installer script, unused scripts, legacy `settings.json` and the unused `shortcuts` list removed. Native lock option removed (never connected). Weather module off by default. Wi-Fi device no longer hard-coded. Version 1.0.0 added (`VERSION`, `quickshell/common/Version.js`).
- Open before release: `config/config.json` still holds a home-directory wallpaper path; the native lock files under `quickshell/lock/` (`LockSurface.qml`, `PamAuth.qml`, `pam/passwd`) are untracked and unused; no LICENSE yet; screenshots not yet replaced.

### Stage 1 (re-audit against the code)

Method: every key that Settings writes was checked against the schema in `ThemeStore.qml`, and every schema entry was checked for a reader in the QML outside Settings (by its `prop` name). This verifies that a control writes a key that is defined and that something reads it. It does not prove the effect works on screen.

Results:
- All keys the Settings pages write are defined in the `ThemeStore` schema. No orphan writes.
- Corner radius is dead. `theme.radius` (`cornerRadius`) is in the schema, but nothing reads it, and no Settings page has a control for it. Surfaces use the constants in `common/Theme.js` (`radiusIsland`, `dockRadius`, `dropRadius`). Earlier in this document, Appearance was listed as having a radius control. That was wrong. Fix: either wire the constants to the setting or remove the key.
- Dock opacity is live. `dock.opacity` reaches the dock through `ThemeStore.dockGlass`.
- Bar, lock, OSD and notification keys all have readers under their `prop` names.

Session changes (not yet verified on screen):
- Dock: unpinned running apps were missing. Root cause: `Hyprland.refreshToplevels()` only ran at shell start, so a new window's class (`lastIpcObject`) stayed empty and the dock skipped it. Fix: each Hyprland event now requests a toplevel refresh, and the dock re-checks when a window's IPC data arrives. Dots are now one per open window, with the focused window's dot stretched.
- Dock debug logging was added and removed again. No `DOCKDBG` lines remain.
- Settings: `components/PageScrollBar.qml` is attached to all 14 pages as a vertical scroll slider. It loads without QML errors. Not checked on screen.

Still open:
- A visual check of the dock with an app opened from the application menu. The fix has not been confirmed on screen.
- Dead corner-radius setting (above).
- Stage 2 of the brief (configuration, state management, reusable components) and the feature stages are not started.

### Settings scrollbars (sidebar and pages)

- Pages: `components/PageScrollBar.qml` is attached to all 14 pages.
- Sidebar: the navigation entries (or search results) are in a `Flickable` with the same scrollbar. Up/Down keep the focused entry in view. Search and the save-status footer stay fixed.
- The shell loads with no QML errors. Not yet checked on screen.

### Stage 2 (configuration architecture)

Done:
- One validator for the whole config. `quickshell/common/ConfigSchema.js` holds the schema (67 keys), the coercion rules, the migrations and the serialiser. It has no Qt dependency. `ThemeStore.qml` now calls it and no longer carries its own copy of the schema.
- Versioning. Files carry `config_version` (currently 1). Unversioned files are version 0. Migrations are an ordered list, so a future change adds an entry rather than editing old ones.
- Migration 0→1 moves the legacy top-level `monitor` key to `dock.monitor` (an existing `dock.monitor` wins).
- Newer files are protected. A file with a higher `config_version` loads, but nothing is written to it, so this Levish cannot downgrade it. The Settings status line says so.
- Unknown keys survive every save (for example `shortcuts`, `metrics_interval`).
- Tests: `tests/config_schema.test.js`, 18 tests (run with `node --test tests/`). They cover every schema default, bounds and enum choices, coercion of each kind, rejected values, migration, newer-version handling, unknown-key preservation and save/load round-trips. All pass.

Not done in Stage 2:
- Import and export. `ConfigSchema.js` can load and serialise, but no UI or ThemeStore call uses it yet.
- Rolling backups. Only a corrupt file is backed up, once.
- Dead key `theme.radius` (see Stage 1). It is still in the schema and still has no reader. Decide: wire it to the surfaces or remove it.
- Python `backend/config.py` keeps its own small defaults. It is limited to backend-owned keys, but it is not generated from the schema.
- `tests/test_release.py` fails on the user's live `config/config.json`, which contains `/home/achinthyaj/Pictures/...`. This was failing before Stage 2. Fix by changing the wallpaper path, or by making the test check the shipped defaults rather than the live file.
- QML side not run through a live check of the load path beyond a clean reload. The validator itself is covered by the Node tests.

### Corner radius (fixed)

- Appearance → Glass now has a "Corner radius" slider (4–28 px), writing `theme.radius`. It is also in that page's reset list.
- The dock reads it through `DockSettings.cornerRadius`. The dock's glass body and its shadow layers use it.
- Not wired: the rest of the live bar and the panels still use their own fixed radii. Making them follow the setting is a larger change; decide whether it is wanted.
- `bar/Island.qml` is not used by anything in the tree. It is dead code and can be removed.

### Stage 3 (visual foundation)

Checked first: Settings already draws its colours from `common/Theme.js`. Only three literals remained (the accent fallback in Lock, the scrollbar default, and the swatch list, which is a user choice on purpose).

Done:
- Reduced motion. New key `ui.reduced_motion` with a switch in Appearance → Motion. `Theme.dur(ms)` scales short animations (every literal duration of 600 ms or less, 91 places in 25 files). Changes apply to animations that start after the setting changes, so a full switch needs a shell restart.
- Last visited page. New key `settings.last_page`. Settings opens on it, and each navigation saves it (no write when the page is unchanged).

Not done in Stage 3:
- Longer animations (700 ms and up, lock-screen loops and the 1 s clock pulse) still ignore reduced motion.
- Basic and advanced modes: no rows are marked as advanced yet.
- Breadcrumbs on each page.
- Overview hero and preview tiles were not re-checked against the brief.
- Nothing was viewed on screen in this stage.

### Batch: finishing Stages 2–3

- Reduced motion now covers the 700 ms, 800 ms and 1000 ms transitions too (`common/Ring.qml`, `lock/auth/PasswordField.qml`, `lock/clock/HeroClock.qml`). Only the long lock-screen loops (14–22 s) still run at full speed by design.
- Export and import. `ThemeStore.exportText()` and `importText(text)` use the same validator and migrations as the loader. Import changes only the keys the file contains, rejects a file from a newer Levish, and lists any values reset to default. About → Export and import is the UI (text areas, no file dialog). Not run live.
- Breadcrumb in the Settings header ("Settings › Page").
- `bar/Island.qml` deleted (unused).
- Still open: basic and advanced modes, a rolling backup on every save, a rewrite of the remaining Stage 4–7 features, and the `test_release.py` home-path failure, which needs your decision about `config/config.json`.

### Stage 4 (core customisation): partial

Done (schema, store, consumer and Settings control for each):
- Top bar zones can be hidden: performance, workspaces, window title, clock, status indicators, tray (`bar.show_*`, Top Bar → Zones).
- Dock spacing between icons (`dock.spacing`, 0–24 px) and hover enlargement (`dock.zoom`, 100–150 %). Both on Dock → Size and position.

Not done in Stage 4:
- Top bar position (top/bottom), width, margins and padding, border, and widget ordering. The bar is anchored to the top edge in `bar/Bar.qml`, so position needs a layout change.
- Dock position (left/right/top) and magnification curve.
- Appearance: font size and weight, UI density, border visibility, shadow intensity, theme mode (light/dark), wallpaper-derived colours, and import or export of named themes.
- Launcher: icon size, sort order, hidden apps, and per-entry actions.
- Wallpaper: per-monitor wallpapers, scheduled changes, and a wallpaper library with favourites.
- Lock screen: most options already exist in the schema, but the Settings page has not been checked against the brief.
- Nothing from Stage 4 has been viewed on screen.

### Stage 4 (core customisation): status after the full pass

Done (schema key, store property, consumer, Settings control and reset entry for each):
- Top bar: zones can be hidden (performance, workspaces, window title, clock, status, tray). Edge (top or bottom), distance from the edge, side margins, corner radius and an optional outline.
- Dock: icon spacing, hover enlargement, shadow strength, and border strength (shared with panels through `theme.border`).
- Appearance: text size (`theme.font_scale`, every literal pixel size goes through `Theme.fs`), border strength, and an accent taken from the wallpaper (ImageMagick average, saturation raised; needs `magick` installed).
- Launcher: icon size, sort order (name or pinned first), and a hidden-applications list (comma-separated desktop IDs).
- Wallpaper: per-monitor images. hyprpaper gets one block per override, with the general wallpaper first. Covered by `tests/wallpaper_paths.test.js`, which checks that paths are passed as arguments, not spliced into the shell script.
- Lock screen: the four text and image fields that had no control (greeting, wallpaper path, avatar, weather location) now have one.
- Dead `Island.qml` removed.

Known limits, not done:
- Dock position (left, right, top). The dock's hover and auto-hide geometry is written for the bottom edge.
- Light and dark theme modes. The palette is a single dark set and there is no light palette.
- Density. No setting changes spacing across the shell.
- Wallpaper favourites, history and a library view. Only the gallery and interval rotation exist.
- Time-of-day wallpaper schedules. Only the interval rotation exists.
- Font family has a control (Appearance → Typography) and is applied only on the lock screen. Other text uses the system default.
- Text size, motion and the top bar edge are read when items are created. A change takes full effect after a shell restart. The edge change is applied on the next layout pass.
- The hidden-applications field is a text list, not per-app checkboxes.
- Nothing from this pass has been viewed on screen. The shell loads with no QML errors and the Node tests pass (23 of 23).

### Stage 4: dock position

- `dock.position` (bottom, top, left, right) with a control in Dock → Size and position.
- The dock window anchors to the chosen edge. Items lay out in a row on the top and bottom edges and a column on the sides. Dots sit on the outer side, and tooltips open toward the middle of the screen.
- Verified: the shell reloads with no QML errors. On the bottom edge the surface is unchanged (422×16 when auto-hidden). On the left edge the surface was 138×422 when shown, with auto-hide off.
- Not verified on screen: the side layouts and the hover reveal for side docks. A fullscreen game on the same workspace covers the Top layer, and I couldn't get a clean capture. The reveal zone for side docks has not been tested.
- The temporary change to `config/config.json` for this check was reverted; the file's checksum matches the original.
- Not moved: the on-screen overlays (OSD and the top-bar popups) still assume a top or bottom bar and the bottom dock.

### Audio, stage 1: native PipeWire backend and Sound page

Audit first:
- `backend/audio/pipewire.py` shells out to `wpctl` and `pactl` and parses their text. The Control Centre reads that state. It has no per-application mixer, and no way to change the default device.
- Quickshell ships a native PipeWire module (`Quickshell.Services.Pipewire`) with nodes, the default sink and source, stream detection, and volume and mute on each node. The new code uses it.

Done:
- `quickshell/audio/AudioService.qml`: one instance in `shell.qml`. It tracks every node with `PwObjectTracker`, and exposes output devices, input devices (monitor sources excluded) and playing applications. It can set the default output or input, and set volume and mute.
- Settings → Sound (after Displays): status (PipeWire connected, default output), output devices (default badge, "Use as default", volume, mute), input devices (same), and an application mixer (icon, name, volume, mute). Each section has an empty state.
- Checked on screen with real devices: the default output and input show, and the volume and mute controls appear. Nothing was playing, so the application mixer showed its empty state.

Not done in this stage:
- Playing audio through a test tone, and checking the application mixer with a real stream. Not run, to avoid making noise.
- Moving a stream to another output. Quickshell's API does not create links, so this needs `pw-metadata` or a native link call.
- Input routing per application, ports and profiles, microphone level meter, noise suppression, sample rate, channels, latency and diagnostics.
- Hotplug handling is reactive through the node list, but unplugging a device has not been tested.
- The Control Centre still reads the older `wpctl`/`pactl` backend. Moving it to this service removes the duplicate integration; that is the next step.
- Network and Bluetooth dedicated pages, and the floating islands mode, are not started.
