#!/data/data/com.termux/files/usr/bin/bash

DIR=/data/local/tmp/anland-bridge
CMD="$DIR/cmd"

mkdir -p "$DIR"
chmod 777 "$DIR"

while true; do
    if [ -f "$CMD" ]; then
        action=$(cat "$CMD")
        rm -f "$CMD"

        case "$action" in
            touch)
                sed -i 's/name="touchpad_mode" value="[^"]*"/name="touchpad_mode" value="false"/' \
                  /data/data/com.anland.termux/shared_prefs/anland_settings.xml
                am force-stop com.anland.termux
                monkey -p com.anland.termux -c android.intent.category.LAUNCHER 1
                ;;
            desktop)
                sed -i 's/name="touchpad_mode" value="[^"]*"/name="touchpad_mode" value="true"/' \
                  /data/data/com.anland.termux/shared_prefs/anland_settings.xml
                am force-stop com.anland.termux
                monkey -p com.anland.termux -c android.intent.category.LAUNCHER 1
                ;;
            haptic)
                /data/data/com.termux/files/usr/bin/termux-vibrate -d 50
                ;;
        esac
    fi
    sleep 0.2
done
