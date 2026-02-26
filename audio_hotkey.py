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
        self.current_keys = set()
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

        # Map string modifiers to pynput Key objects
        self.modifier_map = {
            "ctrl": keyboard.Key.ctrl_l,
            "alt": keyboard.Key.alt_l,
            "shift": keyboard.Key.shift_l,
            "cmd": keyboard.Key.cmd if platform.system() == "Darwin" else None,
            "win": keyboard.Key.cmd if platform.system() == "Windows" else None,
        }

        # Build the set of required modifiers
        self.required_modifiers = set()
        for mod in modifiers:
            mod_lower = mod.lower()
            if mod_lower in self.modifier_map:
                key_obj = self.modifier_map[mod_lower]
                if key_obj:  # Only add if valid for this platform
                    self.required_modifiers.add(key_obj)
                    # Also add the right version of the key
                    if mod_lower == "ctrl":
                        self.required_modifiers.add(keyboard.Key.ctrl_r)
                    elif mod_lower == "alt":
                        self.required_modifiers.add(keyboard.Key.alt_r)
                    elif mod_lower == "shift":
                        self.required_modifiers.add(keyboard.Key.shift_r)

        # Store the main key
        self.main_key = key.lower()

        # Build display string for user
        modifier_names = [m.capitalize() for m in modifiers]
        keybind_display = "+".join(modifier_names + [key.upper()])
        self.keybind_display = keybind_display

    def play_audio(self):
        """Play the audio file (non-blocking, allows overlapping)"""
        try:
            # Create a new sound object for each playback to allow overlapping
            sound = mixer.Sound(self.audio_file)
            sound.play()
            print(f"Playing audio: {os.path.basename(self.audio_file)}")
        except Exception as e:
            print(f"Error playing audio: {e}")

    def check_hotkey(self):
        """Check if the hotkey combination is currently pressed"""
        # Check if at least one variant of each required modifier is pressed
        modifiers_pressed = any(
            mod in self.current_keys for mod in self.required_modifiers
        )

        # If we have required modifiers, check if they're all pressed
        if self.required_modifiers:
            # For each modifier type, check if at least one variant is pressed
            modifier_types = {}
            for mod in self.required_modifiers:
                if mod in [keyboard.Key.ctrl_l, keyboard.Key.ctrl_r]:
                    modifier_types["ctrl"] = (
                        modifier_types.get("ctrl", False) or mod in self.current_keys
                    )
                elif mod in [keyboard.Key.alt_l, keyboard.Key.alt_r]:
                    modifier_types["alt"] = (
                        modifier_types.get("alt", False) or mod in self.current_keys
                    )
                elif mod in [keyboard.Key.shift_l, keyboard.Key.shift_r]:
                    modifier_types["shift"] = (
                        modifier_types.get("shift", False) or mod in self.current_keys
                    )
                elif mod == keyboard.Key.cmd:
                    modifier_types["cmd"] = (
                        modifier_types.get("cmd", False) or mod in self.current_keys
                    )

            # All required modifier types must be pressed
            if not all(modifier_types.values()):
                return False

        # Check if the main key is pressed
        for key in self.current_keys:
            key_char = None
            if hasattr(key, "char") and key.char:
                key_char = key.char.lower()
            elif hasattr(key, "name"):
                key_char = key.name.lower()

            if key_char == self.main_key:
                return True

        return False

    def on_press(self, key):
        """Handle key press events"""
        self.current_keys.add(key)

        if self.check_hotkey():
            self.play_audio()

    def on_release(self, key):
        """Handle key release events"""
        try:
            self.current_keys.discard(key)
        except KeyError:
            pass

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
            try:
                listener.join()
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
