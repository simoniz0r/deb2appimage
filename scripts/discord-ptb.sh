#!/bin/bash

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"

function updatediscordptb() {
    APP_VERSION="$(grep -m1 '"version":' $RUNNING_DIR/discord-ptb.json | cut -f4 -d'"')"
    NEW_APP_VERSION="$(curl -sSL -I -X GET "https://discordapp.com/api/download/ptb?platform=linux&format=tar.gz" | grep -im1 '^location:' | rev | cut -f1 -d'-' | cut -f3- -d'.' | rev)"
    if [ ! -z "$NEW_APP_VERSION" ] && [ ! "$APP_VERSION" = "$NEW_APP_VERSION" ]; then
        GITHUB_DL_URL="https://github.com/simoniz0r/Discord-PTB-AppImage/releases/download/v$NEW_APP_VERSION/discord-ptb-$NEW_APP_VERSION-x86_64.AppImage"
        if curl -sSL -I -X GET "$GITHUB_DL_URL"; then
            fltk-dialog --question --center --text="New Discord PTB version has been released!\nDownload version $NEW_APP_VERSION now?"
            case $? in
                1)
                    exit 0
                    ;;
            esac
            fltk-dialog --message --center --text="Please choose the save location for 'discord-ptb'"
            DEST_DIR="$(fltk-dialog --directory --center --native)"
            if [ -z "$DEST_DIR" ] || [[ "$DEST_DIR" =~ "/tmp/." ]]; then
                fltk-dialog --message --center --text="Invalid directory selected; using $HOME/Downloads"
                DEST_DIR="$HOME/Downloads"
            fi
            if [ -w "$DEST_DIR" ]; then
                mkdir -p "$DEST_DIR"
                fltk-dialog --progress --center --pulsate --no-cancel --no-escape --text="Downloading Discord PTB" &
                PROGRESS_PID=$!
                curl -sSL -o "$DEST_DIR"/discord-ptb "$GITHUB_DL_URL" || { fltk-dialog --warning --center --text="Failed to download Discord PTB!\nPlease try again."; exit 1; }
                chmod +x "$DEST_DIR"/discord-ptb
                kill -SIGTERM -f $PROGRESS_PID
            else
                PASSWORD="$(fltk-dialog --password --center --text="Enter your password to download Discord PTB to $DEST_DIR")"
                echo "$PASSWORD" | sudo -S mkdir -p "$DEST_DIR" || { fltk-dialog --warning --center --text="Failed to create $DEST_DIR!\nPlease try again."; exit 1; }
                fltk-dialog --progress --center --pulsate --no-cancel --no-escape --text="Downloading Discord PTB" &
                PROGRESS_PID=$!
                curl -sSL -o /tmp/discord-ptb-"$NEW_APP_VERSION"-x86_64.AppImage "$GITHUB_DL_URL" || { fltk-dialog --warning --center --text="Failed to download Discord PTB!\nPlease try again."; exit 1; }
                chmod +x /tmp/discord-ptb-"$NEW_APP_VERSION"-x86_64.AppImage 
                echo "$PASSWORD" | sudo -S mv /tmp/discord-ptb-"$NEW_APP_VERSION"-x86_64.AppImage "$DEST_DIR"/discord-ptb || \
                { fltk-dialog --warning --center --text="Failed to move Discord PTB to $DEST_DIR!\nPlease try again."; rm -f /tmp/discord-ptb-"$APP_VERSION"-x86_64.AppImage; exit 1; }
                kill -SIGTERM -f $PROGRESS_PID
            fi
            fltk-dialog --message --center --text="Discord PTB $NEW_APP_VERSION has been downloaded to $DEST_DIR\nLaunching Discord PTB now..."
            "$DEST_DIR"/discord-ptb &
            exit 0
        else
            fltk-dialog --question --center --text="New Discord PTB version has been released!\nUse deb2appimage to build an AppImage for $NEW_APP_VERSION now?"
            case $? in
                1)
                    exit 0
                    ;;
            esac
            mkdir -p "$HOME"/.cache/deb2appimage
            fltk-dialog --message --center --text="Please choose the save location for 'discord-ptb'"
            DEST_DIR="$(fltk-dialog --directory --center --native)"
            if [ -z "$DEST_DIR" ] || [[ "$DEST_DIR" =~ "/tmp/." ]]; then
                fltk-dialog --message --center --text="Invalid directory selected; using $HOME/Downloads"
                DEST_DIR="$HOME/Downloads"
            fi
            if [ -w "$DEST_DIR" ]; then
                mkdir -p "$DEST_DIR"
            else
                PASSWORD="$(fltk-dialog --password --center --text="Enter your password to build Discord PTB AppImage to $DEST_DIR")"
                echo "$PASSWORD" | sudo -S mkdir -p "$DEST_DIR" || { fltk-dialog --warning --center --text="Failed to create $DEST_DIR!\nPlease try again."; exit 1; }
            fi
            cp "$RUNNING_DIR"/deb2appimage "$HOME"/.cache/deb2appimage/deb2appimage.AppImage
            cp "$RUNNING_DIR"/fltk-dialog "$HOME"/.cache/deb2appimage/fltk-dialog
            cp "$RUNNING_DIR"/discord-ptb.sh "$HOME"/.cache/deb2appimage/discord-ptb.sh
            cp "$RUNNING_DIR"/discord-ptb.json "$HOME"/.cache/deb2appimage/discord-ptb.json
            fltk-dialog --progress --center --pulsate --no-cancel --no-escape --text="Downloading Discord PTB" &
            PROGRESS_PID=$!
            echo "$(sed "s%\"version\": \"0..*%\"version\": \"$NEW_APP_VERSION\",%g" "$HOME"/.cache/deb2appimage/discord-ptb.json)" > "$HOME"/.cache/deb2appimage/discord-ptb.json
            deb2appimage -j "$RUNNING_DIR"/discord-ptb.json -o "$HOME"/Downloads || { fltk-dialog --warning --center --text="Failed to build Discord PTB AppImage\nPlease create an issue here:\nhttps://github.com/simoniz0r/Discord-PTB-AppImage/issues/new"; exit 1; }
            kill -SIGTERM -f $PROGRESS_PID
            if [ -w "$DEST_DIR" ]; then
                mv "$HOME"/Downloads/discord-ptb-"$APP_VERSION"-x86_64.AppImage "$DEST_DIR"/discord-ptb
            else
                echo "$PASSWORD" | sudo -S mv "$HOME"/Downloads/discord-ptb-"$NEW_APP_VERSION"-x86_64.AppImage "$DEST_DIR"/discord-ptb || \
                { fltk-dialog --warning --center --text="Failed to move Discord PTB to $DEST_DIR!\nPlease try again."; rm -f "$HOME"/Downloads/discord-ptb-"$APP_VERSION"-x86_64.AppImage; exit 1; }
            fi
            fltk-dialog --message --center --text="Discord PTB AppImage $NEW_APP_VERSION has been built to $DEST_DIR\nLaunching Discord PTB now..."
            "$DEST_DIR"/discord-ptb &
            exit 0
        fi
    else
        echo "$APP_VERSION"
        echo "Discord PTB is up to date"
        echo
    fi
}

case $1 in
    --remove)
        ./usr/bin/discord-ptb.wrapper --remove-appimage-desktop-integration && echo "Removed .desktop file and icon for menu integration for Discord PTB." || echo "Failed to remove .desktop file and icon!"
        exit 0
        ;;
    --help)
        echo "Arguments provided by Discord PTB AppImage:"
        echo "--remove - Remove .desktop file and icon for menu integration if created by the AppImage."
        echo "--help   - Show this help output."
        echo
        echo "All other arguments will be passed to Discord PTB; any valid arguments will function the same as a regular Discord PTB install."
        exit 0
        ;;
    *)
        if ! type curl > /dev/null 2>&1; then
            fltk-dialog --message --center --text="Please install 'curl' to enable update checks"
        else
            updatediscordptb
        fi
        ./usr/bin/discord-ptb.wrapper &
        sleep 30
        while ps aux | grep -v 'grep' | grep -q 'DiscordPTB'; do
            sleep 30
        done
        exit 0
        ;;
esac
