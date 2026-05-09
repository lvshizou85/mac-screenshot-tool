import Foundation

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Show a system notification using osascript (works without UserNotifications framework).
    func notifyScreenshotSaved(fileName: String) {
        let script = "display notification \(appleScriptString(fileName)) with title \(appleScriptString("Screenshot Saved"))"
        runNotification(script)
    }

    /// Show a failure notification.
    func notifyScreenshotFailed(message: String) {
        let script = "display notification \(appleScriptString(message)) with title \(appleScriptString("Screenshot Failed"))"
        runNotification(script)
    }

    private func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")

        return "\"\(escaped)\""
    }

    private func runNotification(_ script: String) {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }
}
