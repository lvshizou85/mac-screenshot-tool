import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case mainDisplay = "Capture Full Screen"
    case interactiveRegion = "Capture Selected Area"

    var id: String { rawValue }
}
