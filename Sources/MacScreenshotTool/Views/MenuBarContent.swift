import SwiftUI
import AppKit

struct MenuBarContent: View {
    @State private var settings = AppSettings()
    @State private var engine = ScreenshotEngine()
    @State private var showSettings = false

    var body: some View {
        Group {
            // Screenshot actions
            Button {
                Task { await capture(mode: .mainDisplay) }
            } label: {
                Label("Capture Full Screen", systemImage: "display")
            }
            .disabled(engine.isCapturing)

            Button {
                Task { await capture(mode: .interactiveRegion) }
            } label: {
                Label("Capture Selected Area", systemImage: "viewfinder")
            }
            .disabled(engine.isCapturing)

            Divider()

            // Settings
            Button("Settings...") {
                showSettings = true
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }

            Divider()

            // Quit
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }

    private func capture(mode: CaptureMode) async {
        let outputURL = FileService.shared.generateOutputURL(
            directory: settings.saveDirectory,
            format: settings.imageFormat
        )

        do {
            try await engine.capture(
                mode: mode,
                outputURL: outputURL,
                format: settings.imageFormat
            )

            // Success: copy to clipboard if enabled
            if settings.copyToClipboard {
                ClipboardService.shared.copyImageToClipboard(at: outputURL)
            }

            // Show in Finder if enabled
            if settings.showInFinder {
                NSWorkspace.shared.activateFileViewerSelecting([outputURL])
            }

            // Notification
            NotificationService.shared.notifyScreenshotSaved(
                fileName: outputURL.lastPathComponent
            )

        } catch ScreenshotError.cancelled {
            // User cancelled - silently ignore, no notification
            return
        } catch {
            NotificationService.shared.notifyScreenshotFailed(
                message: error.localizedDescription
            )
        }
    }
}
