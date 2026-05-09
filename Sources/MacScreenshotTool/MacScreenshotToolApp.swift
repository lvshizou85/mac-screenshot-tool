import SwiftUI
import AppKit

@main
struct MacScreenshotToolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Mac Screenshot Tool", systemImage: "camera.fill") {
            MenuBarContent()
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide Dock icon - make this a pure menu bar app
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Notification permission will be requested lazily on first screenshot
        // (UserNotifications requires proper app bundle and signing to work)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
