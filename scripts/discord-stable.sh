#!/bin/bash

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"

function updatediscordstable() {
    APP_VERSION="$(cat "$RUNNING_DIR"/discord-version)"
    NEW_APP_VERSION="$(curl -sSL -I -X GET "https://discordapp.com/api/download?platform=linux&format=tar.gz" | grep -im1 '^location:' | rev | cut -f1 -d'-' | cut -f3- -d'.' | rev)"
    if [[ ! -z "$NEW_APP_VERSION" ]] && [[ ! "$APP_VERSION" == "$NEW_APP_VERSION" ]]; then
        GITHUB_DL_URL="https://github.com/simoniz0r/Discord-AppImage/releases/download/v$NEW_APP_VERSION/discord-$NEW_APP_VERSION-x86_64.AppImage"
        if [[ "$(curl -sL -I -X HEAD "$GITHUB_DL_URL" | grep -m1 '^Status:' | cut -f2 -d' ')" == "302" ]]; then
            fltk-dialog --question --center --text="New Discord version has been released!\nDownload version $NEW_APP_VERSION now?"
            case $? in
                1)
                    exit 0
                    ;;
            esac
            fltk-dialog --message --center --text="Please choose the save location for 'discord'"
            DEST_DIR="$(fltk-dialog --directory --center --native)"
            if [[ -z "$DEST_DIR" ]] || [[ "$DEST_DIR" =~ "/tmp/." ]]; then
                fltk-dialog --message --center --text="Invalid directory selected; using $HOME/Downloads"
                DEST_DIR="$HOME/Downloads"
            fi
            mkdir -p ~/.cache/discord-appimage
            fltk-dialog --progress --center --pulsate --no-cancel --no-escape --text="Downloading Discord" &
            PROGRESS_PID=$!
            curl -sSL -o ~/.cache/discord-appimage/discord "$GITHUB_DL_URL" || { fltk-dialog --warning --center --text="Failed to download Discord!\nPlease try again."; exit 1; }
            chmod +x ~/.cache/discord-appimage/discord
            kill -SIGTERM -f $PROGRESS_PID
            if [[ -w "$DEST_DIR" ]]; then
                mkdir -p "$DEST_DIR"
                mv ~/.cache/discord-appimage/discord "$DEST_DIR"/discord
            else
                PASSWORD="$(fltk-dialog --password --center --text="Enter your password to download Discord to $DEST_DIR")"
                echo "$PASSWORD" | sudo -S mkdir -p "$DEST_DIR" || { fltk-dialog --warning --center --text="Failed to create $DEST_DIR!\nPlease try again."; exit 1; }
                echo "$PASSWORD" | sudo -S mv ~/.cache/discord-appimage/discord "$DEST_DIR"/discord || \
                { fltk-dialog --warning --center --text="Failed to move Discord to $DEST_DIR!\nPlease try again."; rm -f ~/.cache/discord-appimage/discord; exit 1; }
                kill -SIGTERM -f $PROGRESS_PID
            fi
            rm -rf ~/.cache/discord-appimage
            fltk-dialog --message --center --text="Discord $NEW_APP_VERSION has been downloaded to $DEST_DIR\nLaunching Discord now..."
            "$DEST_DIR"/discord &
            exit 0
        else
            fltk-dialog --question --center --text="New Discord version has been released!\nUse deb2appimage to build an AppImage for $NEW_APP_VERSION now?"
            case $? in
                1)
                    exit 0
                    ;;
            esac
            mkdir -p "$HOME"/.cache/deb2appimage/usr/bin
            mkdir -p "$HOME"/.cache/discord-appimage
            fltk-dialog --message --center --text="Please choose the save location for 'discord'"
            DEST_DIR="$(fltk-dialog --directory --center --native)"
            if [[ -z "$DEST_DIR" ]] || [[ "$DEST_DIR" =~ "/tmp/." ]]; then
                fltk-dialog --message --center --text="Invalid directory selected; using $HOME/Downloads"
                DEST_DIR="$HOME/Downloads"
            fi
            if [[ -w "$DEST_DIR" ]]; then
                mkdir -p "$DEST_DIR"
            else
                PASSWORD="$(fltk-dialog --password --center --text="Enter your password to build Discord AppImage to $DEST_DIR")"
                echo "$PASSWORD" | sudo -S mkdir -p "$DEST_DIR" || { fltk-dialog --warning --center --text="Failed to create $DEST_DIR!\nPlease try again."; exit 1; }
            fi
            # cp "$RUNNING_DIR"/deb2appimage "$HOME"/.cache/deb2appimage/usr/bin/deb2appimage.AppImage
            # cp "$RUNNING_DIR"/fltk-dialog "$HOME"/.cache/deb2appimage/usr/bin/fltk-dialog
            # cp "$RUNNING_DIR"/discord-stable.sh "$HOME"/.cache/deb2appimage/usr/bin/discord-stable.sh
            # cp "$RUNNING_DIR"/discord-stable.json "$HOME"/.cache/deb2appimage/usr/bin/discord-stable.json
            fltk-dialog --progress --center --pulsate --no-cancel --no-escape --text="Downloading Discord" &
            PROGRESS_PID=$!
            deb2appimage -j "$RUNNING_DIR"/discord-stable.json -o "$HOME"/.cache/discord-appimage || { fltk-dialog --warning --center --text="Failed to build Discord AppImage\nPlease create an issue here:\nhttps://github.com/simoniz0r/Discord-AppImage/issues/new"; exit 1; }
            kill -SIGTERM -f $PROGRESS_PID
            if [[ -w "$DEST_DIR" ]]; then
                mv "$HOME"/.cache/discord-appimage/discord-latest-x86_64.AppImage "$DEST_DIR"/discord
            else
                echo "$PASSWORD" | sudo -S mv "$HOME"/.cache/discord-appimage/discord-latest-x86_64.AppImage "$DEST_DIR"/discord || \
                { fltk-dialog --warning --center --text="Failed to move Discord to $DEST_DIR!\nPlease try again."; rm -f "$HOME"/.cache/discord-appimage/discord-latest-x86_64.AppImage; exit 1; }
            fi
            fltk-dialog --message --center --text="Discord AppImage $NEW_APP_VERSION has been built to $DEST_DIR\nLaunching Discord now..."
            rm -rf "$HOME"/.cache/discord-appimage
            "$DEST_DIR"/discord &
            exit 0
        fi
    else
        echo "$APP_VERSION"
        echo "Discord is up to date"
        echo
    fi
}

case $1 in
    --remove)
        "$RUNNING_DIR"/discord.wrapper --remove-appimage-desktop-integration && echo "Removed .desktop file and icon for menu integration for Discord." || echo "Failed to remove .desktop file and icon!"
        exit 0
        ;;
    --help)
        echo "Arguments provided by Discord AppImage:"
        echo "--remove - Remove .desktop file and icon for menu integration if created by the AppImage."
        echo "--help   - Show this help output."
        echo
        echo "All other arguments will be passed to Discord; any valid arguments will function the same as a regular Discord install."
        exit 0
        ;;
    *)
        if ! type curl > /dev/null 2>&1; then
            fltk-dialog --message --center --text="Please install 'curl' to enable update checks"
        else
            updatediscordstable
        fi
        "$RUNNING_DIR"/discord.wrapper &
        sleep 30
        while ps aux | grep -v 'grep' | grep -q 'Discord'; do
            sleep 30
        done
        exit 0
        ;;
esac
