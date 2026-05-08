import Foundation

enum ScreenshotError: Error, LocalizedError {
    case commandUnavailable
    case cancelled
    case failed(exitCode: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .commandUnavailable:
            return "screencapture command not found"
        case .cancelled:
            return "Screenshot was cancelled"
        case .failed(let code, let msg):
            return "Screenshot failed (exit code: \(code)): \(msg)"
        }
    }
}

@MainActor
@Observable
final class ScreenshotEngine {
    var isCapturing = false

    func capture(
        mode: CaptureMode,
        outputURL: URL,
        format: String = "png"
    ) async throws {
        isCapturing = true
        defer { isCapturing = false }

        try await Self.runCapture(mode: mode, outputURL: outputURL, format: format)
    }

    private nonisolated static func runCapture(
        mode: CaptureMode,
        outputURL: URL,
        format: String
    ) async throws {
        try await Task.detached(priority: .userInitiated) {
            try executeCapture(mode: mode, outputURL: outputURL, format: format)
        }.value
    }

    private nonisolated static func executeCapture(
        mode: CaptureMode,
        outputURL: URL,
        format: String
    ) throws {
        let screencapturePath = "/usr/sbin/screencapture"

        guard FileManager.default.fileExists(atPath: screencapturePath) else {
            throw ScreenshotError.commandUnavailable
        }

        let process = Process()
        process.executableURL = URL(filePath: screencapturePath)

        var args = ["-x"] // no sound

        switch mode {
        case .mainDisplay:
            args.append("-m") // main display only
        case .interactiveRegion:
            args.append("-i") // interactive mode
            args.append("-s") // selection mode only
        }

        // Format
        args.append("-t")
        args.append(format)

        // Output file
        args.append(outputURL.path)

        process.arguments = args

        let dir = outputURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let pipe = Pipe()
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let errorData = try pipe.fileHandleForReading.readToEnd() ?? Data()
        let errorStr = String(data: errorData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            if mode == .interactiveRegion && isMissingOrEmptyFile(outputURL) {
                removeIfEmpty(outputURL)
                throw ScreenshotError.cancelled
            }
            throw ScreenshotError.failed(exitCode: process.terminationStatus, stderr: errorStr)
        }

        if isMissingOrEmptyFile(outputURL) {
            removeIfEmpty(outputURL)
            if mode == .interactiveRegion {
                throw ScreenshotError.cancelled
            }
            throw ScreenshotError.failed(
                exitCode: process.terminationStatus,
                stderr: errorStr.isEmpty ? "No screenshot file was created." : errorStr
            )
        }
    }

    private nonisolated static func isMissingOrEmptyFile(_ url: URL) -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return true
        }
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = attr?[.size] as? NSNumber
        return size?.int64Value == 0
    }

    private nonisolated static func removeIfEmpty(_ url: URL) {
        let attr = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = attr?[.size] as? NSNumber
        if size?.int64Value == 0 {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
