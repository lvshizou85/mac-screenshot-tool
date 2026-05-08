import AppKit

@MainActor
class ClipboardService {
    static let shared = ClipboardService()

    private init() {}

    /// Copy an image file to the system clipboard.
    func copyImageToClipboard(at url: URL) {
        guard let image = NSImage(contentsOf: url) else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    /// Copy file URL to clipboard so it can be pasted as a file reference.
    func copyFileURLToClipboard(at url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([url as NSURL])
    }
}
