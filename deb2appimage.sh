#!/bin/bash
# Title: deb2appimage
# Author: simonizor
# License: MIT
# Description: Build AppImages from deb packages on any distro with simple json configuration
# Dependencies: jq, curl, ar, tar

# detect argument input
for D2AARG in $@; do
    case $D2AARG in
        # set path to json file (required)
        -j|--json)
            shift
            D2A_JSON="$(readlink -f $1)"
            shift
            ;;
        # set output directory (optional)
        -o|--output)
            shift
            D2A_OUTPUT="$(readlink -f $1)"
            shift
            ;;
        # turn on quiet mode
        -q|--quiet)
            D2A_QUIET="TRUE"
            shift
            ;;
        # turn on debug mode
        --debug)
            set -x
            shift
            ;;
    esac
done

function d2aexit() {
    case $1 in
        # normal exit; remove "$HOME"/.cache/deb2appimage before exiting
        0)
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 0
            ;;
        # missing dependencies
        1)
            if [ ! "$D2A_QUIET" = "TRUE" ]; then
                echo "Dependency Error!"
                echo "Missing: $2"
                [ -n "$3" ] && echo "$3"
                echo "Exit code 1"
            fi
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 1
            ;;
        # user input error
        2)
            if [ ! "$D2A_QUIET" = "TRUE" ]; then
                echo "Input Error!"
                echo "$2"
                [ -n "$3" ] && echo "$3"
                echo "Exit code 2"
            fi
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 2
            ;;
        # curl error
        3)
            if [ ! "$D2A_QUIET" = "TRUE" ]; then
                echo "Download Error!"
                echo "Error while downloading $2"
                [ -n "$3" ] && echo "$3"
                echo "Exit code 3"
            fi
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 3
            ;;
        # file/dir error
        4)
            if [ ! "$D2A_QUIET" = "TRUE" ]; then
                echo "Directory/File Error!"
                echo "Error while creating file/directory $2"
                [ -n "$3" ] && echo "$3"
                echo "Exit code 4"
            fi
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 4
            ;;
        # deb extraction error
        5)
            if [ ! "$D2A_QUIET" = "TRUE" ]; then
                echo "Error Extracting Deb!"
                echo "Error while extracting $2"
                [ -n "$3" ] && echo "$3"
                echo "Exit code 5"
            fi
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 5
            ;;
        # appimagetool error
        6)
            if [ ! "$D2A_QUIET" = "TRUE" ]; then
                echo "Error Running appimagetool!"
                echo "appimagetool failed to build $2"
                [ -n "$3" ] && echo "$3"
                echo "Exit code 6"
            fi
            rm -rf "$HOME"/.cache/deb2appimage/*
            exit 6
            ;;
    esac
}

function d2aprerun() {
    if [ -d "$HOME/.cache/deb2appimage/AppDir" ]; then
        d2aexit 4 "$HOME/.cache/deb2appimage/AppDir" "Directory exists!"
    fi
    mkdir -p "$HOME"/.cache/deb2appimage/AppDir
    mkdir -p "$HOME"/.cache/deb2appimage/debs
    mkdir -p "$HOME"/.cache/deb2appimage/other
    cp "$D2A_JSON" "$HOME"/.cache/deb2appimage/build.json
}

# execute prerun command if not null
function preruncmd() {
    PRERUN_CMD="$(jq -r '.buildinfo[0].prerun[]' "$HOME"/.cache/deb2appimage/build.json | sed "s,^.*,& \&\& ,g" | tr -d '\n' | rev | cut -f3- -d' ' | rev)"
    if [ ! "$PRERUN_CMD" = "null" ]; then
        bash -c "$PRERUN_CMD" || d2aexit 2 "'prerun' failed!" "Failed to execute: $PRERUN_CMD"
    fi
}

# function to find latest debs based on user input
function getlatestdeb() {
    DEB_NAME="$1"
    DEB_DISTRO="$2"
    DEB_RELEASE="$3"
    DEB_ARCH="$4"
    case $DEB_DISTRO in
        Debian|debian)
            DEB_DISTRO_URL="debian.org"
            ;;
        Ubuntu|ubuntu)
            DEB_DISTRO_URL="ubuntu.com"
            ;;
        *)
            d2aexit 2 "Invalid 'distrorepo' entered in json file" "Valid choices are Debian and Ubuntu"
            ;;
    esac
    # find latest deb url using grep and head -n 1
    LATEST_DEB_URL="$(curl -sL "https://packages.$DEB_DISTRO_URL/$DEB_RELEASE/$DEB_ARCH/$DEB_NAME/download" | grep "<li>*..*$DEB_ARCH.deb" | cut -f2 -d'"' | head -n 1)"
    curl -sL "$LATEST_DEB_URL" -o "$HOME"/.cache/deb2appimage/debs/"$DEB_NAME".deb || d2aexit 3 "$DEB_NAME.deb" "URL: $LATEST_DEB_URL"
}

# function that uses jq to get package's deps from build.json
function getappdeps() {
    if [ ! "$(jq -r '.buildinfo[0].deps' "$HOME"/.cache/deb2appimage/build.json)" = "null" ]; then
        COUNT_NUM=1
        # run a for loop to download the latest version of each deb using getlatestdeb function
        for appdep in $(jq -r '.buildinfo[0].deps' "$HOME"/.cache/deb2appimage/build.json | tr ',' '\n'); do
            DEB_REPO_DISTRO="$(jq -r '.buildinfo[0].distrorepo' "$HOME"/.cache/deb2appimage/build.json | cut -f${COUNT_NUM} -d',')"
            DEB_REPO_VERSION="$(jq -r '.buildinfo[0].repoversion' "$HOME"/.cache/deb2appimage/build.json | cut -f${COUNT_NUM} -d',')"
            DEB_REPO_ARCH="$(jq -r '.buildinfo[0].repoarch' "$HOME"/.cache/deb2appimage/build.json | cut -f${COUNT_NUM} -d',')"
            [ -z "$DEB_REPO_DISTRO" ] && DEB_REPO_DISTRO="$DEB_LAST_DISTRO"
            [ -z "$DEB_REPO_ARCH" ] && DEB_REPO_ARCH="$DEB_LAST_ARCH"
            [ -z "$DEB_REPO_VERSION" ] && DEB_REPO_VERSION="$DEB_LAST_VERSION"
            getlatestdeb "$appdep" "$DEB_REPO_DISTRO" "$DEB_REPO_VERSION" "$DEB_REPO_ARCH"
            COUNT_NUM=$(($COUNT_NUM+1))
            DEB_LAST_DISTRO="$DEB_REPO_DISTRO"
            DEB_LAST_ARCH="$DEB_REPO_ARCH"
            DEB_LAST_VERSION="$DEB_REPO_VERSION"
        done
    fi
}

# function to extract debs and move them to AppDir folder
function debextract () {
    mkdir -p "$HOME"/.cache/deb2appimage/debs/temp
    cd "$HOME"/.cache/deb2appimage/debs/temp
    mv "$HOME"/.cache/deb2appimage/debs/"$1" "$HOME"/.cache/deb2appimage/debs/temp/"$1"
    ar x "$HOME"/.cache/deb2appimage/debs/temp/"$1"
    rm -f "$HOME"/.cache/deb2appimage/debs/temp/"$1"
    rm -f "$HOME"/.cache/deb2appimage/debs/temp/control.tar.gz
    rm -f "$HOME"/.cache/deb2appimage/debs/temp/debian-binary
    tar -xf "$HOME"/.cache/deb2appimage/debs/temp/data.tar.* -C "$HOME"/.cache/deb2appimage/debs/temp/
    rm -f "$HOME"/.cache/deb2appimage/debs/temp/data.tar.*
    chmod -R 755 ~/.cache/deb2appimage
    cp -r "$HOME"/.cache/deb2appimage/debs/temp/* "$HOME"/.cache/deb2appimage/AppDir/
    rm -rf "$HOME"/.cache/deb2appimage/*/debs/temp/*
}

# function that runs a for loop to find all downloaded debs and extract them
function finddownloadeddebs() {
    for debpkg in $(dir -C -w 1 "$HOME"/.cache/deb2appimage/debs); do
        debextract "$debpkg" || d2aexit 5 "$debpkg"
    done
    rm -rf "$HOME"/.cache/deb2appimage/*/debs
}

