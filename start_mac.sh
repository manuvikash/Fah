#!/usr/bin/env bash
cd "$(dirname "$0")" || exit 1
if [ ! -f .venv/bin/fah ]; then
    echo "fah is not installed. Run install.sh first."
    exit 1
fi
exec .venv/bin/fah
