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
    var scrollSegments: Int {
        didSet { save() }
    }
    var scrollStepPercent: Int {
        didSet { save() }
    }
    var scrollDelay: Double {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private static let keys = Keys()

    private struct Keys {
        let saveDirectory = "saveDirectory"
        let imageFormat = "imageFormat"
        let copyToClipboard = "copyToClipboard"
        let showInFinder = "showInFinder"
        let scrollSegments = "scrollSegments"
        let scrollStepPercent = "scrollStepPercent"
        let scrollDelay = "scrollDelay"
    }

    init() {
        self.defaults = UserDefaults.standard
        self.saveDirectory = defaults.string(forKey: Self.keys.saveDirectory)
            ?? (ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()) + "/Desktop"
        self.imageFormat = defaults.string(forKey: Self.keys.imageFormat) ?? "png"
        self.copyToClipboard = defaults.bool(forKey: Self.keys.copyToClipboard)
        self.showInFinder = defaults.bool(forKey: Self.keys.showInFinder)

        let storedSegments = defaults.integer(forKey: Self.keys.scrollSegments)
        self.scrollSegments = storedSegments > 0 ? storedSegments : 6

        let storedStep = defaults.integer(forKey: Self.keys.scrollStepPercent)
        self.scrollStepPercent = storedStep > 0 ? storedStep : 80

        let storedDelay = defaults.double(forKey: Self.keys.scrollDelay)
        self.scrollDelay = storedDelay > 0 ? storedDelay : 0.35

        if defaults.object(forKey: Self.keys.saveDirectory) == nil {
            save()
        }
    }

    func save() {
        defaults.set(saveDirectory, forKey: Self.keys.saveDirectory)
        defaults.set(imageFormat, forKey: Self.keys.imageFormat)
        defaults.set(copyToClipboard, forKey: Self.keys.copyToClipboard)
        defaults.set(showInFinder, forKey: Self.keys.showInFinder)
        defaults.set(scrollSegments, forKey: Self.keys.scrollSegments)
        defaults.set(scrollStepPercent, forKey: Self.keys.scrollStepPercent)
        defaults.set(scrollDelay, forKey: Self.keys.scrollDelay)
    }
}