# function that places files in places where appimagetool expects them to be for building AppImage
function prepareappdir() {
    APP_NAME="$(jq -r '.buildinfo[0].name' "$HOME"/.cache/deb2appimage/build.json)"
    BINARY_PATH="$(jq -r '.buildinfo[0].binarypath' "$HOME"/.cache/deb2appimage/build.json)"
    DESKTOP_PATH="$(jq -r '.buildinfo[0].desktoppath' "$HOME"/.cache/deb2appimage/build.json)"
    ICON_PATH="$(jq -r '.buildinfo[0].iconpath' "$HOME"/.cache/deb2appimage/build.json)"
    USE_WRAPPER="$(jq -r '.buildinfo[0].usewrapper' "$HOME"/.cache/deb2appimage/build.json)"
    [ "$APP_NAME" = "null" ] && d2aexit 2 "Missing required 'appname' in json file"
    [ ! -f "$HOME/.cache/deb2appimage/AppDir$BINARY_PATH" ] && d2aexit 2 "Binary file not found at binarypath in json file"
    # Download icon if it does not exist
    if [ ! -f "$HOME/.cache/deb2appimage/AppDir$ICON_PATH" ]; then
        echo "$ICON_PATH not found; downloading generic icon..."
        curl -sL "https://raw.githubusercontent.com/iconic/open-iconic/master/png/file-6x.png" -o "$HOME"/.cache/deb2appimage/AppDir/."$APP_NAME".png
        ICON_PATH="/.$APP_NAME.png"
    fi
    # Create .desktop file if it does not exist
    if [ ! -f "$HOME/.cache/deb2appimage/AppDir$DESKTOP_PATH" ]; then
        echo "$DESKTOP_PATH not found; creating generic .desktop file..."
        cat > "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME".desktop << EOL
[Desktop Entry]
Type=Application
Name="$APP_NAME"
Comment="$APP_NAME"
Exec=."$BINARY_PATH"
Categories=Utility;
Icon="$APP_NAME"
StartupNotify=false
Terminal=true

EOL
    else
        cp "$HOME"/.cache/deb2appimage/AppDir"$DESKTOP_PATH" "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME".desktop
        DESKTOP_CATEGORIES="$(grep '^Categories=' "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME".desktop)"
        if [ -z "$DESKTOP_CATEGORIES" ]; then
            echo "Categories=Utility;" >> "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME".desktop
        elif [ ! "$(echo $DESKTOP_CATEGORIES | rev | cut -c1)" = ";" ]; then
            sed -i 's%^Categories=.*%Categories=Utility;%g' "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME".desktop
        fi
    fi
    if [ "$USE_WRAPPER" = "true" ]; then
        curl -sL "https://raw.githubusercontent.com/simoniz0r/deb2appimage/master/resources/desktopintegration" -o "$HOME"/.cache/deb2appimage/AppDir"$BINARY_PATH".wrapper || d2aexit 3 "wrapper script"
        chmod a+x "$HOME"/.cache/deb2appimage/AppDir"$BINARY_PATH".wrapper
    fi
    ICON_TYPE="$(echo $ICON_PATH | rev | cut -f1 -d'.' | rev)"
    ICON_SIZE=$(file "$HOME"/.cache/deb2appimage/AppDir${ICON_PATH} | cut -f2 -d',' | tr -d '[:blank:]' | cut -f1 -d'x')
    mkdir -p "$HOME"/.cache/deb2appimage/AppDir/usr/share/icons/default/${ICON_SIZE}x${ICON_SIZE}/apps
    cp "$HOME"/.cache/deb2appimage/AppDir"$ICON_PATH" "$HOME"/.cache/deb2appimage/AppDir/usr/share/icons/default/${ICON_SIZE}x${ICON_SIZE}/apps/"$APP_NAME"."$ICON_TYPE"
    cp "$HOME"/.cache/deb2appimage/AppDir"$ICON_PATH" "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME"."$ICON_TYPE"
    sed -i "s,^Exec=.*,Exec=.$BINARY_PATH,g;s,^Icon=.*,Icon=$APP_NAME,g" "$HOME"/.cache/deb2appimage/AppDir/"$APP_NAME".desktop
}

