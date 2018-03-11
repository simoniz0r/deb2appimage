#!/bin/bash

mkdir -p "$HOME"/.cache/deb2appimage/AppDir/usr/bin
mkdir -p "$HOME"/.cache/deb2appimage/AppDir/usr/share/deb2appimage
cp ~/github/deb2appimage/deb2appimage.sh ~/.cache/deb2appimage/AppDir/usr/bin/deb2appimage
chmod a+x ~/.cache/deb2appimage/AppDir/usr/bin/deb2appimage
cp ~/github/deb2appimage/spm.png ~/.cache/deb2appimage/AppDir/usr/share/deb2appimage/deb2appimage.png

cat > ~/.cache/deb2appimage/AppDir/usr/share/deb2appimage/deb2appimage.desktop << EOL
[Desktop Entry]
Type=Application
Name=deb2appimage
GenericName=deb2appimage
Comment=Build AppImages from deb packages on any distro with simple json configuration
Exec=deb2appimage
Categories=Utility;
Icon=deb2appimage
StartupNotify=false
Terminal=true

EOL
