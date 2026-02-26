#!/usr/bin/env bash
# install.sh — one-liner installer for fah (Audio Hotkey Player)
# Usage: curl -fsSL https://raw.githubusercontent.com/manuvikash/Fah/main/install.sh | bash

set -e

REPO="https://github.com/manuvikash/Fah"
RAW="https://raw.githubusercontent.com/manuvikash/Fah/main"
CONFIG_DIR="$HOME/.config/fah"

# ── Colours ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()    { echo -e "${GREEN}[fah]${NC} $*"; }
warn()    { echo -e "${YELLOW}[fah]${NC} $*"; }
error()   { echo -e "${RED}[fah]${NC} $*" >&2; exit 1; }

# ── OS detection ───────────────────────────────────────────────────────────────
OS="$(uname -s)"
case "$OS" in
  Linux*)  PLATFORM=linux ;;
  Darwin*) PLATFORM=macos ;;
  *)       error "Unsupported OS: $OS" ;;
esac
info "Detected platform: $PLATFORM"

# ── Python 3 ───────────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  error "Python 3 is required but not found. Install it from https://python.org"
fi
info "Python 3 found: $(python3 --version)"

# ── pipx ───────────────────────────────────────────────────────────────────────
ensure_pipx() {
  if command -v pipx &>/dev/null; then
    info "pipx already installed: $(pipx --version)"
    return
  fi
  info "Installing pipx..."
  if [[ "$PLATFORM" == "macos" ]] && command -v brew &>/dev/null; then
    brew install pipx
  elif [[ "$PLATFORM" == "linux" ]] && command -v apt-get &>/dev/null; then
    sudo apt-get install -y pipx 2>/dev/null || python3 -m pip install --user pipx
  else
    python3 -m pip install --user pipx
  fi
  # Ensure pipx bin dir is on PATH for this session
  export PATH="$HOME/.local/bin:$PATH"
  python3 -m pipx ensurepath --force &>/dev/null || true
}
ensure_pipx

# ── Install / upgrade fah ──────────────────────────────────────────────────────
if pipx list 2>/dev/null | grep -q "package fah"; then
  info "Upgrading fah..."
  pipx upgrade fah
else
  info "Installing fah via pipx..."
  pipx install "git+${REPO}.git"
fi

# ── Config directory ───────────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

# Download config.yaml only if it doesn't exist (preserve user edits)
if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
  info "Downloading default config.yaml → $CONFIG_DIR/config.yaml"
  curl -fsSL "$RAW/config.yaml" -o "$CONFIG_DIR/config.yaml"
else
  warn "config.yaml already exists — skipping (edit it at $CONFIG_DIR/config.yaml)"
fi

# Download fah.mp3 only if it doesn't exist
if [[ ! -f "$CONFIG_DIR/fah.mp3" ]]; then
  info "Downloading fah.mp3 → $CONFIG_DIR/fah.mp3"
  curl -fsSL "$RAW/fah.mp3" -o "$CONFIG_DIR/fah.mp3"
else
  warn "fah.mp3 already exists — skipping"
fi

# ── Autostart ──────────────────────────────────────────────────────────────────
FAH_BIN="$(command -v fah 2>/dev/null || echo "$HOME/.local/bin/fah")"

setup_autostart_linux() {
  local desktop_dir="$HOME/.config/autostart"
  mkdir -p "$desktop_dir"
  cat > "$desktop_dir/fah.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Fah Audio Hotkey
Exec=$FAH_BIN
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
  info "Autostart enabled → $desktop_dir/fah.desktop"
}

setup_autostart_macos() {
  local plist="$HOME/Library/LaunchAgents/com.manuvikash.fah.plist"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.manuvikash.fah</string>
  <key>ProgramArguments</key>
  <array>
    <string>$FAH_BIN</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
</dict>
</plist>
EOF
  launchctl load "$plist" 2>/dev/null || true
  info "Autostart enabled → $plist"
}

echo ""
read -r -p "$(echo -e "${YELLOW}Set up fah to start automatically on login? [y/N]:${NC} ")" autostart_choice </dev/tty
if [[ "$autostart_choice" =~ ^[Yy]$ ]]; then
  if [[ "$PLATFORM" == "linux" ]]; then
    setup_autostart_linux
  else
    setup_autostart_macos
  fi
else
  info "Skipping autostart."
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}✓ fah installed successfully!${NC}"
echo ""
echo "  Run now:     fah"
echo "  Edit config: $CONFIG_DIR/config.yaml"
echo "  Audio file:  $CONFIG_DIR/fah.mp3"
echo ""
warn "If 'fah' is not found, restart your shell or run: export PATH=\"\$HOME/.local/bin:\$PATH\""
