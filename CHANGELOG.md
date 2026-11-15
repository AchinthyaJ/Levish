# Changelog

All notable changes to Levish are recorded here. Levish follows [Semantic Versioning](https://semver.org).

## 1.0.0

First release. Levish is now a Quickshell shell for Hyprland. The earlier Eww prototype has been removed.

### Added

- Floating top bar with performance, workspace, active window, clock and status islands. System tray with menus.
- Performance panel: CPU, memory, GPU, storage and network, with a network graph.
- Control center: Wi-Fi, Bluetooth, volume, brightness, power profiles, media controls, Lock, Sleep and Restart.
- Power menu: Lock, Suspend, Restart, Shutdown, Logout.
- Dock with pinned and running applications, running indicators, and auto-hide.
- Application launcher with grid and list views and recent apps.
- Notifications: popups with actions, expiry, do-not-disturb and history.
- On-screen display for volume, mute, brightness and keyboard layout.
- Wallpaper management through hyprpaper: folder scan, rotation and fit modes.
- Clipboard history (opt-in, text only, in memory).
- Night light (hyprsunset) and caffeine (idle inhibitor).
- Lock screen through hyprlock with a generated Levish configuration, four layouts, and optional auto-lock and lock-before-sleep through hypridle.
- Levish Settings: overview, a page per area, search across settings, keyboard navigation, and read-only views of Hyprland keybinds and monitors.
- Keyboard brightness keys: `brightnessUp` and `brightnessDown` IPC functions, 5 % per press.
- `scripts/levish-ipc.sh` for binding keys in Hyprland.
- Installer for Arch-based systems (`install.sh`).
- Unit tests for the backend, config handling, and release consistency (`tests/`).
- Documentation: README, configuration reference (`docs/CONFIGURATION.md`), development audit (`docs/FEATURE_AUDIT.md`).

### Changed

- The settings file is owned by one component (the QML config store). The backend reads only the keys it uses.
- Wallpaper state, the hyprpaper configuration and the hyprlock and hypridle configurations are written to `~/.local/state/levish`. Your `~/.config/hypr` files are not changed.
- Wallpaper folders are passed to shell commands as arguments, never spliced into shell text.
- The lock screen and power menu lock through hyprlock with the Levish configuration.
- The weather module on the lock screen is off by default. It contacts `wttr.in` only when turned on.
- The dock hides after the pointer leaves for 600 ms, and reveals when the pointer reaches the bottom edge.
- Control socket commands are sent in order through a queue. No command is dropped while another is in flight.

### Fixed

- Dock auto-hide: after the dock appeared, it did not hide again. Hover state is now tracked from each hover handler directly, so a leave event always hides the dock.
- Tray menus did not open. The shell now runs with `UseQApplication`.
- Wi-Fi disconnect used a hard-coded `wlan0` device. It now uses the Wi-Fi device found on the machine.
- The Wi-Fi scan and connect paths no longer depend on one interface name.
- Wallpaper folder scanning no longer runs shell code from folder names.
- Backend configuration tests use a temporary file and never change the user's configuration.

### Removed

- The Eww widget stack (`eww/`, `scripts/popup.sh`, `scripts/build-css.sh`).
- Unused scripts: the OSD listener (replaced by the in-shell OSD), `calendar_data.py`, `launcher_apps.py`, `dock_apps.py`.
- `config/settings.json`, a legacy file that nothing read.
- The `shortcuts` list in `config/config.json`. It was never applied. Keybinds are set in your Hyprland config.
- The "native" lock screen option. It was never connected to the shell. The lock screen uses hyprlock.
- An unrelated third-party installer script that had been committed to the repository.

### Known limitations

See the README, [Known limitations](README.md#known-limitations).
