import Foundation

@MainActor
@Observable
final class AppSettings {
    var saveDirectory: String {
        didSet { save() }
    }
    var imageFormat: String {
        didSet { save() }
    }
    var copyToClipboard: Bool {
        didSet { save() }
    }
    var showInFinder: Bool {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private static let keys = Keys()

    private struct Keys {
        let saveDirectory = "saveDirectory"
        let imageFormat = "imageFormat"
        let copyToClipboard = "copyToClipboard"
        let showInFinder = "showInFinder"
    }

    init() {
        self.defaults = UserDefaults.standard
        self.saveDirectory = defaults.string(forKey: Self.keys.saveDirectory)
            ?? (ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()) + "/Desktop"
        self.imageFormat = defaults.string(forKey: Self.keys.imageFormat) ?? "png"
        self.copyToClipboard = defaults.bool(forKey: Self.keys.copyToClipboard)
        self.showInFinder = defaults.bool(forKey: Self.keys.showInFinder)

        if defaults.object(forKey: Self.keys.saveDirectory) == nil {
            save()
        }
    }

    func save() {
        defaults.set(saveDirectory, forKey: Self.keys.saveDirectory)
        defaults.set(imageFormat, forKey: Self.keys.imageFormat)
        defaults.set(copyToClipboard, forKey: Self.keys.copyToClipboard)
        defaults.set(showInFinder, forKey: Self.keys.showInFinder)
    }
}
