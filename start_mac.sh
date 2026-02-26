#!/bin/bash
# macOS/Linux Background Launcher for Audio Hotkey Player
# This script runs the Python script as a background daemon

echo "Starting Audio Hotkey Player in background..."

# Get the directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run Python script in background with nohup
nohup python3 "$DIR/audio_hotkey.py" > /dev/null 2>&1 &

# Get the process ID
PID=$!

echo "Audio Hotkey Player started with PID: $PID"
echo "To stop it, run: kill $PID"
echo "Or use: pkill -f audio_hotkey.py"

# Save PID to file for easy stopping later
echo $PID > "$DIR/.audio_hotkey.pid"
echo "PID saved to .audio_hotkey.pid"
