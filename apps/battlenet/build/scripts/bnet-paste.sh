#!/bin/bash
# bnet-paste: Wolf types pasted text as Ctrl+Shift+U <hex digits> (GTK Unicode input), which Wine ignores.
# Sway catches that sequence (see bnet-paste.sway), this script collects the characters and, shortly after
# the last one, puts the text on the clipboard and sends Ctrl+V to the focused window.
S=/tmp/bnet-paste
mkdir -p "$S"
export LC_ALL=C.UTF-8
export DISPLAY="${DISPLAY:-:0}"
case "$1" in
    start)
        : > "$S/cur"
        ;;
    key)
        printf '%s' "$2" >> "$S/cur"
        ;;
    end)
        # sway swallows the release of the modifiers it matched; tell the X side that they are up
        xdotool keyup Shift_L Control_L 2>/dev/null
        [ -s "$S/cur" ] || exit 0
        hex=$(cat "$S/cur"); : > "$S/cur"
        # shellcheck disable=SC2059
        printf "\\U$(printf '%08x' "0x$hex")" >> "$S/text"
        gen=$(date +%s%N); echo "$gen" > "$S/gen"
        ( sleep 0.5; [ "$(cat "$S/gen")" = "$gen" ] && "$0" flush ) > /dev/null 2>&1 &
        ;;
    flush)
        [ -s "$S/text" ] || exit 0
        cp "$S/text" "$S/paste"; : > "$S/text"
        xclip -selection clipboard -i < "$S/paste"
        sleep 0.1
        xdotool key --clearmodifiers ctrl+v
        ;;
esac
exit 0