# function that downloads AppRun and creates AppRun.conf
function prepareapprun() {
curl -sL "https://raw.githubusercontent.com/simoniz0r/deb2appimage/master/resources/AppRun" -o "$HOME"/.cache/deb2appimage/AppDir/AppRun || d2aexit 3 "AppRun script"
chmod a+x "$HOME"/.cache/deb2appimage/AppDir/AppRun
APPRUN_SET_PATH="$(jq -r '.apprunconf[0].setpath' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_LIBPATH="$(jq -r '.apprunconf[0].setlibpath' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_PYTHONPATH="$(jq -r '.apprunconf[0].setpythonpath' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_PYTHONHOME="$(jq -r '.apprunconf[0].setpythonhome' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_PYTHONBYTE="$(jq -r '.apprunconf[0].setpythondontwritebytecode' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_XDG="$(jq -r '.apprunconf[0].setxdgdatadirs' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_PERL="$(jq -r '.apprunconf[0].setperllib' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_SET_QT="$(jq -r '.apprunconf[0].setqtpluginpath' "$HOME"/.cache/deb2appimage/build.json | tr '[:lower:]' '[:upper:]')"
APPRUN_EXEC="$(jq -r '.apprunconf[0].exec' "$HOME"/.cache/deb2appimage/build.json)"
case $APPRUN_EXEC in
    /*)
        APPRUN_EXEC=".$APPRUN_EXEC"
        ;;
esac
cat >"$HOME"/.cache/deb2appimage/AppDir/AppRun.conf << EOL
APPRUN_SET_PATH="$APPRUN_SET_PATH"
APPRUN_SET_LD_LIBRARY_PATH="$APPRUN_SET_LIBPATH"
APPRUN_SET_PYTHONPATH="$APPRUN_SET_PYTHONPATH"
APPRUN_SET_PYTHONHOME="$APPRUN_SET_PYTHONHOME"
APPRUN_SET_PYTHONDONTWRITEBYTECODE="$APPRUN_SET_PYTHONBYTE"
APPRUN_SET_XDG_DATA_DIRS="$APPRUN_SET_XDG"
APPRUN_SET_PERLLIB="$APPRUN_SET_PERL"
APPRUN_SET_GSETTINGS_SCHEMA_DIR="$APPRUN_SET_GSETTINGS"
APPRUN_SET_QT_PLUGIN_PATH="$APPRUN_SET_QT"
APPRUN_EXEC="$APPRUN_EXEC"

EOL
}

# function that runs postruncmd
function postruncmd() {
    POSTRUN_CMD="$(jq -r '.buildinfo[0].postrun[]' "$HOME"/.cache/deb2appimage/build.json | sed "s,^.*,& \&\& ,g" | tr -d '\n' | rev | cut -f3- -d' ' | rev)"
    if [ ! "$POSTRUN_CMD" = "null" ]; then
        bash -c "$POSTRUN_CMD" || d2aexit 2 "'postrun' failed!" "Failed to execute: $POSTRUN_CMD"
    fi
}

# function that downloads appimagetool and uses it to build the AppImage to the --output directory
function buildappimage() {
    APP_VERSION="$(jq -r '.buildinfo[0].version' "$HOME"/.cache/deb2appimage/build.json)"
    if [ -z "$APP_VERSION" ] || [ "$APP_VERSION" = "null" ]; then
        APP_VERSION="$(date +'%F')"
    fi
    curl -sL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" -o "$HOME"/.cache/deb2appimage/appimagetool || d2aexit 3 "appimagetool"
    chmod +x "$HOME"/.cache/deb2appimage/appimagetool
    if [ "$D2A_QUIET" = "TRUE" ]; then
        ARCH="$(uname -m)" "$HOME"/.cache/deb2appimage/appimagetool "$@" "$HOME"/.cache/deb2appimage/AppDir "$D2A_OUTPUT"/"$APP_NAME"-"$APP_VERSION"-"$(uname -m)".AppImage > /dev/null 2>&1 || d2aexit 6 "$APP_NAME"
    else
        ARCH="$(uname -m)" "$HOME"/.cache/deb2appimage/appimagetool "$@" "$HOME"/.cache/deb2appimage/AppDir "$D2A_OUTPUT"/"$APP_NAME"-"$APP_VERSION"-"$(uname -m)".AppImage || d2aexit 6 "$APP_NAME"
    fi
}

function d2ahelp() {
printf '%s\n' "deb2appimage 0.0.3
Usage deb2appimage [argument] [input]

deb2appimage is a tool for creating AppImages using deb packages. json files are used
to provide simple configuration for building the AppImage.  Contrary to the name, other
package types can also be used as the source of the application (or even its deps), but
those files will have to be placed in '~/.cache/deb2appimage/AppDir/' manually with a
prerun script.

Arguments:
--help|-h       Show this output and exit
--json|-j       Specify the location of the json file for building the AppImage (required)
--output|-o     Specify the output directory of the AppImage (optional; $HOME will be used by default)
--quiet|-q      Enable quiet mode
--debug         Enable debug mode

Any arguments not listed above will be passed to 'appimagetool' when building the AppImage.

Examples:
deb2appimage -j $HOME/my-app.json
deb2appimage -j $HOME/my-app.json -o $HOME/AppImages
deb2appimage -j $HOME/my-app.json -o $HOME/AppImages -q
deb2appimage -j $HOME/my-app.json -o $HOME/AppImages --debug
"
}

# check for help argument
case $1 in
    -h|--help)
        d2ahelp
        d2aexit 0
        ;;
esac

# check for deb2appimage's dependencies and exit if not installed
mkdir -p "$HOME"/.cache/deb2appimage
type jq > /dev/null 2>&1 || echo "jq" >> "$HOME"/.cache/deb2appimage/missingdeps
type curl > /dev/null 2>&1 || echo "curl" >> "$HOME"/.cache/deb2appimage/missingdeps
type ar > /dev/null 2>&1 || echo "ar (binutils)" >> "$HOME"/.cache/deb2appimage/missingdeps
type tar > /dev/null 2>&1 || echo "tar" >> "$HOME"/.cache/deb2appimage/missingdeps
[ -f "$HOME/.cache/deb2appimage/missingdeps" ] && d2aexit 1 "$(cat "$HOME"/.cache/deb2appimage/missingdeps | tr '\n' ',')"

# check required inputs
[ -z "$D2A_JSON" ] && d2ahelp && d2aexit 2 "Missing required --json input"
jq '.' "$D2A_JSON" > /dev/null 2>&1 || d2aexit 2 "$D2A_JSON not valid json file"
[ -z "$D2A_OUTPUT" ] && D2A_OUTPUT="$HOME"

d2aprerun
[ ! "$D2A_QUIET" = "TRUE" ] && echo "Executing prerun..."
preruncmd
[ ! "$D2A_QUIET" = "TRUE" ] && echo "Downloading dependencies..."
getappdeps
[ ! "$D2A_QUIET" = "TRUE" ] && echo "Extracting dependencies..."
finddownloadeddebs
[ ! "$D2A_QUIET" = "TRUE" ] && echo "Preparing AppImage AppDir..."
prepareappdir
prepareapprun
[ ! "$D2A_QUIET" = "TRUE" ] && echo "Executing postrun..."
postruncmd
[ ! "$D2A_QUIET" = "TRUE" ] && echo "Using 'appimagetool' to build AppImage for '$APP_NAME' to '$D2A_OUTPUT'..."
buildappimage && d2aexit 0
