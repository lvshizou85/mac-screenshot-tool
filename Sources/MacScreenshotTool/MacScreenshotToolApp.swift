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
        
        // Request notification permission on first launch (safe to call even without bundle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationService.shared.requestPermission()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
