#!/bin/bash

# Build script for creating an AppImage for the Seed Flutter app

set -e

APP_NAME="Seed"
APP_VERSION="1.0.0"
DESCRIPTION="Generate deterministic Nostr private keys from memorable seed phrases"

# Clean and build the Linux app
echo "Building Flutter Linux app..."
flutter clean
flutter build linux --release

# Create AppDir structure
APPDIR="build/AppDir"
mkdir -p "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"

# Copy the built application
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

# Copy the icon file
if [ -f "icon-512.png" ]; then
    cp "icon-512.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/$APP_NAME.png"
    cp "icon-512.png" "$APPDIR/$APP_NAME.png"
    echo "✅ Icon copied"
else
    echo "Warning: icon-512.png not found, AppImage will not have an icon"
fi

# Create AppRun script
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash

# Get the directory where the AppImage is located
DIR="$(dirname "$(readlink -f "${0}")")"

# Set LD_LIBRARY_PATH to include the app's lib directory
export LD_LIBRARY_PATH="$DIR/usr/bin/lib:$LD_LIBRARY_PATH"

# Run the application
exec "$DIR/usr/bin/Seed" "$@"
EOF

chmod +x "$APPDIR/AppRun"

# Download appimagetool if not present
if [ ! -f "appimagetool-x86_64.AppImage" ]; then
    echo "Downloading appimagetool..."
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x appimagetool-x86_64.AppImage
fi

# Build the AppImage
echo "Building AppImage..."
./appimagetool-x86_64.AppImage "$APPDIR" "build/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"

echo "✅ AppImage created: build/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo ""
echo "To run: ./build/${APP_NAME}-${APP_VERSION}-x86_64.AppImage"
echo "To install: Copy the AppImage to your Applications folder or ~/bin"