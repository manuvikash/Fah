#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
if [ ! -f .venv/bin/fah ]; then
    echo "fah is not installed. Run install.sh first."
    exit 1
fi

# Kill previous instance if running
if [ -f .fah.pid ] && kill -0 "$(cat .fah.pid)" 2>/dev/null; then
    kill "$(cat .fah.pid)"
    echo "Stopped previous instance."
fi

nohup .venv/bin/fah > /dev/null 2>&1 &
echo $! > .fah.pid
echo "fah is running in the background (PID: $!)"
echo "To stop:  kill \$(cat $(pwd)/.fah.pid)"
