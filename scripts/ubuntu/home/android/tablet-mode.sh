#!/bin/bash

set -e

python3 /home/android/kwin-tablet-mode.py on

sleep 0.5

plasmashell --replace -p org.kde.plasma.mobileshell \
    >/tmp/plasma-mobile.log 2>&1 &

exit 0
