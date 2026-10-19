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

# GDLauncher keeps its data (instances, accounts, Java runtimes) under ~/.local/share/gdlauncher_carbon,
# which lives in the profile's persistent home. Extra Electron flags: GDLAUNCHER_STARTUP_FLAGS.
# Electron's own sandbox cannot run inside the container, hence --no-sandbox (same as the Heroic image).
source /opt/gow/launch-comp.sh
launcher /usr/local/bin/gdlauncher ${GDLAUNCHER_STARTUP_FLAGS} --no-sandbox
