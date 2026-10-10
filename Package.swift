// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NovaPlayer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "NovaPlayer",
            targets: ["NovaPlayer"]
        ),
        .executable(
            name: "NovaPlayerTests",
            targets: ["NovaPlayerTests"]
        ),
        .library(
            name: "NovaPlayerKit",
            targets: ["NovaPlayerKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NovaPlayerKit",
            dependencies: [],
            path: "Sources/NovaPlayerKit"
        ),
        .executableTarget(
            name: "NovaPlayer",
            dependencies: ["NovaPlayerKit"],
            path: "Sources/NovaPlayer"
        ),
        .executableTarget(
            name: "NovaPlayerTests",
            dependencies: ["NovaPlayerKit"],
            path: "Tests/NovaPlayerTests"
        )
    ]
)
