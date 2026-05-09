import Foundation

@MainActor
class FileService {
    static let shared = FileService()

    private let dateFormatter: DateFormatter
    private let fileManager: FileManager

    private init() {
        self.fileManager = FileManager.default
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
    }

    /// Generate a unique output URL for a screenshot.
    /// Handles conflicts by appending -1, -2, etc.
    func generateOutputURL(
        directory: String,
        format: String,
        prefix: String = "Screenshot"
    ) -> URL {
        let dirURL = URL(filePath: directory)

        // Ensure directory exists
        if !fileManager.fileExists(atPath: dirURL.path) {
            try? fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)
        }

        let baseName = prefix + " " + dateFormatter.string(from: Date())
        let ext = format.hasPrefix(".") ? String(format.dropFirst()) : format
        let baseURL = dirURL.appendingPathComponent("\(baseName).\(ext)")

        // If no conflict, return immediately
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }

        // Conflict: append incrementing suffix
        var counter = 1
        while true {
            let conflictURL = dirURL.appendingPathComponent("\(baseName)-\(counter).\(ext)")
            if !fileManager.fileExists(atPath: conflictURL.path) {
                return conflictURL
            }
            counter += 1
        }
    }
}
