#!/bin/bash

set -e

python3 /home/android/kwin-tablet-mode.py off

sleep 0.5

plasmashell --replace \
    >/tmp/plasma-desktop.log 2>&1 &

exit 0
