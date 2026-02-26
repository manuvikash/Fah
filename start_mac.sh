#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
python3 audio_hotkey.py &
