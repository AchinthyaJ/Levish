import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../components"
import "../../common/Theme.js" as Theme

Flickable {
    id: page
    property var themeStore
    property var lock                  // LockService
    property string pageId: ""
    property string keywords: "lock screen locking idle timeout sleep suspend password hyprlock hypridle clock wallpaper weather layout blur pam"

    readonly property var resetPaths: [
        "lock.timeout_min", "lock.before_sleep", "lock.layout",
        "lock.clock_format", "lock.show_seconds", "lock.clock_scale",
        "lock.use_desktop_wallpaper", "lock.blur", "lock.dimming", "lock.vignette",
        "lock.ambient_effects", "lock.reduced_motion", "lock.show_greeting",
        "lock.show_display_name", "lock.show_username", "lock.show_hostname",
        "lock.show_weather", "lock.weather_units", "lock.show_battery",
        "lock.show_network", "lock.show_media", "lock.show_uptime",
        "lock.hide_sensitive_media", "lock.hide_user_details", "lock.disable_widgets"
    ]
    readonly property color accent: themeStore ? themeStore.accentColor : "#c8f7ef"

    contentHeight: col.implicitHeight + 60
    clip: true

    ColumnLayout {
        id: col
        x: Theme.space5; y: Theme.space4
        width: page.width - Theme.space5 * 2
        spacing: Theme.space3

        // 1. Locking & Backend
        SettingsCard {
            title: "Locking & Security"

            SettingsRow {
                label: "Lock after being idle"
                hint: page.themeStore.lockTimeoutMin === 0 ? "Never. The screen is locked only when you lock it."
                                                           : "Locks after " + page.themeStore.lockTimeoutMin + " minute(s) without input."
                SettingsSlider {
                    from: 0; to: 60; step: 1; suffix: " min"; accent: page.accent
                    value: page.themeStore.lockTimeoutMin
                    onCommitted: (v) => page.themeStore.set("lock.timeout_min", Math.round(v))
                }
            }

            SettingsRow {
                label: "Lock before sleep"
                hint: "Locks when the computer suspends, so it is locked on wake."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockBeforeSleep
                    onToggled: (v) => page.themeStore.set("lock.before_sleep", v)
                }
            }

            SettingsRow {
                label: "Lock session now"
                hint: "Instantly locks all displays with the active lock screen."
                SettingsButton {
                    text: "Lock now"
                    onClicked: { if (page.lock) page.lock.lockNow() }
                }
            }
        }

        // 2. Composition & Layout
        SettingsCard {
            title: "Composition & Layout"

            SettingsRow {
                label: "Layout preset"
                hint: "Choose between classic centered, editorial magazine, minimal, or split focus."
                SettingsChoice {
                    accent: page.accent
                    current: page.themeStore.lockLayout
                    options: [
                        { value: "cinematic", label: "Cinematic" },
                        { value: "editorial", label: "Editorial" },
                        { value: "minimal", label: "Minimal" },
                        { value: "split", label: "Split Focus" }
                    ]
                    onPicked: (v) => page.themeStore.set("lock.layout", v)
                }
            }

            SettingsRow {
                label: "Clock scale"
                hint: "Adjust the size multiplier for the hero centerpiece clock."
                SettingsSlider {
                    from: 0.8; to: 1.5; step: 0.05; suffix: "x"; accent: page.accent
                    value: page.themeStore.lockClockScale
                    onCommitted: (v) => page.themeStore.set("lock.clock_scale", v)
                }
            }
        }

        // 3. Hero Clock & Typography
        SettingsCard {
            title: "Hero Clock & Typography"

            SettingsRow {
                label: "Time format"
                hint: "24-hour digital or 12-hour format with AM/PM indicator."
                SettingsChoice {
                    accent: page.accent
                    current: page.themeStore.lockClockFormat
                    options: [
                        { value: "HH:mm", label: "24-Hour" },
                        { value: "hh:mm AP", label: "12-Hour" }
                    ]
                    onPicked: (v) => page.themeStore.set("lock.clock_format", v)
                }
            }

            SettingsRow {
                label: "Show seconds"
                hint: "Displays a seconds indicator badge alongside the time."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowSeconds
                    onToggled: (v) => page.themeStore.set("lock.show_seconds", v)
                }
            }
        }

        // 4. Background & Atmosphere
        SettingsCard {
            title: "Background & Atmosphere"

            SettingsRow {
                label: "Wallpaper source"
                hint: page.themeStore.lockUseDesktopWallpaper ? "Uses your active desktop wallpaper." : "Uses an independent lock screen wallpaper."
                SettingsChoice {
                    accent: page.accent
                    current: page.themeStore.lockUseDesktopWallpaper ? "desktop" : "custom"
                    options: [
                        { value: "desktop", label: "Desktop" },
                        { value: "custom", label: "Independent" }
                    ]
                    onPicked: (v) => page.themeStore.set("lock.use_desktop_wallpaper", v === "desktop")
                }
            }

            SettingsRow {
                label: "Background blur"
                hint: "Hardware-accelerated MultiEffect gaussian blur intensity."
                SettingsSlider {
                    from: 0; to: 64; step: 2; suffix: " px"; accent: page.accent
                    value: page.themeStore.lockBlur
                    onCommitted: (v) => page.themeStore.set("lock.blur", Math.round(v))
                }
            }

            SettingsRow {
                label: "Dimming level"
                hint: "Dark overlay opacity to enhance readability."
                SettingsSlider {
                    from: 0; to: 90; step: 5; suffix: "%"; accent: page.accent
                    value: Math.round(page.themeStore.lockDimming * 100)
                    onCommitted: (v) => page.themeStore.set("lock.dimming", v / 100)
                }
            }

            SettingsRow {
                label: "Vignette intensity"
                hint: "Radial shadow around screen boundaries focusing attention on the hero centerpiece."
                SettingsSlider {
                    from: 0; to: 100; step: 5; suffix: "%"; accent: page.accent
                    value: Math.round(page.themeStore.lockVignette * 100)
                    onCommitted: (v) => page.themeStore.set("lock.vignette", v / 100)
                }
            }

            SettingsRow {
                label: "Ambient lighting & shimmer"
                hint: "Restrained, slow-drifting luminous glow and stardust effects."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockAmbientEffects
                    onToggled: (v) => page.themeStore.set("lock.ambient_effects", v)
                }
            }

            SettingsRow {
                label: "Reduced motion"
                hint: "Disables background particle drift and simplifies transitions for minimal GPU overhead."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockReducedMotion
                    onToggled: (v) => page.themeStore.set("lock.reduced_motion", v)
                }
            }
        }

        // 5. User Identity
        SettingsCard {
            title: "User Identity"

            SettingsRow {
                label: "Show greeting"
                hint: "Displays a dynamic time-based greeting (e.g. 'Good evening')."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowGreeting
                    onToggled: (v) => page.themeStore.set("lock.show_greeting", v)
                }
            }

            SettingsRow {
                label: "Show display name"
                hint: "Displays full user name from system accounts."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowDisplayName
                    onToggled: (v) => page.themeStore.set("lock.show_display_name", v)
                }
            }

            SettingsRow {
                label: "Show username"
                hint: "Displays system login handle (@user)."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowUsername
                    onToggled: (v) => page.themeStore.set("lock.show_username", v)
                }
            }

            SettingsRow {
                label: "Show hostname"
                hint: "Displays machine name."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowHostname
                    onToggled: (v) => page.themeStore.set("lock.show_hostname", v)
                }
            }
        }

        // 6. Widgets & Environmental Data
        SettingsCard {
            title: "Widgets & Environmental Data"

            SettingsRow {
                label: "Weather module"
                hint: "Off by default. When on, fetches conditions from wttr.in every 20 minutes: your location, or your IP address when no location is set. Nothing is sent while this is off."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowWeather
                    onToggled: (v) => page.themeStore.set("lock.show_weather", v)
                }
            }

            SettingsRow {
                label: "Temperature units"
                hint: "Choose Celsius or Fahrenheit."
                SettingsChoice {
                    accent: page.accent
                    current: page.themeStore.lockWeatherUnits
                    options: [
                        { value: "C", label: "Celsius (°C)" },
                        { value: "F", label: "Fahrenheit (°F)" }
                    ]
                    onPicked: (v) => page.themeStore.set("lock.weather_units", v)
                }
            }

            SettingsRow {
                label: "Battery indicator"
                hint: "Shows battery percentage and charging state."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowBattery
                    onToggled: (v) => page.themeStore.set("lock.show_battery", v)
                }
            }

            SettingsRow {
                label: "Network & Bluetooth"
                hint: "Shows active Wi-Fi SSID and Bluetooth state."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowNetwork
                    onToggled: (v) => page.themeStore.set("lock.show_network", v)
                }
            }

            SettingsRow {
                label: "Media player"
                hint: "Shows currently playing MPRIS audio track and playback controls."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowMedia
                    onToggled: (v) => page.themeStore.set("lock.show_media", v)
                }
            }

            SettingsRow {
                label: "System uptime"
                hint: "Displays time elapsed since boot."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockShowUptime
                    onToggled: (v) => page.themeStore.set("lock.show_uptime", v)
                }
            }
        }

        // 7. Privacy & Security
        SettingsCard {
            title: "Privacy & Security"

            SettingsRow {
                label: "Hide sensitive media info"
                hint: "Hides song title and artist on the lock screen."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockHideSensitiveMedia
                    onToggled: (v) => page.themeStore.set("lock.hide_sensitive_media", v)
                }
            }

            SettingsRow {
                label: "Hide user details"
                hint: "Hides avatar, name and greeting on the lock screen."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockHideUserDetails
                    onToggled: (v) => page.themeStore.set("lock.hide_user_details", v)
                }
            }

            SettingsRow {
                label: "Disable all lock screen widgets"
                hint: "Hides weather, battery, network and media widgets when locked."
                SettingsToggle {
                    accent: page.accent
                    checked: page.themeStore.lockDisableWidgets
                    onToggled: (v) => page.themeStore.set("lock.disable_widgets", v)
                }
            }
        }

        // 8. Diagnostics & Architecture
        SettingsCard {
            title: "Diagnostics & Configuration"

            Text {
                Layout.fillWidth: true
                text: "Levish features a dual-architecture locking system: Native Wayland ext-session-lock-v1 protocol with PAM conversation, synchronized with a dedicated hyprlock configuration."
                color: Theme.textSecondary
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.Wrap
            }

            Text {
                Layout.fillWidth: true
                text: "State directory: " + (page.lock ? page.lock.stateDir : "")
                color: Theme.muted
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
