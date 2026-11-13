// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "OpenDotlet", platforms: [.macOS(.v14)],
    products: [.executable(name: "OpenDotlet", targets: ["OpenDotletApp"])],
    targets: [
        .target(name: "DotletCore"),
        .executableTarget(name: "OpenDotletApp", dependencies: ["DotletCore"]),
        .testTarget(name: "DotletCoreTests", dependencies: ["DotletCore"])
    ]
)
