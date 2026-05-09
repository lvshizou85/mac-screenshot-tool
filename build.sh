#!/bin/bash
# Build and wrap into .app bundle
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/.build/release"
APP_NAME="MacScreenshotTool"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"
ICON_FILE="$PROJECT_DIR/Resources/AppIcon.icns"
INSTALL=0

usage() {
    echo "Usage: ./build.sh [--install]"
    echo "  --install    Also copy the built app to ~/Applications"
}

for arg in "$@"; do
    case "$arg" in
        --install)
            INSTALL=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

echo "Building $APP_NAME..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating .app bundle..."
rm -rf "$APP_BUNDLE"

# Create bundle structure
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy app icon
if [ ! -f "$ICON_FILE" ]; then
    echo "Missing app icon: $ICON_FILE" >&2
    exit 1
fi
cp "$ICON_FILE" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MacScreenshotTool</string>
    <key>CFBundleDisplayName</key>
    <string>Mac Screenshot Tool</string>
    <key>CFBundleIdentifier</key>
    <string>com.lvshizou.mac-screenshot-tool</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>MacScreenshotTool</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>MIT</string>
</dict>
</plist>
PLIST

# Sign the app (ad-hoc)
codesign --force --deep --sign - "$APP_BUNDLE"

echo "Done! App bundle: $APP_BUNDLE"
if [ "$INSTALL" -eq 1 ]; then
    echo "Deploying to ~/Applications..."
    mkdir -p "$HOME/Applications"
    rm -rf "$HOME/Applications/$APP_NAME.app"
    cp -R "$APP_BUNDLE" "$HOME/Applications/$APP_NAME.app"
    codesign --force --deep --sign - "$HOME/Applications/$APP_NAME.app"
    echo "Deployed: $HOME/Applications/$APP_NAME.app"
    echo "Run with: open $HOME/Applications/$APP_NAME.app"
else
    echo "Run with: open $APP_BUNDLE"
    echo "Install with: ./build.sh --install"
fi
