#!/usr/bin/env python3
"""
Cross-platform audio hotkey player
Listens for a global keyboard hotkey and plays an audio file
"""

import os
import sys
import yaml
import platform
from pathlib import Path
from pynput import keyboard
from pygame import mixer


class AudioHotkey:
    def __init__(self, config_path="config.yaml"):
        """Initialize the audio hotkey listener"""
        self.config = self.load_config(config_path)
        self.setup_audio()
        self.parse_keybind()

    def load_config(self, config_path):
        """Load configuration from YAML file"""
        try:
            with open(config_path, "r") as f:
                config = yaml.safe_load(f)
            return config
        except FileNotFoundError:
            print(f"Error: Configuration file '{config_path}' not found!")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"Error parsing configuration file: {e}")
            sys.exit(1)

    def setup_audio(self):
        """Initialize pygame mixer for audio playback"""
        try:
            mixer.init()
            audio_file = self.config.get("audio_file", "fah.mp3")

            # Support both relative and absolute paths
            if not os.path.isabs(audio_file):
                audio_file = os.path.join(os.path.dirname(__file__), audio_file)

            if not os.path.exists(audio_file):
                print(f"Error: Audio file '{audio_file}' not found!")
                print(
                    f"Please place your audio file in the same directory as this script."
                )
                sys.exit(1)

            self.audio_file = audio_file
            print(f"Audio file loaded: {audio_file}")
        except Exception as e:
            print(f"Error initializing audio: {e}")
            sys.exit(1)

    def parse_keybind(self):
        """Parse the keybind configuration"""
        keybind_config = self.config.get("keybind", {})
        modifiers = keybind_config.get("modifiers", [])
        key = keybind_config.get("key", "f")

        # Map config modifier names to pynput hotkey string tokens
        modifier_token_map = {
            "ctrl": "<ctrl>",
            "alt": "<alt>",
            "shift": "<shift>",
            "cmd": "<cmd>",
            "win": "<cmd>",
        }

        # Build pynput HotKey combination string (e.g. "<ctrl>+<shift>+f")
        parts = []
        valid_modifiers = []
        for mod in modifiers:
            mod_lower = mod.lower()
            if mod_lower in modifier_token_map:
                parts.append(modifier_token_map[mod_lower])
                valid_modifiers.append(mod)
        parts.append(key.lower())
        hotkey_str = "+".join(parts)

        # Use pynput's HotKey which handles canonical key normalization
        self.hotkey = keyboard.HotKey(
            keyboard.HotKey.parse(hotkey_str),
            self.play_audio,
        )

        # Build display string for user
        modifier_names = [m.capitalize() for m in valid_modifiers]
        self.keybind_display = "+".join(modifier_names + [key.upper()])

    def play_audio(self):
        """Play the audio file (non-blocking, allows overlapping)"""
        try:
            # Create a new sound object for each playback to allow overlapping
            sound = mixer.Sound(self.audio_file)
            sound.play()
            print(f"Playing audio: {os.path.basename(self.audio_file)}")
        except Exception as e:
            print(f"Error playing audio: {e}")

    def on_press(self, key):
        """Handle key press events"""
        # canonical() normalises the key (e.g. Ctrl+F -> F) so HotKey can
        # match it correctly regardless of which modifiers are held.
        self.hotkey.press(self._listener.canonical(key))

    def on_release(self, key):
        """Handle key release events"""
        self.hotkey.release(self._listener.canonical(key))

    def run(self):
        """Start the global keyboard listener"""
        print(f"\n{'=' * 50}")
        print(f"Audio Hotkey Player Started")
        print(f"{'=' * 50}")
        print(f"Platform: {platform.system()}")
        print(f"Hotkey: {self.keybind_display}")
        print(f"Audio file: {os.path.basename(self.audio_file)}")
        print(f"\nPress {self.keybind_display} to play audio")
        print(f"Press Ctrl+C to stop")
        print(f"{'=' * 50}\n")

        # Platform-specific instructions
        if platform.system() == "Darwin":
            print("Note: On macOS, you may need to grant Accessibility permissions")
            print("to Terminal or Python in System Preferences > Security & Privacy\n")

        # Start the keyboard listener
        with keyboard.Listener(
            on_press=self.on_press, on_release=self.on_release
        ) as listener:
            self._listener = listener  # needed for canonical() in callbacks
            try:
                # join() with a timeout loops so the main thread stays
                # responsive to KeyboardInterrupt (Ctrl+C) on Linux.
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
