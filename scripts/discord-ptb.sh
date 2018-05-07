#!/bin/bash

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"

case $1 in
    --update)
        if type deb2appimage >/dev/null 2>&1; then
            mkdir -p "$HOME"/Downloads
            mkdir -p "$HOME"/.cache/deb2appimage
            cp "$RUNNING_DIR"/deb2appimage "$HOME"/.cache/deb2appimage/deb2appimage.AppImage
            cp "$RUNNING_DIR"/discord-ptb.sh "$HOME"/.cache/deb2appimage/discord-ptb.sh
            cp "$RUNNING_DIR"/discord-ptb.json "$HOME"/.cache/deb2appimage/discord-ptb.json
            deb2appimage -j "$RUNNING_DIR"/discord-ptb.json -o "$HOME"/Downloads || { echo -e "Failed to build Discord PTB AppImage\nPlease create an issue here: https://github.com/simoniz0r/Discord-PTB-AppImage/issues/new"; exit 1; }
        fi
        ;;
    --remove)
        ./usr/bin/discord-ptb.wrapper --remove-appimage-desktop-integration && echo "Removed .desktop file and icon for menu integration for Discord PTB." || echo "Failed to remove .desktop file and icon!"
        exit 0
        ;;
    --help)
        echo "Arguments provided by Discord PTB AppImage:"
        echo "--update - Automatically build an AppImage for the latest version of Discord PTB.  Will be moved to '~/Downloads'"
        echo "--remove - Remove .desktop file and icon for menu integration if created by the AppImage."
        echo "--help   - Show this help output."
        echo
        echo "All other arguments will be passed to Discord PTB; any valid arguments will function the same as a regular Discord PTB install."
        exit 0
        ;;
    *)
        ./usr/bin/discord-ptb.wrapper &
        sleep 30
        while ps aux | grep -v 'grep' | grep -q 'DiscordPTB'; do
            sleep 30
        done
        exit 0
        ;;
esac
