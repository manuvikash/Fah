#!/usr/bin/env python3
"""
Cross-platform audio hotkey player
Listens for a global keyboard hotkey and plays an audio file
"""

import os
import sys
import yaml
import platform
import subprocess
import threading
from pathlib import Path
from pynput import keyboard

# pythonw.exe sets stdout/stderr to None -- redirect to devnull to avoid crashes
if sys.stdout is None:
    sys.stdout = open(os.devnull, "w")
if sys.stderr is None:
    sys.stderr = open(os.devnull, "w")

_SYSTEM = platform.system()

# Config lives in the right place per OS
if _SYSTEM == "Windows":
    CONFIG_DIR = Path(os.environ.get("APPDATA", Path.home())) / "fah"
else:
    CONFIG_DIR = Path.home() / ".config" / "fah"

# -- Windows audio via winmm.dll MCI (no subprocess, no window flash) ----------
if _SYSTEM == "Windows":
    import ctypes

    _winmm = ctypes.windll.winmm
    _mciSend = _winmm.mciSendStringW
    _mci_counter = 0
    _mci_lock = threading.Lock()

    def _win_play(filepath):
        """Play an audio file via MCI. Blocks until playback finishes."""
        global _mci_counter
        with _mci_lock:
            _mci_counter += 1
            alias = f"fah{_mci_counter}"
        safe_path = filepath.replace('"', '')
        _mciSend(f'open "{safe_path}" type mpegvideo alias {alias}', None, 0, None)
        _mciSend(f"play {alias} wait", None, 0, None)
        _mciSend(f"close {alias}", None, 0, None)


class AudioHotkey:
    def __init__(self):
        """Initialize the audio hotkey listener"""
        self.config = self.load_config()
        self.setup_audio()
        self.parse_keybind()

    def load_config(self):
        """Load configuration from the platform config directory"""
        config_path = CONFIG_DIR / "config.yaml"
        try:
            with open(config_path, "r") as f:
                config = yaml.safe_load(f)
            return config
        except FileNotFoundError:
            print(f"Error: Configuration file not found at '{config_path}'")
            print("Run the install script again to restore defaults.")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"Error parsing configuration file: {e}")
            sys.exit(1)

    def setup_audio(self):
        """Resolve the audio file and detect the system player"""
        audio_file = self.config.get("audio_file", "fah.mp3")

        if not os.path.isabs(audio_file):
            audio_file = str(CONFIG_DIR / audio_file)

        if not os.path.exists(audio_file):
            print(f"Error: Audio file '{audio_file}' not found!")
            print(f"Place your audio file at: {CONFIG_DIR / 'fah.mp3'}")
            sys.exit(1)

        self.audio_file = audio_file
        self._linux_cmd = self._find_linux_player() if _SYSTEM == "Linux" else None
        print(f"Audio file loaded: {audio_file}")

    def _find_linux_player(self):
        """Return a command list for playing audio on Linux."""
        for player, extra in [
            ("paplay", []),
            ("aplay", []),
            ("ffplay", ["-nodisp", "-autoexit"]),
            ("mpg123", []),
            ("mpv", ["--no-video"]),
        ]:
            if subprocess.run(
                ["which", player], capture_output=True
            ).returncode == 0:
                return [player] + extra
        print("Warning: no audio player found (install paplay, aplay, or ffplay)")
        return None

    def parse_keybind(self):
        """Parse the keybind configuration"""
        keybind_config = self.config.get("keybind", {})
        modifiers = keybind_config.get("modifiers", [])
        key = keybind_config.get("key", "f")

        modifier_token_map = {
            "ctrl": "<ctrl>",
            "alt": "<alt>",
            "shift": "<shift>",
            "cmd": "<cmd>",
            "win": "<cmd>",
        }

        parts = []
        valid_modifiers = []
        for mod in modifiers:
            mod_lower = mod.lower()
            if mod_lower in modifier_token_map:
                parts.append(modifier_token_map[mod_lower])
                valid_modifiers.append(mod)
        parts.append(key.lower())
        hotkey_str = "+".join(parts)

        self.hotkey = keyboard.HotKey(
            keyboard.HotKey.parse(hotkey_str),
            self.play_audio,
        )

        modifier_names = [m.capitalize() for m in valid_modifiers]
        self.keybind_display = "+".join(modifier_names + [key.upper()])

    def play_audio(self):
        """Play the audio file (non-blocking, allows overlapping)"""
        try:
            if _SYSTEM == "Windows":
                # MCI play blocks, so run in a daemon thread
                threading.Thread(
                    target=_win_play, args=(self.audio_file,), daemon=True
                ).start()
            elif _SYSTEM == "Darwin":
                # afplay is always present on macOS
                subprocess.Popen(
                    ["afplay", self.audio_file],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            else:
                # Linux
                if not self._linux_cmd:
                    print("Error: no audio player available")
                    return
                subprocess.Popen(
                    self._linux_cmd + [self.audio_file],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            print(f"Playing audio: {os.path.basename(self.audio_file)}")
        except Exception as e:
            print(f"Error playing audio: {e}")

    def on_press(self, key):
        """Handle key press events"""
        self.hotkey.press(self._listener.canonical(key))

    def on_release(self, key):
        """Handle key release events"""
        self.hotkey.release(self._listener.canonical(key))

    def run(self):
        """Start the global keyboard listener"""
        print(f"\n{'=' * 50}")
        print("Audio Hotkey Player Started")
        print(f"{'=' * 50}")
        print(f"Platform: {_SYSTEM}")
        print(f"Hotkey: {self.keybind_display}")
        print(f"Audio file: {os.path.basename(self.audio_file)}")
        print(f"\nPress {self.keybind_display} to play audio")
        print("Press Ctrl+C to stop")
        print(f"{'=' * 50}\n")

        if _SYSTEM == "Darwin":
            print("Note: On macOS, you may need to grant Accessibility permissions")
            print(
                "to Terminal or Python in System Preferences > Security & Privacy\n"
            )

        with keyboard.Listener(
            on_press=self.on_press, on_release=self.on_release
        ) as listener:
            self._listener = listener
            try:
                while listener.is_alive():
                    listener.join(timeout=1.0)
            except KeyboardInterrupt:
                print("\n\nStopping Audio Hotkey Player...")
                print("Goodbye!")


def main():
    """Main entry point"""
    try:
        hotkey = AudioHotkey()
        hotkey.run()
    except Exception as e:
        print(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
