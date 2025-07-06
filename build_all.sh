#!/bin/bash

# Build script for all platforms - Seed Flutter app

set -e

APP_NAME="Seed"
APP_VERSION=$(grep '^version:' pubspec.yaml | cut -d ' ' -f 2 | cut -d '+' -f 1)
DESCRIPTION="Generate deterministic Nostr private keys from memorable seed phrases"
MAINTAINER="Russell npub1kg4sdvz3l4fr99n2jdz2vdxe2mpacva87hkdetv76ywacsfq5leqquw5te"
ARCHITECTURE="amd64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Building Seed app for all platforms...${NC}"

# Create output directory structure
mkdir -p build/outputs

# Clean first
echo -e "${YELLOW}🧹 Cleaning...${NC}"
flutter clean
flutter pub get

# Build Web
echo -e "${YELLOW}🌐 Building Web...${NC}"
flutter build web --release
mkdir -p build/temp/web
mkdir -p build/outputs
cp -r build/web/* build/temp/web/
cd build/temp && zip -r ../outputs/Seed-${APP_VERSION}-web.zip web/ && cd ../..
echo -e "${GREEN}✅ Web build completed -> build/outputs/Seed-${APP_VERSION}-web.zip${NC}"

# Build Linux
echo -e "${YELLOW}🐧 Building Linux...${NC}"
flutter build linux --release
mkdir -p build/temp/linux
cp -r build/linux/x64/release/bundle/. build/temp/linux/

# Create desktop file for Linux package
cat > "build/temp/linux/seed.desktop" << EOF
[Desktop Entry]
Name=Seed
Comment=$DESCRIPTION
Exec=./Seed
Icon=seed
Terminal=false
Type=Application
Categories=Utility;Security;
StartupWMClass=Com.example.seed
Path=%k
EOF

# Copy icon to Linux package if available
if [ -f "icon-512.png" ]; then
    cp "icon-512.png" "build/temp/linux/seed.png"
fi

cd build/temp && zip -r ../outputs/Seed-${APP_VERSION}-linux.zip linux/ && cd ../..
echo -e "${GREEN}✅ Linux build completed -> build/outputs/Seed-${APP_VERSION}-linux.zip${NC}"

# Build Android APK
echo -e "${YELLOW}🤖 Building Android APK...${NC}"
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk build/outputs/Seed-${APP_VERSION}.apk
echo -e "${GREEN}✅ APK build completed -> build/outputs/Seed-${APP_VERSION}.apk${NC}"

# Build Android AAB
echo -e "${YELLOW}🤖 Building Android AAB...${NC}"
flutter build appbundle --release
cp build/app/outputs/bundle/release/app-release.aab build/outputs/Seed-${APP_VERSION}.aab
echo -e "${GREEN}✅ AAB build completed -> build/outputs/Seed-${APP_VERSION}.aab${NC}"

# Build DEB package
echo -e "${YELLOW}📦 Building DEB package...${NC}"
DEB_DIR="build/debian"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/pixmaps"

# Copy Linux bundle for DEB
cp -r build/linux/x64/release/bundle/* "$DEB_DIR/usr/bin/"

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: seed
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
cat > "$DEB_DIR/usr/share/applications/seed.desktop" << EOF
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

# Copy icon
if [ -f "icon-512.png" ]; then
    cp "icon-512.png" "$DEB_DIR/usr/share/pixmaps/seed.png"
fi

# Build DEB
dpkg-deb --build "$DEB_DIR" "build/outputs/Seed_${APP_VERSION}_${ARCHITECTURE}.deb"
echo -e "${GREEN}✅ DEB package completed -> build/outputs/Seed_${APP_VERSION}_${ARCHITECTURE}.deb${NC}"

# Build AppImage
echo -e "${YELLOW}📱 Building AppImage...${NC}"
APPDIR="build/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"

# Copy Linux bundle for AppImage
cp -r build/linux/x64/release/bundle/* "$APPDIR/usr/bin/"

# Create desktop file
cat > "$APPDIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=$APP_NAME
Comment=$DESCRIPTION
Exec=$APP_NAME
Icon=$APP_NAME
Terminal=false
Type=Application
Categories=Utility;Security;
StartupWMClass=Com.example.seed
EOF

# Copy desktop file to AppDir root
cp "$APPDIR/usr/share/applications/$APP_NAME.desktop" "$APPDIR/"

# Copy icon
if [ -f "icon-512.png" ]; then
    cp "icon-512.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
    cp "icon-512.png" "$APPDIR/$APP_NAME.png"
fi

# Create AppRun script
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
DIR="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="$DIR/usr/bin/lib:$LD_LIBRARY_PATH"
exec "$DIR/usr/bin/Seed" "$@"
EOF

chmod +x "$APPDIR/AppRun"

# Download appimagetool if not present
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo "Downloading appimagetool..."
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x appimagetool-x86_64.AppImage
fi

# Build AppImage
ARCH=x86_64 ./appimagetool-x86_64.AppImage "$APPDIR" "build/outputs/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo -e "${GREEN}✅ AppImage completed -> build/outputs/${APP_NAME}-${APP_VERSION}-x86_64.AppImage${NC}"

# Summary
echo -e "\n${GREEN}🎉 All builds completed successfully!${NC}"
echo -e "${GREEN}📁 Outputs available in build/outputs/:${NC}"
echo -e "  🌐 Web: build/outputs/Seed-${APP_VERSION}-web.zip"
echo -e "  🐧 Linux: build/outputs/Seed-${APP_VERSION}-linux.zip"
echo -e "  🤖 Android APK: build/outputs/Seed-${APP_VERSION}.apk"
echo -e "  🤖 Android AAB: build/outputs/Seed-${APP_VERSION}.aab"
echo -e "  📦 DEB: build/outputs/Seed_${APP_VERSION}_${ARCHITECTURE}.deb"
echo -e "  📱 AppImage: build/outputs/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

echo -e "\n${YELLOW}📋 Installation instructions:${NC}"
echo -e "  DEB: sudo dpkg -i build/outputs/Seed_${APP_VERSION}_${ARCHITECTURE}.deb"
echo -e "  AppImage: chmod +x build/outputs/${APP_NAME}-${APP_VERSION}-x86_64.AppImage && ./build/outputs/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo -e "  APK: adb install build/outputs/Seed-${APP_VERSION}.apk"