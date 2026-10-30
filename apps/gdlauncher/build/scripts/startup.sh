#!/bin/bash -e

source /opt/gow/bash-lib/utils.sh

# Run additional startup scripts
for file in /opt/gow/startup.d/* ; do
    if [ -f "$file" ] ; then
        gow_log "[start] Sourcing $file"
        source $file
    fi
done

gow_log "[start] Starting GDLauncher"

# Managed desktop config (window controls in the waybar toolbar, sway rules). The base image only copies its default
# waybar config when none exists, so profile homes would keep the old toolbar forever; we own these three files and
# rewrite them on every start. The base sway config includes ~/.config/sway/custom-cfg.
mkdir -p "$HOME/.config/waybar" "$HOME/.config/sway"
cp /opt/gdl-cfg/waybar/config.jsonc "$HOME/.config/waybar/config.jsonc"
cat /cfg/waybar/style.css /opt/gdl-cfg/waybar/style-extra.css > "$HOME/.config/waybar/style.css"
cp /opt/gdl-cfg/sway/custom-cfg "$HOME/.config/sway/custom-cfg"

# Moonlight's paste (Ctrl+Alt+Shift+V) arrives as Ctrl+Shift+U <hex digits> per character, which GTK understands and
# Electron/Java do not. Sway catches those keys and /opt/gow/gdl-paste.sh turns them into a real clipboard paste.
# GDL_PASTE_HELPER=0 (environment variable of the app) turns this off.
if [ "${GDL_PASTE_HELPER:-1}" != "0" ]; then
    mkdir -p /tmp/gdl-paste && chmod 777 /tmp/gdl-paste
    KEY='exec sh -c "printf %s >> /tmp/gdl-paste/cur; /opt/gow/gdl-paste.sh arm"'
    {
        echo "bindcode --no-repeat Control+Shift+30 mode \"gdl-unicode\", ${KEY/\%s/\' \'}"
        echo 'mode "gdl-unicode" {'
        echo "    bindcode --no-repeat Control+Shift+30 ${KEY/\%s/\' \'}"
        n=0
        for code in 19 10 11 12 13 14 15 16 17 18; do
            echo "    bindcode --no-repeat Control+Shift+$code ${KEY/\%s/$n}"; n=$((n + 1))
        done
        for pair in 38:a 56:b 54:c 40:d 26:e 41:f; do
            echo "    bindcode --no-repeat Control+Shift+${pair%%:*} ${KEY/\%s/${pair##*:}}"
        done
        echo '}'
    } >> "$HOME/.config/sway/custom-cfg"
fi

# GDLauncher keeps its data (instances, accounts, Java runtimes) under ~/.local/share/gdlauncher_carbon,
# which lives in the profile's persistent home. Extra Electron flags: GDLAUNCHER_STARTUP_FLAGS.
# Electron's own sandbox cannot run inside the container, hence --no-sandbox (same as the Heroic image).
source /opt/gow/launch-comp.sh
launcher /usr/local/bin/gdlauncher ${GDLAUNCHER_STARTUP_FLAGS} --no-sandbox
