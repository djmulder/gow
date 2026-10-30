# syntax=docker/dockerfile:1.4
ARG BASE_APP_IMAGE=ghcr.io/games-on-whales/base-app:edge

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive

# GDLauncher (Carbon) is an Electron app. apt resolves the Electron libraries from the .deb itself;
# these are only the extras the container image needs. GDLauncher downloads its own Java runtimes.
ARG REQUIRED_PACKAGES=" \
    ca-certificates \
    curl \
    xdg-utils \
    libnotify4 \
    libsecret-1-0 \
    xclip \
    xdotool \
    "

RUN apt-get update && \
    apt-get install -y --no-install-recommends $REQUIRED_PACKAGES && \
    rm -rf /var/lib/apt/lists/*

# Release feed: https://cdn-raw.gdl.gg/launcher/latest-linux.yml has `version` and `path` (the AppImage
# name, e.g. GDLauncher__2.0.31__linux__x64.AppImage). The .deb sits next to it with the same base name.
# GDL_VERSION=latest follows the feed; set an explicit version (e.g. 2.0.31) to pin a release.
ARG GDL_VERSION=latest
ARG GDL_BASE_URL=https://cdn-raw.gdl.gg/launcher

WORKDIR /tmp
RUN <<_INSTALL_GDLAUNCHER
#!/bin/bash
set -euo pipefail

if [ "${GDL_VERSION}" = "latest" ]; then
  curl -fsSL "${GDL_BASE_URL}/latest-linux.yml" -o latest-linux.yml
  cat latest-linux.yml
  APPIMAGE_NAME=$(sed -n 's/^path:[[:space:]]*//p' latest-linux.yml | tr -d "\"' \r")
  [ -n "${APPIMAGE_NAME}" ] || { echo "no 'path:' in latest-linux.yml" >&2; exit 1; }
  DEB_NAME="${APPIMAGE_NAME%.*}.deb"
else
  DEB_NAME="GDLauncher__${GDL_VERSION}__linux__x64.deb"
fi

echo "Installing ${DEB_NAME}"
curl -fSL "${GDL_BASE_URL}/${DEB_NAME}" -o gdlauncher.deb
apt-get update
apt-get install -y --no-install-recommends ./gdlauncher.deb
rm -rf /var/lib/apt/lists/* gdlauncher.deb latest-linux.yml

# Find the installed executable and expose it as 'gdlauncher' (startup.sh calls that name)
PKG=$(dpkg-query -W -f='${Package}\n' | grep -i -E '^gdlauncher' | head -1)
[ -n "${PKG}" ] || { echo "GDLauncher package not found after install" >&2; exit 1; }
# The Electron binary of the .deb is /opt/GDLauncher/@gddesktop (the folder /opt/GDLauncher also matches by name,
# so only accept regular executable files)
BIN=""
for f in $(dpkg -L "${PKG}" | grep -E '/(@gddesktop|gdlauncher)$'); do
  if [ -f "$f" ] && [ -x "$f" ]; then BIN="$f"; break; fi
done
if [ -z "${BIN}" ]; then
  echo "GDLauncher executable not found, package contents:" >&2
  dpkg -L "${PKG}" >&2
  exit 1
fi
ln -sf "${BIN}" /usr/local/bin/gdlauncher
echo "${PKG} installed, binary ${BIN}"
_INSTALL_GDLAUNCHER
WORKDIR /

COPY --chmod=777 scripts/startup.sh /opt/gow/startup-app.sh
COPY --chmod=755 scripts/gdl-paste.sh /opt/gow/gdl-paste.sh
# Managed desktop config (taskbar, window buttons); startup.sh installs it into the profile home on every start
COPY --chmod=755 configs/ /opt/gdl-cfg/

# Sway's modifier is left Alt in the base config, which swallows Alt in games (Create schematic placement). Use Super.
RUN sed -i 's/^set \$mod Mod1$/set $mod Mod4/' /cfg/sway/config && grep -q '^set \$mod Mod4$' /cfg/sway/config

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
