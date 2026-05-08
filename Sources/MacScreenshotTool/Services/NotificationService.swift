import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private init() {}

    /// Request notification permission. Safe to call multiple times.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
            if granted {
                print("Notification permission granted")
            }
        }
    }

    /// Send a notification that a screenshot was saved.
    func notifyScreenshotSaved(fileName: String) {
        notify(title: "Screenshot Saved", body: fileName)
    }

    /// Send a notification that a screenshot failed.
    func notifyScreenshotFailed(message: String) {
        notify(title: "Screenshot Failed", body: message)
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to deliver notification: \(error.localizedDescription)")
            }
        }
    }
}
