# Audio Hotkey Player

A cross-platform background script that plays an audio file when you press a configurable global hotkey. Works on Windows, macOS, and Linux.

## Quick Install

**macOS / Linux**
```bash
curl -fsSL https://raw.githubusercontent.com/manuvikash/Fah/main/install.sh | bash
```

**Windows** (PowerShell)
```powershell
irm https://raw.githubusercontent.com/manuvikash/Fah/main/install.ps1 | iex
```

## Features

- Global hotkey (works in any application)
- User-configurable keybind via `config.yaml`
- Plays audio from start on each keypress (allows overlapping)
- Runs silently in the background
- Cross-platform (Windows & macOS)

## Prerequisites

- Python 3.7 or higher
- pip (Python package manager)

## Installation

1. **Clone or download this repository**

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```
   
   Or install individually:
   ```bash
   pip install pynput pygame pyyaml
   ```

3. **Add custom audio file(optional):**
   - Place your `fah.mp3` file in the same directory as the script
   - Or update `config.yaml` to point to your audio file location

4. **Configure your keybind** (see Configuration section below)

## Configuration

Edit `config.yaml` to customize your keybind:

```yaml
keybind:
  modifiers: ["ctrl", "shift"]  # Modifier keys to hold
  key: "f"                       # Main key to press

audio_file: "fah.mp3"           # Path to your audio file
```

### Available Modifiers

- `ctrl` - Control key (works on both Windows and macOS)
- `alt` - Alt key (Option on macOS)
- `shift` - Shift key
- `cmd` - Command key (macOS only)
- `win` - Windows key (Windows only)

### Available Keys

- Any letter: `a` through `z`
- Any number: `0` through `9`
- Function keys: `f1` through `f12`

### Example Keybind Configurations

**Ctrl+Shift+F:**
```yaml
keybind:
  modifiers: ["ctrl", "shift"]
  key: "f"
```

**Ctrl+Alt+P:**
```yaml
keybind:
  modifiers: ["ctrl", "alt"]
  key: "p"
```

**F9 (no modifiers):**
```yaml
keybind:
  modifiers: []
  key: "f9"
```

**Cmd+Shift+Space (macOS):**
```yaml
keybind:
  modifiers: ["cmd", "shift"]
  key: "space"
```

## Usage

### Running Manually (Foreground)

**Windows:**
```cmd
python audio_hotkey.py
```

**macOS/Linux:**
```bash
python3 audio_hotkey.py
```

Press `Ctrl+C` to stop the script.

### Running in Background

**Windows:**
```cmd
start_windows.bat
```

To stop:
```cmd
taskkill /F /IM pythonw.exe
```

**macOS/Linux:**
```bash
./start_mac.sh
```

To stop:
```bash
pkill -f audio_hotkey.py
```

Or using the saved PID:
```bash
kill $(cat .audio_hotkey.pid)
```

## Auto-Start on Boot

### Windows

Use Task Scheduler to run the script on startup:

1. Open **Task Scheduler** (search in Start menu)
2. Click **Create Basic Task**
3. Name it "Audio Hotkey Player"
4. Trigger: **When I log on**
5. Action: **Start a program**
6. Program/script: Browse to `start_windows.bat`
7. Finish and test by restarting

**Alternative: Using Startup Folder**

1. Press `Win+R` and type: `shell:startup`
2. Create a shortcut to `start_windows.bat` in that folder
3. The script will run on every login

### macOS

Use `launchd` to run the script on startup:

1. Create a plist file at `~/Library/LaunchAgents/com.audiohotkey.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.audiohotkey.player</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/FULL/PATH/TO/audio_hotkey.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/audiohotkey.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/audiohotkey.error.log</string>
</dict>
</plist>
```

2. Replace `/FULL/PATH/TO/audio_hotkey.py` with the actual path (e.g., `/Users/username/fah/audio_hotkey.py`)

3. Load the agent:
```bash
launchctl load ~/Library/LaunchAgents/com.audiohotkey.plist
```

4. To unload/stop:
```bash
launchctl unload ~/Library/LaunchAgents/com.audiohotkey.plist
```

**Alternative: Using Login Items**

1. Open **System Preferences > Users & Groups**
2. Click **Login Items** tab
3. Click **+** and add `start_mac.sh`
4. The script will run when you log in

## Platform-Specific Notes

### macOS Permissions

On macOS, you'll need to grant Accessibility permissions:

1. Run the script once
2. macOS will prompt you to allow Terminal (or Python) to control your computer
3. Go to **System Preferences > Security & Privacy > Privacy > Accessibility**
4. Add Terminal or Python to the allowed apps list

### Windows Permissions

On Windows, no special permissions are typically required. If you encounter issues:

- Run Terminal/PowerShell as Administrator when installing dependencies
- Some antivirus software may flag global keyboard hooks; add an exception if needed

## Troubleshooting

### Audio file not found
- Ensure `fah.mp3` is in the same directory as `audio_hotkey.py`
- Or specify the full path in `config.yaml`

### Hotkey not working
- Check that your keybind doesn't conflict with other applications
- Try a different key combination
- On macOS, ensure Accessibility permissions are granted

### Script won't start
- Verify Python 3 is installed: `python3 --version`
- Check all dependencies are installed: `pip list`
- Look for error messages in the console output

### Can't stop background process

**Windows:**
```cmd
taskkill /F /IM pythonw.exe
```

**macOS/Linux:**
```bash
pkill -f audio_hotkey.py
```

## How It Works

1. The script loads your configuration from `config.yaml`
2. It initializes pygame mixer for audio playback
3. It sets up a global keyboard listener using pynput
4. When your configured keybind is pressed, it plays the audio file
5. Each keypress plays from the start (overlapping audio is allowed)

## License

Free to use and modify for personal projects.

## Support

If you encounter issues:
1. Check the Troubleshooting section above
2. Verify your Python version and dependencies
3. Try running in foreground mode to see error messages
4. Check platform-specific permissions
