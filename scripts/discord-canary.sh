#!/bin/bash

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"
APP_VERSION="$(grep -m1 '"version":' $RUNNING_DIR/discord-canary.json | cut -f4 -d'"')"
NEW_APP_VERSION="$(curl -sSL -I -X GET "https://discordapp.com/api/download/canary?platform=linux&format=tar.gz" | grep -im1 '^location:' | rev | cut -f1 -d'-' | cut -f3- -d'.' | rev)"

if [ ! -z "$NEW_APP_VERSION" ] && [ ! "$APP_VERSION" = "$NEW_APP_VERSION" ]; then
    echo "New update available for Discord Canary; version $NEW_APP_VERSION"
    echo "Checking for new AppImage from GitHub..."
    GITHUB_APP_VERSION="$(curl -sSL "https://api.github.com/repos/simoniz0r/Discord-Canary-AppImage/releases" | tac | grep -m1 '"name":' | cut -f3 -d'-')"
    if [ ! -z "$GITHUB_APP_VERSION" ] && [  "$GITHUB_APP_VERSION" = "$NEW_APP_VERSION" ]; then
        GITHUB_DL_URL="$(curl -sSL "https://api.github.com/repos/simoniz0r/Discord-Canary-AppImage/releases" | grep -m1 '"browser_download_url":' | cut -f4 -d'"')"
        [ -z "$GITHUB_DL_URL" ] && exit 1
        fltk-dialog --message --center --text="New version of Discord Canary found; downloading version $NEW_APP_VERSION from GitHub...\n \
        Choose a directory to save Discord Canary $NEW_APP_VERSION"
        DEST_DIR="$(fltk-dialog --directory --center --native)"
        [ -z "$DEST_DIR" ] && exit 1
        echo "Downloading $NEW_APP_VERSION from GitHub..."
        if [ -w "$DEST_DIR" ]; then
            mkdir -p "$DEST_DIR"
            curl -sSL -o "$DEST_DIR"/discord-canary "$GITHUB_DL_URL" || { flkt-dialog --warning --center --text="Failed to download Discord Canary!\nPlease try again."; exit 1; }
            chmod +x "$DEST_DIR"/discord-canary
        else
            PASSWORD="$(flkt-dialog --password --center --text="Enter your password to download Discord Canary to $DEST_DIR")"
            echo -n "$PASSWORD" | sudo -S mkdir -p "$DEST_DIR"
            curl -sSL -o /tmp/discord-canary-"$NEW_APP_VERSION"-x86_64.AppImage "$GITHUB_DL_URL" || { flkt-dialog --warning --center --text="Failed to download Discord Canary!\nPlease try again."; exit 1; }
            chmod +x /tmp/discord-canary-"$NEW_APP_VERSION"-x86_64.AppImage
            echo -n "$PASSWORD" | sudo -S mv /tmp/discord-canary-"$NEW_APP_VERSION"-x86_64.AppImage "$DEST_DIR"/discord-canary
        fi
        fltk-dialog --message --center --text="Discord Canary $NEW_APP_VERSION has been downloaded to $DEST_DIR\nLaunching Discord Canary now..."
        "$DEST_DIR"/discord-canary &
        exit 0
    else
        echo "New version not found on GitHub; using deb2appimage to build latest version..."
        mkdir -p "$HOME"/.cache/deb2appimage
        mkdir -p "$DEST_DIR"
        cp "$RUNNING_DIR"/deb2appimage "$HOME"/.cache/deb2appimage/deb2appimage.AppImage
        cp "$RUNNING_DIR"/discord-canary.sh "$HOME"/.cache/deb2appimage/discord-canary.sh
        cp "$RUNNING_DIR"/discord-canary.json "$HOME"/.cache/deb2appimage/discord-canary.json
        deb2appimage -j "$RUNNING_DIR"/discord-canary.json -o "$HOME"/Downloads || { echo -e "Failed to build Discord Canary AppImage\nPlease create an issue here: https://github.com/simoniz0r/Discord-Canary-AppImage/issues/new"; exit 1; }
        mv "$HOME"/Downloads/discord-canary-"$APP_VERSION"-x86_64.AppImage "$DEST_DIR"/discord-canary-"$NEW_APP_VERSION"-x86_64.AppImage
        echo "Discord Canary $NEW_APP_VERSION built to $DEST_DIR/discord-canary-$NEW_APP_VERSION-x86_64.AppImage"
        echo "Running $DEST_DIR/discord-canary-$NEW_APP_VERSION-x86_64.AppImage"
        "$DEST_DIR"/discord-canary-"$NEW_APP_VERSION"-x86_64.AppImage &
        exit 0
    fi
else
    echo "$APP_VERSION"
    echo "Discord Canary is up to date"
    echo
fi


case $1 in
    --remove)
        ./usr/bin/discord-canary.wrapper --remove-appimage-desktop-integration && echo "Removed .desktop file and icon for menu integration for Discord Canary." || echo "Failed to remove .desktop file and icon!"
        exit 0
        ;;
    --help)
        echo "Arguments provided by Discord Canary AppImage:"
        echo "--remove - Remove .desktop file and icon for menu integration if created by the AppImage."
        echo "--help   - Show this help output."
        echo
        echo "All other arguments will be passed to Discord Canary; any valid arguments will function the same as a regular Discord Canary install."
        exit 0
        ;;
    *)
        unset XDG_DATA_DIRS
        ./usr/bin/discord-canary.wrapper &
        sleep 30
        while ps aux | grep -v 'grep' | grep -q 'DiscordCanary'; do
            sleep 30
        done
        exit 0
        ;;
esac
