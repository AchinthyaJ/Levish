# Levish

**Levish** is a complete, modern, and unified desktop shell built specifically for **Hyprland** on Wayland. Designed from the ground up to feel like a cohesive operating system environment rather than a collection of disconnected widgets.

---

## 🎨 Visual Architecture & Design Language

- **Floating Island Top Bar**: Modular top bar composed of independent floating islands rather than a continuous strip.
- **Deep Dark Theme**: Centralized styling system based on SCSS and CSS custom variables (`#1a1a2e`, `#16213e`, `#e94560`).
- **Smooth Interaction**: Subtly rounded corners, carefully tuned drop-shadows, responsive hover cues, and transitions.
- **Low Footprint**: Python 3 asyncio backend with event-driven subscriptions, minimizing polling and CPU consumption.

---

## 🚀 Component Overview

### 1. Top Bar Floating Islands
- **Island A: Performance Monitor (Far Left)**
  - Real-time CPU%, RAM%, GPU%, and CPU temperatures.
  - Clicking/hovering opens the **System Dashboard**:
    - **Performance**: Per-core metrics, RAM & Swap breakdown, GPU VRAM & temps, Upload/Download bandwidth.
    - **Media**: Current track, artist, album, album art, playback controls (MPRIS).
    - **Calendar**: Interactive monthly calendar with active day highlight.
    - **System**: Hostname, kernel, uptime, CPU model, distribution.
- **Island B: Workspace Dots (Left-Center)**
  - Hyprland workspace indicator dots.
  - Active workspace highlighted, occupied workspaces indicated.
  - Instant workspace switching on click.
- **Island C: Active Window (Center)**
  - Real-time window title and class tracking via Hyprland IPC socket.
- **Island D: Clock (Right-Center)**
  - Formatted time and date display with automatic updates.
- **Island E: System Indicators & Power (Far Right)**
  - NetworkManager status pill (Wi-Fi SSID, signal strength, connectivity).
  - Bluetooth status indicator.
  - PipeWire volume indicator with mute status.
  - Battery capacity and charging state indicator.
  - Dedicated **Power Button**:
    - 5-action quick power menu (Lock, Suspend, Restart, Shutdown, Logout).
    - Keyboard shortcut hints (1–5).

### 2. System Controls Panel
Quick-access panel opened from the system indicators:
- **Wi-Fi**: Toggle adapter, view SSID, signal metrics.
- **Bluetooth**: Toggle power, view paired devices.
- **Audio**: Interactive volume slider, mute toggle (PipeWire).
- **Brightness**: Interactive backlight slider (brightnessctl / sysfs).
- **Battery**: Real-time status and health progress indicator.

### 3. Floating Bottom Dock
- Pinned favorite applications.
- Running application dot indicators.
- Focused application accent styling.
- Left-click to launch/focus, right-click actions.
- Persistent configuration via `config/pinned-apps.json`.

### 4. Application Launcher
- Windows-inspired grid and list application menu.
- Full `.desktop` file discovery across `/usr/share/applications` and `~/.local/share/applications`.
- Fast instant search filtering by name and categories.
- Launch applications detached from shell session.

### 5. On-Screen Display (OSD)
- Dock-style floating OSD inspired by modern shells.
- Triggered dynamically when volume or brightness changes.
- Smooth slide-up transition with automated 2.5s inactivity dismissal.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Compositor** | Hyprland (Wayland) |
| **Widget Engine** | Eww (ElKowar's Wacky Widgets) |
| **Frontend Style** | Yuck (S-expressions) + SCSS |
| **Core Backend** | Python 3 (Asyncio, D-Bus, IPC Sockets) |
| **Sound & Media** | PipeWire (`pactl`), MPRIS (`playerctl`) |
| **Connectivity** | NetworkManager (`nmcli`), BlueZ (`dbus`) |
| **Hardware Controls** | `brightnessctl`, `/sys/class/backlight`, `/sys/class/power_supply` |

---

## 📦 Installation & Setup

### Automated Installation
Run the installer to set up dependencies and permissions:
```bash
git clone <repo-url> Levish
cd Levish
chmod +x install.sh
./install.sh
```

### Manual Dependencies (Arch Linux / CachyOS)
```bash
sudo pacman -S --needed hyprland python python-psutil python-dbus python-gobject pipewire networkmanager bluez bluez-utils brightnessctl playerctl
yay -S eww
```

---

## 🎮 Usage & Management

### Launching Levish
```bash
./scripts/launch.sh
```

### Development Mode (Foreground & Debug Logging)
```bash
./scripts/dev.sh
```

### Hot-Reloading Configuration
```bash
./scripts/reload.sh
```

### Stopping Levish
```bash
./scripts/stop.sh
```

### Hyprland Autostart Integration
Add this line to your `~/.config/hypr/hyprland.conf`:
```ini
exec-once = /path/to/Levish/scripts/launch.sh
```

To bind launcher toggle to a key (e.g. `SUPER`):
```ini
bind = SUPER, SUPER_L, exec, eww open --toggle levish-launcher --config /path/to/Levish/eww
```

---

## ⚙️ Configuration

- `config/settings.json`: Theme colors, bar metrics, dock geometry, OSD timeouts, and monitor assignment.
- `config/pinned-apps.json`: Pinned applications for the bottom dock and launcher.
