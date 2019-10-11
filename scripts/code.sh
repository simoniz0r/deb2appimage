#!/bin/bash
# script to build, update, and launch VSCode AppImage

# Get current location
RUNNING_LOC="$(readlink -f "$(dirname "$0")")"
# function to build vscode AppImage using deb2appimage
vscode_build() {
    unset VSCODE_SAVE_DIR
    # tell user to choose dir
    fltk-dialog --message --close-label="Ok" --center --text="Please choose where you would like to save the AppImage of Visual Studio Code."
    cd "$HOME"
    # set VSCODE_SAVE_DIR to directory user chooses
    export VSCODE_SAVE_DIR="$(fltk-dialog --directory --center)"
    # return 1 if no dir chosen
    if [[ -z "$VSCODE_SAVE_DIR" ]]; then
        return 1
    fi
    # use deb2appimage to build latest vscode version
    fltk-dialog --progress --center --pulsate --no-cancel --no-escape --text="Building Visual Studio Code AppImage..." &
    PROGRESS_PID=$!
    deb2appimage -j "$RUNNING_LOC"/vscode.json -o ~/.cache
    kill -SIGTERM -f $PROGRESS_PID
    if [[ ! -f "$HOME/.cache/vscode-latest-x86_64.AppImage" ]]; then
        return 1
    fi
    # check if directory is writable
    if [[ -w "$VSCODE_SAVE_DIR" ]]; then
        mkdir -p "$VSCODE_SAVE_DIR" || \
        { fltk-dialog --message --close-label="Ok" --center --text="Failed to create $VSCODE_SAVE_DIR!\nPlease try again."; rm -f ~/.cache/vscode-latest-x86_64.AppImage; return 1; }
        mv ~/.cache/vscode-latest-x86_64.AppImage "$VSCODE_SAVE_DIR"/code || \
        { fltk-dialog --message --close-label="Ok" --center --text="Failed to move Visual Studio Code to $VSCODE_SAVE_DIR!\nPlease try again."; rm -f ~/.cache/vscode-latest-x86_64.AppImage; return 1; }
    else
        # get password if not writable for use with sudo
        PASSWORD="$(fltk-dialog --password --center --text="Enter your password to save Visual Studio Code to $VSCODE_SAVE_DIR")"
        echo "$PASSWORD" | sudo -S mkdir -p "$VSCODE_SAVE_DIR" || \
        { fltk-dialog --message --close-label="Ok" --center --text="Failed to create $VSCODE_SAVE_DIR!\nPlease try again."; rm -f ~/.cache/vscode-latest-x86_64.AppImage; return 1; }
        echo "$PASSWORD" | sudo -S mv ~/.cache/vscode-latest-x86_64.AppImage "$VSCODE_SAVE_DIR"/code || \
        { fltk-dialog --message --close-label="Ok" --center --text="Failed to move Visual Studio Code to $VSCODE_SAVE_DIR!\nPlease try again."; rm -f ~/.cache/vscode-latest-x86_64.AppImage; return 1; }
    fi
    # if moved to VSCODE_SAVE_DIR, return 0 otherwise return 1
    if [[ -f "$VSCODE_SAVE_DIR/code" ]]; then
        return 0
    else
        return 1
    fi
}
# function to check for vscode update
vscode_update() {
    unset CURRENT_VSCODE_VER NEW_VSCODE_VER
    # get current version from .version file
    export CURRENT_VSCODE_VER="$(cat "$RUNNING_LOC"/.version)"
    # get latest version from header of deb download location
    export NEW_VSCODE_VER="$(curl -sLIX HEAD 'https://update.code.visualstudio.com/latest/linux-deb-x64/stable' | grep -m1 'Location: ' | cut -f2 -d'_')"
    # return 1 if either version is missing
    if [[ -z "$NEW_VSCODE_VER" || -z "$CURRENT_VSCODE_VER" ]]; then
        return 1
    fi
    # return 0 if versions match
    if [[ "$CURRENT_VSCODE_VER" == "$NEW_VSCODE_VER" ]]; then
        return 0
    fi
    # ask user if they want to update
    fltk-dialog --question \
    --center \
    --text="A new version of Visual Studio Code is available.\nCurrent version: $CURRENT_VSCODE_VER\nNew version: $NEW_VSCODE_VER\nUpdate Visual Studio Code to $NEW_VSCODE_VER now?"
    case $? in
        0) sleep 0;;
        *) return 0;;
    esac
    # build vscode AppImage
    vscode_build
    # check exit status of vscode_build function
    case $? in
        0) return 0;;
        *) return 1;;
    esac
}
# check vscode update if .version file exists otherwise build vscode AppImage
if [[ -f "$RUNNING_LOC/.version" ]]; then
    vscode_update
else
    vscode_build
fi
# check exit status of ran function
case $? in
    0)
        # if versions match, run RUNNING_DIR/code
        if [[ "$CURRENT_VSCODE_VER" == "$NEW_VSCODE_VER" ]]; then
            "$RUNNING_LOC"/code
        # otherwise assume new AppImage built and run new AppImage
        else
            "$VSCODE_SAVE_DIR"/code
        fi
        ;;
    *)
        fltk-dialog --message --close-label="Ok" --center --text="Failed to update or build Visual Studio Code."
        # if RUNNING_LOC/code exists, run it
        if [[ -f "$RUNNING_LOC/code" ]]; then
            "$RUNNING_LOC"/code
        # otherwise assume initial build failed and exit
        else
            exit 1
        fi
        ;;
esac
