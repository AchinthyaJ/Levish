# Configuration reference

Levish keeps its settings in `config/config.json`. You can change nearly everything from **Levish Settings** (open it with `toggleSettings`, see [Keybinds](../README.md#keybinds)), and every change is written back to this file. You can also edit the file by hand: Levish watches it and reloads on save. A value that is out of range or the wrong type is replaced by its default, and the Overview page in Settings lists the keys that were reset.

If `config/config.json` is corrupt, Levish copies it to `config/config.json.bak` before it writes anything, then runs on defaults until you fix or replace the file.

## Files

| File | Owner | Purpose |
|---|---|---|
| `config/config.json` | Quickshell (`quickshell/common/ThemeStore.qml`) | Appearance, bar, dock, launcher, wallpaper, notifications, OSD, clipboard, night light, lock screen |
| `config/pinned-apps.json` | Backend (`backend/config.py`) | Apps pinned to the dock and the launcher, and the recent-apps list |

Keys in `config.json` that Levish does not recognise are kept as they are, so you can add your own notes without losing them.

## Backend-owned keys

| Key | Type | Default | Meaning |
|---|---|---|---|
| `metrics_interval` | number (seconds) | `2` | How often the backend samples CPU, memory, network and temperatures. Lower values make the performance panel more responsive and cost a little more CPU. |

## `pinned-apps.json`

```json
{
  "dock": ["brave", "thunar", "kitty", "code"],
  "launcher_pinned": ["brave", "thunar", "kitty", "code", "discord"],
  "recent": []
}
```

Each entry is a desktop-entry ID (the name of a `.desktop` file without the extension), such as `brave` for `brave-browser.desktop` or `kitty` for `kitty.desktop`. `recent` is maintained by Levish; you can clear it.

## Settings keys (`config.json`)

Types: `bool`, `int`, `real` (decimal), `enum`, `string`, `color` (a `#rrggbb` hex string). A value outside the stated range falls back to the default.


### `theme`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `theme.accent` | color | `"#c8f7ef"` |  |
| `theme.opacity` | real | `0.85` | 0.3–1.0 |
| `theme.radius` | int | `22` | 4–28 |
| `theme.font_family` | string | `"JetBrains Mono"` | max 64 chars |

### `dock`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `dock.opacity` | real | `0.76` | 0.3–1.0 |
| `dock.enabled` | bool | `true` |  |
| `dock.icon_size` | int | `48` | 24–96 |
| `dock.auto_hide` | bool | `false` |  |
| `dock.margin` | int | `10` | 0–200 |
| `dock.monitor` | string | `""` | max 64 chars |

### `bar`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `bar.height` | int | `34` | 28–60 |
| `bar.clock_format` | enum | `"HH:mm"` | HH:mm / hh:mm AP |
| `bar.show_date` | bool | `true` |  |
| `bar.show_seconds` | bool | `false` |  |
| `bar.show_gpu` | bool | `true` |  |
| `bar.show_temp` | bool | `true` |  |
| `bar.ws_width` | int | `40` | 20–64 |
| `bar.ws_height` | int | `14` | 8–24 |
| `bar.ws_radius` | int | `7` | 3–12 |

### `launcher`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `launcher.default_view` | enum | `"grid"` | grid / list |
| `launcher.columns` | int | `5` | 3–8 |

### `wallpaper`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `wallpaper.path` | string | `"/usr/share/hypr/wall0.png"` | max 4096 chars |
| `wallpaper.folder` | string | `""` | max 4096 chars |
| `wallpaper.fit` | enum | `"cover"` | cover / contain / stretch / tile |
| `wallpaper.auto_rotate` | bool | `false` |  |
| `wallpaper.interval` | int | `1800` | 30–86400 |

### `notifications`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `notifications.enabled` | bool | `true` |  |
| `notifications.timeout_ms` | int | `5000` | 1000–60000 |
| `notifications.position` | enum | `"top-right"` | top-right / top-left / bottom-right / bottom-left |
| `notifications.max_visible` | int | `3` | 1–6 |

### `osd`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `osd.volume` | bool | `true` |  |
| `osd.brightness` | bool | `true` |  |
| `osd.keyboard` | bool | `true` |  |
| `osd.timeout_ms` | int | `2000` | 800–6000 |

### `clipboard`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `clipboard.enabled` | bool | `false` |  |
| `clipboard.max_items` | int | `50` | 5–200 |

### `nightlight`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `nightlight.enabled` | bool | `false` |  |
| `nightlight.temperature` | int | `4000` | 2500–6500 |

### `lock`

| Key | Type | Default | Range / choices |
|---|---|---|---|
| `lock.timeout_min` | int | `0` | 0–120 |
| `lock.before_sleep` | bool | `false` |  |
| `lock.layout` | enum | `"cinematic"` | cinematic / editorial / minimal / split |
| `lock.clock_format` | enum | `"HH:mm"` | HH:mm / hh:mm AP |
| `lock.show_seconds` | bool | `false` |  |
| `lock.clock_scale` | real | `1.0` | 0.7–1.6 |
| `lock.use_desktop_wallpaper` | bool | `true` |  |
| `lock.custom_wallpaper_path` | string | `""` | max 4096 chars |
| `lock.blur` | int | `32` | 0–64 |
| `lock.dimming` | real | `0.45` | 0.0–0.95 |
| `lock.vignette` | real | `0.5` | 0.0–1.0 |
| `lock.ambient_effects` | bool | `true` |  |
| `lock.reduced_motion` | bool | `false` |  |
| `lock.show_greeting` | bool | `true` |  |
| `lock.custom_greeting` | string | `""` | max 128 chars |
| `lock.show_display_name` | bool | `true` |  |
| `lock.show_username` | bool | `true` |  |
| `lock.show_hostname` | bool | `false` |  |
| `lock.custom_avatar` | string | `""` | max 4096 chars |
| `lock.show_weather` | bool | `false` |  |
| `lock.weather_location` | string | `""` | max 128 chars |
| `lock.weather_units` | enum | `"C"` | C / F |
| `lock.show_battery` | bool | `true` |  |
| `lock.show_network` | bool | `true` |  |
| `lock.show_media` | bool | `true` |  |
| `lock.show_uptime` | bool | `false` |  |
| `lock.hide_sensitive_media` | bool | `false` |  |
| `lock.hide_user_details` | bool | `false` |  |
| `lock.disable_widgets` | bool | `false` |  |

