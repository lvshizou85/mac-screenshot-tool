# Mac Screenshot Tool

A lightweight macOS menu bar screenshot tool built with SwiftUI and Swift Package Manager.

## Features

- **Full Screen Capture**: One-click screenshot of your main display
- **Region Capture**: Interactive selection mode for capturing specific areas
- **Auto Save**: Automatic timestamped filenames, no overwrites
- **Clipboard**: Optional auto-copy to clipboard after capture
- **Finder Integration**: Optional auto-reveal in Finder after capture
- **Settings**: Configurable save directory, image format (PNG/JPG/PDF/TIFF)
- **No Dock Icon**: Pure menu bar application

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 6.0+ (bundled with Xcode or standalone toolchain)
- Screen Recording permission (granted on first use)

## Build

```bash
cd /Users/lvshizou/mac-screenshot-tool
swift build          # Debug build (for development)
```

## Build .app Bundle

```bash
./build.sh           # Release build + wraps into .app bundle
```

## Run

### Development (debug binary)
```bash
swift run MacScreenshotTool
```

### Using .app bundle (recommended)
```bash
open MacScreenshotTool.app
```

> Note: The `.app` bundle is recommended for local use because it provides a proper app identity, Info.plist, LSUIElement menu bar behavior, and ad-hoc signing.

## Usage

1. Click the camera icon in the menu bar
2. Choose **Capture Full Screen** or **Capture Selected Area**
3. Screenshot is saved to your configured directory (default: ~/Desktop)
4. Files are named: `Screenshot yyyy-MM-dd HH.mm.ss.png`

### Settings

Click **Settings...** in the menu to configure:
- **Save Directory**: Where screenshots are saved (default: ~/Desktop)
- **Image Format**: PNG, JPG, PDF, or TIFF
- **Copy to Clipboard**: Auto-copy screenshots to clipboard
- **Show in Finder**: Auto-reveal screenshot in Finder after capture

### Keyboard Shortcuts

- **Cmd+Q**: Quit the app

## Permissions

The app requires **Screen Recording** permission on macOS. The system will prompt you on first use:
1. System Settings → Privacy & Security → Screen Recording
2. Ensure "MacScreenshotTool" is enabled

## Project Structure

```
mac-screenshot-tool/
├── Package.swift
├── README.md
├── docs/
│   ├── research.md          # Technical research notes
│   └── plan.md              # Implementation plan
└── Sources/MacScreenshotTool/
    ├── MacScreenshotToolApp.swift    # App entry point
    ├── Core/
    │   └── ScreenshotEngine.swift    # screencapture process wrapper
    ├── Models/
    │   ├── AppSettings.swift         # UserDefaults-backed settings
    │   └── CaptureMode.swift         # Capture mode enum
    ├── Services/
    │   ├── FileService.swift         # File naming & conflict handling
    │   ├── ClipboardService.swift    # NSPasteboard integration
    │   └── NotificationService.swift # User notifications
    └── Views/
        ├── MenuBarContent.swift      # Menu bar dropdown UI
        └── SettingsView.swift        # Settings panel
```

## Technical Notes

- Uses `/usr/sbin/screencapture` as the screenshot backend
- Swift concurrency (async/await) runs the blocking `screencapture` process off the main actor
- `@Observable` macro for reactive settings model
- Settings are persisted to `UserDefaults` when values change
- `MenuBarExtra` with `.window` style for the menu bar interface
- `NSApplicationActivationPolicy.accessory` for Dock icon hiding

## License

MIT
