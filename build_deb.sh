#!/bin/bash

# Build script for creating a .deb package for the Seed Flutter app

set -e

APP_NAME="seed"
APP_VERSION="1.0.0"
DESCRIPTION="Generate deterministic Nostr private keys from memorable seed phrases"
MAINTAINER="Russell npub1kg4sdvz3l4fr99n2jdz2vdxe2mpacva87hkdetv76ywacsfq5leqquw5te"
ARCHITECTURE="amd64"

# Clean and build the Linux app
echo "Building Flutter Linux app..."
flutter clean
flutter build linux --release

# Create debian package structure
DEB_DIR="build/debian"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"

# Copy the built application
cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/bin/"

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $APP_VERSION
Section: utils
Priority: optional
Architecture: $ARCHITECTURE
Maintainer: $MAINTAINER
Description: $DESCRIPTION
 A Flutter application for generating deterministic Nostr private keys (nsec) 
 from memorable seed phrases. Simple and secure key generation for Nostr.
EOF

# Create desktop file
cat > "$DEB_DIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=Seed
Comment=$DESCRIPTION
Exec=/usr/bin/Seed
Icon=/usr/share/pixmaps/seed.png
Terminal=false
Type=Application
Categories=Utility;Security;
StartupWMClass=Com.example.seed
EOF

# Copy the icon file
if [ -f "icon-512.png" ]; then
    cp "icon-512.png" "$DEB_DIR/usr/share/pixmaps/seed.png"
else
    echo "Warning: icon-512.png not found, package will not have an icon"
fi

# Build the .deb package
echo "Building .deb package..."
dpkg-deb --build "$DEB_DIR" "build/${APP_NAME}_${APP_VERSION}_${ARCHITECTURE}.deb"

echo "✅ .deb package created: build/${APP_NAME}_${APP_VERSION}_${ARCHITECTURE}.deb"
echo ""
echo "To install: sudo dpkg -i build/${APP_NAME}_${APP_VERSION}_${ARCHITECTURE}.deb"
echo "To remove: sudo apt remove $APP_NAME"