#!/bin/bash

curl -sL 'https://discordapp.com/api/download/canary?platform=linux&format=deb' -o "$HOME"/.cache/deb2appimage/debs/discord-canary.deb || exit 1
mkdir -p ~/.cache/deb2appimage/AppDir/usr/bin
mv ~/.cache/deb2appimage/deb2appimage.AppImage ~/.cache/deb2appimage/AppDir/usr/bin/deb2appimage
cp ~/.cache/deb2appimage/discord-canary-prerun.sh ~/.cache/deb2appimage/AppDir/usr/bin/.discord-canary-prerun.sh
cp ~/.cache/deb2appimage/discord-canary.json ~/.cache/deb2appimage/AppDir/usr/bin/discord-canary.json

cat >"$HOME"/.cache/deb2appimage/AppDir/usr/bin/discord-canary.sh << \EOL
#!/bin/bash

REALPATH="$(readlink -f $0)"
RUNNING_DIR="$(dirname "$REALPATH")"

case $1 in
    --update)
        if type deb2appimage >/dev/null 2>&1; then
            mkdir -p "$HOME"/Downloads
            mkdir -p "$HOME"/.cache/deb2appimage
            cp "$RUNNING_DIR"/deb2appimage "$HOME"/.cache/deb2appimage/deb2appimage.AppImage
            cp "$RUNNING_DIR"/.discord-canary-prerun.sh "$HOME"/.cache/deb2appimage/discord-canary-prerun.sh
            cp "$RUNNING_DIR"/discord-canary.json "$HOME"/.cache/deb2appimage/discord-canary.json
            chmod +x "$HOME"/.cache/deb2appimage/discord-canary-prerun.sh
            deb2appimage -j "$RUNNING_DIR"/discord-canary.json -o "$HOME"/Downloads || { echo -e "Failed to build Discord Canary AppImage\nPlease create an issue here: https://github.com/simoniz0r/Discord-Canary-AppImage/issues/new"; exit 1; }
        fi
        ;;
    --remove)
        ./usr/bin/discord-canary.wrapper --remove-appimage-desktop-integration && echo "Removed .desktop file and icon for menu integration for Discord Canary." || echo "Failed to remove .desktop file and icon!"
        exit 0
        ;;
    --help)
        echo "Arguments provided by Discord Canary AppImage:"
        echo "--update - Automatically build an AppImage for the latest version of Discord Canary.  Will be moved to '~/Downloads'"
        echo "--remove - Remove .desktop file and icon for menu integration if created by the AppImage."
        echo "--help   - Show this help output."
        echo
        echo "All other arguments will be passed to Discord Canary; any valid arguments will function the same as a regular Discord Canary install."
        exit 0
        ;;
    *)
        ./usr/bin/discord-canary.wrapper &
        sleep 15
        if ! pgrep DiscordCanary; then
            sleep 60
        fi
        CANARY_VER_DIR="$(dir -C -w 1 $HOME/.config/discordcanary | grep '^[0-9].[0-9].[0-9]')"
        if [ -d "$HOME/.config/discordcanary/$CANARY_VER_DIR/modules/pending" ] && [ $(dir -C -w 1 $HOME/.config/discordcanary/$CANARY_VER_DIR/modules/pending | wc -l) -gt 0 ]; then
            sleep 240
        fi
        exit 0
        ;;
esac

EOL
chmod a+x "$HOME"/.cache/deb2appimage/AppDir/usr/bin/discord-canary.sh || exit 1
