#!/usr/bin/env bash
set -euo pipefail

# Colors
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${BLUE}${BOLD}"
echo "    _   __                  ____  __                      "
echo "   / | / /___ _   ______ _ / __ \/ /___ ___  _____  _____ "
echo "  /  |/ / __ \ | / / __ \`/ /_/ / / __ \`/ / / / _ \/ ___/ "
echo " / /|  / /_/ / |/ / /_/ / ____/ / /_/ / /_/ /  __/ /     "
echo "/_/ |_/\____/|___/\__,_/_/   /_/\__,_/\__, /\___/_/      "
echo "                                     /____/              "
echo -e "${RESET}"
echo -e "${BOLD}NovaPlayer Installer for macOS${RESET}"
echo "--------------------------------------------------------"

REPO="Beccaceci/NovaPlayer"
INSTALL_DIR="/Applications"
APP_NAME="NovaPlayer.app"
DEST="$INSTALL_DIR/$APP_NAME"

# Check OS
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "❌ Error: NovaPlayer currently supports macOS only."
    exit 1
fi

echo -e "==> Checking for latest GitHub Release of ${BOLD}${REPO}${RESET}..."

# Try downloading latest release DMG from GitHub
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/NovaPlayer.dmg"
TEMP_DMG="/tmp/NovaPlayer_install.dmg"

SUCCESS=false
if curl -fsSL -I "$RELEASE_URL" > /dev/null 2>&1; then
    echo -e "==> Downloading latest binary release..."
    curl -fSL "$RELEASE_URL" -o "$TEMP_DMG"
    
    echo -e "==> Mounting DMG..."
    MOUNT_DIR=$(hdiutil attach "$TEMP_DMG" -nobrowse -readonly | grep "/Volumes/" | awk '{print $3}')
    
    if [[ -d "$MOUNT_DIR/$APP_NAME" ]]; then
        echo -e "==> Installing to $INSTALL_DIR..."
        rm -rf "$DEST"
        cp -R "$MOUNT_DIR/$APP_NAME" "$INSTALL_DIR/"
        hdiutil detach "$MOUNT_DIR" -quiet || true
        rm -f "$TEMP_DMG"
        SUCCESS=true
    fi
fi

# Fallback: clone and build locally if release binary not yet published
if [[ "$SUCCESS" != "true" ]]; then
    echo -e "${YELLOW}==> Pre-built binary not found on Releases yet. Building locally with Swift...${RESET}"
    
    if ! command -v swift &> /dev/null; then
        echo "❌ Error: Swift is required to compile from source. Please install Xcode Command Line Tools: xcode-select --install"
        exit 1
    fi
    
    TEMP_DIR="/tmp/NovaPlayer-source"
    rm -rf "$TEMP_DIR"
    git clone --depth 1 "https://github.com/${REPO}.git" "$TEMP_DIR"
    
    cd "$TEMP_DIR"
    chmod +x scripts/build_app.sh
    ./scripts/build_app.sh
    
    rm -rf "$DEST"
    cp -R "build/$APP_NAME" "$INSTALL_DIR/"
    rm -rf "$TEMP_DIR"
fi

# Clear quarantine attributes for smooth gatekeeper launch
echo -e "==> Registering application with macOS..."
xattr -cr "$DEST" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST" 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}🎉 NovaPlayer was successfully installed to /Applications/NovaPlayer.app!${RESET}\n"
echo "You can launch it anytime by pressing Cmd + Space and searching 'NovaPlayer'."
echo ""
read -p "Would you like to launch NovaPlayer right now? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$DEST"
fi
