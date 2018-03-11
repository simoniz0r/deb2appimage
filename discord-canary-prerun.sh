#!/bin/bash

curl -sL 'https://discordapp.com/api/download/canary?platform=linux&format=deb' -o "$HOME"/.cache/deb2appimage/debs/discord-canary.deb || exit 1

cat >"$HOME"/.cache/deb2appimage/discord-canary.sh << \EOL
#!/bin/bash

case $1 in
    --update)
        if type wget >/dev/null 2>&1; then
            echo "Downloading appimagebuild to build an AppImage for the latest version of Discord Canary..."
            if [ ! -d "$HOME/Downloads" ]; then
                mkdir "$HOME"/Downloads
            fi
            wget "https://github.com/simoniz0r/AppImages/releases/download/appimagebuild/appimagebuild-light-latest-x86_64.AppImage" -O "$HOME"/Downloads/appimagebuild && echo "Using appimagebuild to build an AppImage for the latest version of Discord Canary..." || { echo "Failed to download appimagebuild!"; exit 1; }
            chmod a+x "$HOME"/Downloads/appimagebuild
            "$HOME"/Downloads/appimagebuild discord-canary || { echo "Failed to build an AppImage for the latest version of Discord Canary.  Please report an issue here: https://github.com/simoniz0r/AppImages/issues"; rm -f "$HOME"/Downloads/appimagebuild; exit 1; }
            rm -f "$HOME"/Downloads/appimagebuild
            exit 0
        elif type curl >/dev/null 2>&1; then
            echo "Downloading appimagebuild to build an AppImage for the latest version of Discord Canary..."
            if [ ! -d "$HOME/Downloads" ]; then
                mkdir "$HOME"/Downloads
            fi
            curl -L -o "$HOME"/Downloads/appimagebuild "https://github.com/simoniz0r/AppImages/releases/download/appimagebuild/appimagebuild-light-latest-x86_64.AppImage" && echo "Using appimagebuild to build an AppImage for the latest version of Discord Canary..." || { echo "Failed to download appimagebuild!"; exit 1; }
            chmod a+x "$HOME"/Downloads/appimagebuild
            "$HOME"/Downloads/appimagebuild discord-canary || { echo "Failed to build an AppImage for the latest version of Discord Canary.  Please report an issue here: https://github.com/simoniz0r/AppImages/issues"; rm -f "$HOME"/Downloads/appimagebuild; exit 1; }
            rm -f "$HOME"/Downloads/appimagebuild
            exit 0
        else
            echo "Cannot download appimagebuild to build an AppImage for new version of Discord Canary; curl or wget not installed!"
            exit 1
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
        ./usr/bin/discord-canary.wrapper && sleep 15
        ;;
esac

EOL
chmod a+x "$HOME"/.cache/deb2appimage/discord-canary.sh || exit 1
