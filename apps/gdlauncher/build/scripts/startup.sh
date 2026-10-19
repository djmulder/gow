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

# GDLauncher keeps its data (instances, accounts, Java runtimes) under ~/.local/share/gdlauncher_carbon,
# which lives in the profile's persistent home. Extra Electron flags: GDLAUNCHER_STARTUP_FLAGS.
# Electron's own sandbox cannot run inside the container, hence --no-sandbox (same as the Heroic image).
source /opt/gow/launch-comp.sh
launcher /usr/local/bin/gdlauncher ${GDLAUNCHER_STARTUP_FLAGS} --no-sandbox
