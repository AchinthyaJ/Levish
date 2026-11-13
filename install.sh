#!/usr/bin/env bash
# =============================================================
# Levish Desktop Shell — Automated Installer
# Supported: Arch Linux, CachyOS, EndeavourOS, Manjaro
# =============================================================
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}━━━ Levish Desktop Shell Installer ━━━${NC}"

# Detect AUR helper
AUR_HELPER=""
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
elif command -v paru &>/dev/null; then
    AUR_HELPER="paru"
fi

# 1. System packages via pacman/AUR
echo -e "\n${YELLOW}[1/4] Checking system dependencies...${NC}"

DEPENDENCIES=(
    "hyprland"
    "python"
    "python-psutil"
    "python-dbus"
    "python-gobject"
    "pipewire"
    "networkmanager"
    "bluez"
    "bluez-utils"
    "brightnessctl"
    "playerctl"
)

MISSING_DEPS=()
for dep in "${DEPENDENCIES[@]}"; do
    if ! pacman -Qi "$dep" &>/dev/null; then
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "Installing missing dependencies: ${MISSING_DEPS[*]}"
    if [ -n "$AUR_HELPER" ]; then
        $AUR_HELPER -S --needed --noconfirm "${MISSING_DEPS[@]}"
    else
        sudo pacman -S --needed --noconfirm "${MISSING_DEPS[@]}"
    fi
else
    echo -e "${GREEN}✓ All core dependencies installed.${NC}"
fi

# 2. Check eww
echo -e "\n${YELLOW}[2/4] Checking Eww widget system...${NC}"
if ! command -v eww &>/dev/null; then
    echo "Eww not found. Installing via $AUR_HELPER..."
    if [ -n "$AUR_HELPER" ]; then
        $AUR_HELPER -S --noconfirm eww
    else
        echo -e "${RED}Error: Neither yay nor paru found. Please install eww manually.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Eww is installed: $(eww --version 2>/dev/null || echo 'installed')${NC}"
fi

# 3. Setup permissions and directories
echo -e "\n${YELLOW}[3/4] Setting up permissions and environment...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

chmod +x "$SCRIPT_DIR"/scripts/*.sh "$SCRIPT_DIR"/scripts/*.py "$SCRIPT_DIR"/install.sh
mkdir -p /tmp/levish

echo -e "${GREEN}✓ Scripts are now executable.${NC}"

# 4. Verification
echo -e "\n${YELLOW}[4/4] Verifying installation...${NC}"
python3 -m unittest discover -s "$SCRIPT_DIR/tests" -p "test_*.py"

echo -e "\n${GREEN}━━━ Levish installation complete! ━━━${NC}"
echo -e "To start Levish right now:"
echo -e "  ${BLUE}$SCRIPT_DIR/scripts/launch.sh${NC}"
echo -e "\nTo launch automatically with Hyprland, add this line to your hyprland.conf:"
echo -e "  ${BLUE}exec-once = $SCRIPT_DIR/scripts/launch.sh${NC}"
echo -e "\nTo stop Levish:"
echo -e "  ${BLUE}$SCRIPT_DIR/scripts/stop.sh${NC}"
