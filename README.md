# Mac Screenshot Tool

A lightweight macOS menu bar screenshot tool built with SwiftUI and Swift Package Manager.

## Features

- **Full Screen Capture**: One-click screenshot of your main display
- **Region Capture**: Interactive selection mode for capturing specific areas
- **Scrolling Capture**: Capture long/scrolling content by auto-scrolling and stitching multiple frames
- **Auto Save**: Automatic timestamped filenames, no overwrites
- **Clipboard**: Optional auto-copy to clipboard after capture
- **Finder Integration**: Optional auto-reveal in Finder after capture
- **Settings**: Configurable save directory, image format (PNG/JPG/PDF/TIFF)
- **No Dock Icon**: Pure menu bar application

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 6.0+ (bundled with Xcode or standalone toolchain)
- Screen Recording permission (granted on first use)
- Accessibility permission (required for scrolling capture scroll simulation)

## Build

```bash
cd /Users/lvshizou/mac-screenshot-tool
swift build          # Debug build (for development)
```

## Build .app Bundle

```bash
./build.sh           # Release build + wraps into .app bundle
```

## Install Locally

```bash
./build.sh --install # Build and copy to ~/Applications
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
2. Choose **Capture Full Screen**, **Capture Selected Area**, or **Capture Scrolling Screenshot**
3. Screenshot is saved to your configured directory (default: ~/Desktop)
4. Files are named: `Screenshot yyyy-MM-dd HH.mm.ss.png` or `Scrolling Screenshot yyyy-MM-dd HH.mm.ss.png`

### Scrolling Capture

1. Click **Capture Scrolling Screenshot** in the menu
2. A semi-transparent overlay appears — drag to select the scrollable area
3. The app captures the region, scrolls down, and repeats (default: 6 segments)
4. All frames are stitched into a single long image and saved as PNG
5. Press **ESC** to cancel at any time during region selection

**Tips:**
- Place the target window in the foreground before starting
- The selected area should cover the scrollable content (not the entire window)
- Works best with text-based content (web pages, documents, code editors)

### Settings

Click **Settings...** in the menu to configure:
- **Save Directory**: Where screenshots are saved (default: ~/Desktop)
- **Image Format**: PNG, JPG, PDF, or TIFF
- **Copy to Clipboard**: Auto-copy screenshots to clipboard
- **Show in Finder**: Auto-reveal screenshot in Finder after capture
- **Max Segments**: Maximum number of scroll captures (default: 6)
- **Scroll Step**: Percentage of region height to scroll each step (default: 80%)
- **Scroll Delay**: Delay between scroll and capture in seconds (default: 0.35s)

### Keyboard Shortcuts

- **Cmd+Q**: Quit the app

## Permissions

The app requires the following permissions:

1. **Screen Recording** — needed for all screenshot types
   - System Settings → Privacy & Security → Screen Recording
   - Enable "MacScreenshotTool"

2. **Accessibility** — needed for scrolling capture (scroll simulation)
   - System Settings → Privacy & Security → Accessibility
   - Enable "MacScreenshotTool"

The system will prompt you on first use of each feature.

## Project Structure

```
mac-screenshot-tool/
├── Package.swift
├── README.md
├── Resources/
│   ├── AppIcon.icns
│   └── AppIcon.iconset/
├── docs/
│   ├── research.md          # Technical research notes
│   └── plan.md              # Implementation plan
└── Sources/MacScreenshotTool/
    ├── MacScreenshotToolApp.swift    # App entry point
    ├── Core/
    │   ├── ScreenshotEngine.swift    # screencapture process wrapper
    │   └── ScrollingCaptureEngine.swift # Scrolling capture engine
    ├── Models/
    │   ├── AppSettings.swift         # UserDefaults-backed settings
    │   └── CaptureMode.swift         # Capture mode enum
    ├── Services/
    │   ├── FileService.swift         # File naming & conflict handling
    │   ├── ClipboardService.swift    # NSPasteboard integration
    │   └── NotificationService.swift # System notifications
    └── Views/
        ├── MenuBarContent.swift      # Menu bar dropdown UI
        ├── RegionSelectionWindow.swift # Scrolling capture region selector
        └── SettingsView.swift        # Settings panel
```

## Technical Notes

- Uses `/usr/sbin/screencapture` as the screenshot backend for full screen and region capture
- Scrolling capture uses `CGWindowListCreateImage` for region capture and `CGEvent` for scroll simulation
- Image stitching via CoreGraphics with configurable overlap trimming
- Automatic bottom-detection stops scrolling when content no longer changes
- Swift concurrency (async/await) runs the blocking `screencapture` process off the main actor
- `@Observable` macro for reactive settings model
- Settings are persisted to `UserDefaults` when values change
- Notifications are delivered through `osascript` to avoid app-bundle-specific `UserNotifications` setup
- `MenuBarExtra` with `.window` style for the menu bar interface
- `NSApplicationActivationPolicy.accessory` for Dock icon hiding

## Known Limitations (Scrolling Capture)

- Only works on content directly beneath the selected screen region (not window-aware)
- Requires the target window to be in the foreground and not obscured
- Scroll simulation relies on Accessibility permission; may not work in all apps
- No intelligent content-aware overlap detection — uses fixed percentage-based trimming
- Maximum capture segments is capped (default 6) to prevent runaway scrolling
- Retina displays are supported but very large captures may use significant memory
- Scrolling speed/distance may need tuning for different apps (adjust Scroll Step and Delay in Settings)

## License

MIT
