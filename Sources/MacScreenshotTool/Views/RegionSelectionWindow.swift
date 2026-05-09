import AppKit
import CoreGraphics

/// Provides an interactive fullscreen overlay for the user to select a screen region.
@MainActor
final class RegionSelector {
    private static var activeController: RegionSelectorController?

    /// Present a fullscreen overlay and let the user draw a selection rectangle.
    /// Returns the selected CGRect in CG screen coordinates (origin at top-left).
    /// Throws `ScrollingCaptureError.cancelled` if the user presses ESC.
    static func selectRegion() async throws -> CGRect {
        return try await withCheckedThrowingContinuation { continuation in
            let selector = RegionSelectorController(continuation: continuation) {
                activeController = nil
            }
            activeController = selector
            selector.show()
        }
    }
}

// MARK: - RegionSelectorController

@MainActor
private final class RegionSelectorController {
    private var window: NSWindow?
    private var selectionView: RegionSelectionView?
    private let continuation: CheckedContinuation<CGRect, Error>
    private let onFinish: () -> Void
    private var didResume = false

    init(continuation: CheckedContinuation<CGRect, Error>, onFinish: @escaping () -> Void) {
        self.continuation = continuation
        self.onFinish = onFinish
    }

    func show() {
        guard let screen = NSScreen.main else {
            resume(throwing: ScrollingCaptureError.noScreenFound)
            return
        }

        let selectionView = RegionSelectionView(frame: screen.frame)
        selectionView.onSelection = { [weak self] rect in
            self?.handleSelection(rect, screen: screen)
        }
        selectionView.onCancel = { [weak self] in
            self?.handleCancel()
        }
        self.selectionView = selectionView

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.2)
        window.level = .screenSaver
        window.contentView = selectionView
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(selectionView)

        // Force to front
        NSApplication.shared.activate(ignoringOtherApps: true)

        self.window = window
    }

    private func handleSelection(_ nsRect: NSRect, screen: NSScreen) {
        // Convert from NSWindow coordinates (origin bottom-left) to CG coordinates (origin top-left)
        let screenHeight = screen.frame.height
        let cgRect = CGRect(
            x: nsRect.origin.x,
            y: screenHeight - nsRect.origin.y - nsRect.height,
            width: nsRect.width,
            height: nsRect.height
        )

        dismiss()
        resume(returning: cgRect)
    }

    private func handleCancel() {
        dismiss()
        resume(throwing: ScrollingCaptureError.cancelled)
    }

    private func dismiss() {
        window?.orderOut(nil)
        window = nil
        selectionView = nil
    }

    private func resume(returning value: CGRect) {
        guard !didResume else { return }
        didResume = true
        continuation.resume(returning: value)
        onFinish()
    }

    private func resume(throwing error: Error) {
        guard !didResume else { return }
        didResume = true
        continuation.resume(throwing: error)
        onFinish()
    }
}

// MARK: - RegionSelectionView

private final class RegionSelectionView: NSView {
    var onSelection: ((NSRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw instruction text
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.systemFont(ofSize: 16, weight: .medium),
        ]
        let text = "Drag to select scrolling capture area  •  ESC to cancel"
        let textSize = text.size(withAttributes: attrs)
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: bounds.height - textSize.height - 40,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attrs)

        // Draw selection rectangle
        if let rect = currentRect {
            NSColor.systemBlue.withAlphaComponent(0.2).setFill()
            NSBezierPath(rect: rect).fill()

            NSColor.systemBlue.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2
            path.stroke()
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)

        currentRect = NSRect(x: x, y: y, width: w, height: h)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width >= 20, rect.height >= 20 else {
            // Too small, ignore
            startPoint = nil
            currentRect = nil
            needsDisplay = true
            return
        }

        onSelection?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            onCancel?()
        }
    }
}
