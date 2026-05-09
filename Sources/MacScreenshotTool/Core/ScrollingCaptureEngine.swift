import AppKit
import CoreGraphics

/// Errors specific to scrolling capture.
enum ScrollingCaptureError: Error, LocalizedError {
    case cancelled
    case noScreenFound
    case captureRegionFailed
    case stitchingFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .cancelled:
            return "Scrolling capture was cancelled"
        case .noScreenFound:
            return "Could not determine the screen for capture"
        case .captureRegionFailed:
            return "Failed to capture screen region"
        case .stitchingFailed:
            return "Failed to stitch captured images"
        case .saveFailed:
            return "Failed to save the scrolling screenshot"
        }
    }
}

/// Engine responsible for scrolling (long) screenshot capture.
/// Flow: user selects region → capture → scroll → repeat → stitch → save.
@MainActor
@Observable
final class ScrollingCaptureEngine {
    var isCapturing = false

    /// Settings for scrolling capture.
    struct Config: Sendable {
        var maxSegments: Int = 6
        var scrollStepFraction: Double = 0.80  // scroll by 80% of region height
        var scrollDelay: Double = 0.35  // seconds between scroll and next capture
    }

    /// Perform a scrolling capture workflow.
    /// Returns the URL of the saved stitched image.
    @discardableResult
    func captureScrolling(
        config: Config,
        outputURL: URL
    ) async throws -> URL {
        isCapturing = true
        defer { isCapturing = false }

        // 1. Let user select a region
        let selectedRect = try await RegionSelector.selectRegion()

        // 2. Perform capture-scroll loop
        let images = try await performCaptureLoop(
            region: selectedRect,
            config: config
        )

        guard !images.isEmpty else {
            throw ScrollingCaptureError.captureRegionFailed
        }

        // 3. Stitch images
        let stitched = try stitchImages(
            images,
            overlapFraction: 1.0 - config.scrollStepFraction
        )

        // 4. Save to file
        try saveImage(stitched, to: outputURL)

        return outputURL
    }

    // MARK: - Capture Loop

    private func performCaptureLoop(
        region: CGRect,
        config: Config
    ) async throws -> [CGImage] {
        var images: [CGImage] = []

        // Small delay to let the selection overlay disappear
        try await Task.sleep(for: .milliseconds(200))

        // First capture
        guard let firstImage = captureRegion(region) else {
            throw ScrollingCaptureError.captureRegionFailed
        }
        images.append(firstImage)

        let scrollAmount = Int(Double(Int(region.height)) * config.scrollStepFraction)

        for _ in 1..<config.maxSegments {
            // Simulate scroll
            simulateScroll(
                at: CGPoint(x: region.midX, y: region.midY),
                deltaY: -scrollAmount  // negative = scroll down
            )

            // Wait for scroll animation to complete
            try await Task.sleep(for: .milliseconds(Int(config.scrollDelay * 1000)))

            // Capture again
            guard let image = captureRegion(region) else {
                break
            }

            // Check if we've reached the bottom (compare with previous)
            if let lastImage = images.last, imagesAreIdentical(lastImage, image) {
                break
            }

            images.append(image)
        }

        return images
    }

    // MARK: - Screen Region Capture

    private func captureRegion(_ rect: CGRect) -> CGImage? {
        // CGWindowListCreateImage uses CG coordinate system (origin top-left)
        let image = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
        return image
    }

    // MARK: - Scroll Simulation

    private func simulateScroll(at point: CGPoint, deltaY: Int) {
        // Move the mouse to the center of the selected region first
        if let moveEvent = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        ) {
            moveEvent.post(tap: .cghidEventTap)
        }

        // Create scroll event with pixel-based scrolling
        if let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: Int32(deltaY),
            wheel2: 0,
            wheel3: 0
        ) {
            scrollEvent.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: Int64(deltaY))
            scrollEvent.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Duplicate Detection

    /// Simple check: compare a strip at the bottom of img1 with a strip at the top of img2.
    /// If they are pixel-identical, we've likely hit the bottom.
    private func imagesAreIdentical(_ img1: CGImage, _ img2: CGImage) -> Bool {
        guard img1.width == img2.width, img1.height == img2.height else {
            return false
        }

        // Compare a 20px strip from the bottom of img1 with the same region of img2
        let stripHeight = min(20, img1.height)
        let y = img1.height - stripHeight

        guard let strip1 = img1.cropping(to: CGRect(x: 0, y: y, width: img1.width, height: stripHeight)),
              let strip2 = img2.cropping(to: CGRect(x: 0, y: y, width: img2.width, height: stripHeight)) else {
            return false
        }

        guard let data1 = dataForImage(strip1),
              let data2 = dataForImage(strip2) else {
            return false
        }

        return data1 == data2
    }

    private func dataForImage(_ image: CGImage) -> Data? {
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4

        var pixelData = Data(count: bytesPerRow * height)
        pixelData.withUnsafeMutableBytes { ptr in
            guard let context = CGContext(
                data: ptr.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: bitmapInfo.rawValue
            ) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        return pixelData
    }

    // MARK: - Image Stitching

    /// Stitch captured images vertically, trimming overlap from subsequent frames.
    private func stitchImages(_ images: [CGImage], overlapFraction: Double) throws -> CGImage {
        guard let first = images.first else {
            throw ScrollingCaptureError.stitchingFailed
        }

        if images.count == 1 {
            return first
        }

        let imageWidth = first.width
        let imageHeight = first.height
        let overlapPixels = Int(Double(imageHeight) * overlapFraction)

        // Calculate total height:
        // First image: full height
        // Subsequent images: height - overlap
        let newContentHeight = imageHeight - overlapPixels
        let totalHeight = imageHeight + newContentHeight * (images.count - 1)

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(
            data: nil,
            width: imageWidth,
            height: totalHeight,
            bitsPerComponent: 8,
            bytesPerRow: imageWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw ScrollingCaptureError.stitchingFailed
        }

        // Draw images from bottom to top (CG origin is bottom-left)
        // First image goes at the top of the final image
        var yOffset = totalHeight - imageHeight
        context.draw(first, in: CGRect(x: 0, y: yOffset, width: imageWidth, height: imageHeight))

        for i in 1..<images.count {
            let img = images[i]
            // Crop the overlap portion from the top of this image
            let cropRect = CGRect(x: 0, y: 0, width: img.width, height: img.height - overlapPixels)
            guard let cropped = img.cropping(to: cropRect) else {
                continue
            }
            yOffset -= cropped.height
            context.draw(cropped, in: CGRect(x: 0, y: yOffset, width: cropped.width, height: cropped.height))
        }

        guard let result = context.makeImage() else {
            throw ScrollingCaptureError.stitchingFailed
        }

        return result
    }

    // MARK: - Save

    private func saveImage(_ image: CGImage, to url: URL) throws {
        let dir = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            "public.png" as CFString,
            1,
            nil
        ) else {
            throw ScrollingCaptureError.saveFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ScrollingCaptureError.saveFailed
        }
    }
}
