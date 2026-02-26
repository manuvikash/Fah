#!/usr/bin/env bash
# install.sh - Install fah (Audio Hotkey Player) on macOS/Linux
# Works both locally (bash install.sh) and piped (curl ... | bash)

set -e

REPO_URL="https://github.com/manuvikash/Fah.git"
CONFIG_DIR="$HOME/.config/fah"

# ── Detect local vs piped execution ───────────────────────────────────────────
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_SOURCE" ] && [ -f "$SCRIPT_SOURCE" ] && \
   [ -f "$(dirname "$SCRIPT_SOURCE")/pyproject.toml" ]; then
    PROJECT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"
else
    # Running via curl | bash - clone the repo
    PROJECT_DIR="$HOME/.local/share/fah"
    if ! command -v git &>/dev/null; then
        echo "Error: git is required. Install git and retry."
        exit 1
    fi
    if [ -d "$PROJECT_DIR/.git" ]; then
        echo "Updating fah..."
        git -C "$PROJECT_DIR" pull --ff-only --quiet
    else
        rm -rf "$PROJECT_DIR"
        echo "Cloning fah into $PROJECT_DIR..."
        git clone --depth 1 "$REPO_URL" "$PROJECT_DIR"
    fi
fi

cd "$PROJECT_DIR"

# ── Find Python 3 ─────────────────────────────────────────────────────────────
PY=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null && "$cmd" --version 2>&1 | grep -q "Python 3"; then
        PY="$cmd"; break
    fi
done
if [ -z "$PY" ]; then
    echo "Error: Python 3 not found. Install from https://python.org"
    exit 1
fi
echo "Found $($PY --version 2>&1)"

# ── Create virtual environment ─────────────────────────────────────────────────
if [ ! -d .venv ]; then
    echo "Creating virtual environment..."
    $PY -m venv .venv
fi

# ── Install package into venv ──────────────────────────────────────────────────
echo "Installing dependencies..."
.venv/bin/pip install --quiet -e .

# ── Set up config directory ────────────────────────────────────────────────────
mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    cp config.yaml "$CONFIG_DIR/"
    echo "Config copied to $CONFIG_DIR/config.yaml"
else
    echo "Config already exists at $CONFIG_DIR/config.yaml - skipping"
fi

if [ ! -f "$CONFIG_DIR/fah.mp3" ] && [ -f fah.mp3 ]; then
    cp fah.mp3 "$CONFIG_DIR/"
    echo "Audio copied to $CONFIG_DIR/fah.mp3"
elif [ ! -f "$CONFIG_DIR/fah.mp3" ]; then
    echo "Place your audio file at: $CONFIG_DIR/fah.mp3"
fi

# ── Symlink for PATH access ───────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
ln -sf "$PROJECT_DIR/.venv/bin/fah" "$HOME/.local/bin/fah"

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "Install complete!"
echo "  Run:    fah  (or $PROJECT_DIR/start_mac.sh)"
echo "  Config: $CONFIG_DIR/config.yaml"
echo "  Audio:  $CONFIG_DIR/fah.mp3"
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo ""
    echo "Add ~/.local/bin to PATH if 'fah' is not found:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
