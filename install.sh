#!/usr/bin/env bash
# =============================================================
# Levish — installer
# Installs the packages Levish needs on Arch Linux and derivatives
# (Arch, CachyOS, EndeavourOS, Manjaro), makes the scripts executable
# and runs the test suite. It does not edit your Hyprland config.
# =============================================================
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}━━━ Levish installer ━━━${NC}"

if ! command -v pacman &>/dev/null; then
    echo -e "${RED}This installer needs pacman (Arch Linux and derivatives).${NC}"
    echo "On other distributions, install the packages listed in README.md → Requirements by hand."
    exit 1
fi

# Official repositories. Names are the Arch packages Levish was built and tested against.
OFFICIAL_PACKAGES=(
    hyprland          # compositor, hyprctl
    hyprpaper         # wallpaper
    hyprlock          # lock screen
    hypridle          # idle locking (optional, used only when auto-lock is on)
    hyprsunset        # night light
    python            # backend
    python-psutil     # CPU, memory and temperature metrics
    python-dbus       # Bluetooth (BlueZ over D-Bus)
    python-gobject    # Bluetooth event loop
    networkmanager    # nmcli: Wi-Fi
    bluez             # Bluetooth stack
    bluez-utils       # bluetoothctl
    pipewire          # audio
    libpulse          # pactl (volume and mute)
    brightnessctl     # display brightness
    playerctl         # media controls (MPRIS)
    wl-clipboard      # wl-copy / wl-paste for clipboard history
)

# AUR. noctalia-qs provides the `qs` command that runs the Quickshell UI.
AUR_PACKAGES=(
    noctalia-qs
)

AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
fi

# ── 1. Official packages ────────────────────────────────────────
echo -e "\n${YELLOW}[1/4] Official packages${NC}"
MISSING=()
for pkg in "${OFFICIAL_PACKAGES[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING+=("$pkg")
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Installing: ${MISSING[*]}"
    sudo pacman -S --needed "${MISSING[@]}"
else
    echo -e "${GREEN}✓ All official packages are installed.${NC}"
fi

# ── 2. AUR packages ─────────────────────────────────────────────
echo -e "\n${YELLOW}[2/4] AUR packages${NC}"
MISSING_AUR=()
for pkg in "${AUR_PACKAGES[@]}"; do
    pacman -Qi "$pkg" &>/dev/null || MISSING_AUR+=("$pkg")
done
if [ ${#MISSING_AUR[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All AUR packages are installed.${NC}"
elif [ -n "$AUR_HELPER" ]; then
    echo "Installing with $AUR_HELPER: ${MISSING_AUR[*]}"
    "$AUR_HELPER" -S --needed "${MISSING_AUR[@]}"
else
    echo -e "${RED}Missing AUR package(s): ${MISSING_AUR[*]}${NC}"
    echo "Install an AUR helper (yay or paru), or build the package(s) by hand, then run this installer again."
    exit 1
fi

# ── 3. Permissions and runtime directory ────────────────────────
echo -e "\n${YELLOW}[3/4] Permissions and runtime directory${NC}"
chmod +x "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR/install.sh"
mkdir -p /tmp/levish
echo -e "${GREEN}✓ Scripts are executable. Runtime state goes to /tmp/levish.${NC}"

# ── 4. Verification ─────────────────────────────────────────────
echo -e "\n${YELLOW}[4/4] Running the test suite${NC}"
python3 -m unittest discover -s "$SCRIPT_DIR/tests" -p "test_*.py"

echo -e "\n${GREEN}━━━ Levish is installed ━━━${NC}"
echo -e "Start Levish now:"
echo -e "  ${BLUE}$SCRIPT_DIR/scripts/launch.sh${NC}"
echo -e "\nStart it with Hyprland by adding this line to ~/.config/hypr/hyprland.conf:"
echo -e "  ${BLUE}exec-once = $SCRIPT_DIR/scripts/launch.sh${NC}"
echo -e "\nStop Levish:"
echo -e "  ${BLUE}$SCRIPT_DIR/scripts/stop.sh${NC}"
echo -e "\nFull setup, keybinds and troubleshooting: README.md"
