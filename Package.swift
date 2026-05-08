// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacScreenshotTool",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacScreenshotTool",
            targets: ["MacScreenshotTool"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "MacScreenshotTool",
            path: "Sources/MacScreenshotTool"
        ),
    ]
)
