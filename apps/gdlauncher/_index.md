# GDLauncher

[GDLauncher](https://gdlauncher.com) (Carbon) is a Minecraft launcher: instances, Forge/NeoForge/Fabric, CurseForge and Modrinth
modpacks. It downloads the Java runtimes it needs by itself.

The image installs the official `.deb` from the release feed at build time. `--build-arg GDL_VERSION=2.0.31` pins a release,
the default `latest` follows `https://cdn-raw.gdl.gg/launcher/latest-linux.yml`.

## Data

Everything (instances, accounts, runtimes) lives in `~/.local/share/gdlauncher_carbon` inside the profile's persistent home, so
it survives container restarts. Instances get large; mount a bigger volume on that folder if the profile storage is small.

## Notes

- Electron runs with `--no-sandbox`; extra flags go in the `GDLAUNCHER_STARTUP_FLAGS` environment variable.
- Minecraft needs a GPU: pass the render device to the app as for the other GoW apps.

## Window controls

Sway has no title-bar buttons, so the image ships its own toolbar (`build/configs/`): a taskbar (click focuses, middle-click closes) and Float / Fullscreen / Close buttons that act on the focused window. `startup.sh` rewrites `~/.config/waybar/{config.jsonc,style.css}` and `~/.config/sway/custom-cfg` on every start, so these files are managed by the image, not by the profile home. Keyboard: Alt+F fullscreen, Alt+Shift+Space float, Alt+F4 close.
