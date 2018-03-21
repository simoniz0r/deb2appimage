#!/bin/bash

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"

case $1 in
    --update)
        if type deb2appimage >/dev/null 2>&1; then
            mkdir -p "$HOME"/Downloads
            mkdir -p "$HOME"/.cache/deb2appimage
            cp "$RUNNING_DIR"/deb2appimage "$HOME"/.cache/deb2appimage/deb2appimage.AppImage
            cp "$RUNNING_DIR"/discord-stable.sh "$HOME"/.cache/deb2appimage/discord-stable.sh
            cp "$RUNNING_DIR"/discord-stable.json "$HOME"/.cache/deb2appimage/discord-stable.json
            deb2appimage -j "$RUNNING_DIR"/discord-stable.json -o "$HOME"/Downloads || { echo -e "Failed to build Discord Stable AppImage\nPlease create an issue here: https://github.com/simoniz0r/Discord-Stable-AppImage/issues/new"; exit 1; }
        fi
        ;;
    --remove)
        ./usr/bin/discord-stable.wrapper --remove-appimage-desktop-integration && echo "Removed .desktop file and icon for menu integration for Discord Stable." || echo "Failed to remove .desktop file and icon!"
        exit 0
        ;;
    --help)
        echo "Arguments provided by Discord Stable AppImage:"
        echo "--update - Automatically build an AppImage for the latest version of Discord Stable.  Will be moved to '~/Downloads'"
        echo "--remove - Remove .desktop file and icon for menu integration if created by the AppImage."
        echo "--help   - Show this help output."
        echo
        echo "All other arguments will be passed to Discord Stable; any valid arguments will function the same as a regular Discord Stable install."
        exit 0
        ;;
    *)
        ./usr/bin/discord.wrapper &
        sleep 15
        if ! pgrep DiscordStable; then
            sleep 60
        fi
        STABLE_VER_DIR="$(dir -C -w 1 $HOME/.config/discord | grep '^[0-9].[0-9].[0-9]')"
        if [ -d "$HOME/.config/discord/$STABLE_VER_DIR/modules/pending" ] && [ $(dir -C -w 1 $HOME/.config/discord/$STABLE_VER_DIR/modules/pending | wc -l) -gt 0 ]; then
            sleep 240
        fi
        exit 0
        ;;
esac
