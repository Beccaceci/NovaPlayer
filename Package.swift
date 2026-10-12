// swift-tools-version: 6.0
import PackageDescription

var products: [Product] = [.library(name: "NovaPlayerCore", targets: ["NovaPlayerCore"])]
var targets: [Target] = [
    .target(name: "NovaPlayerCore"),
    .testTarget(name: "NovaPlayerCoreTests", dependencies: ["NovaPlayerCore"])
]
#if os(macOS)
products += [
    .executable(name: "NovaPlayer", targets: ["NovaPlayer"]),
    .library(name: "NovaPlayerKit", targets: ["NovaPlayerKit"])
]
targets += [
    .target(name: "NovaPlayerKit", dependencies: ["NovaPlayerCore"]),
    .executableTarget(name: "NovaPlayer", dependencies: ["NovaPlayerKit"]),
    .testTarget(name: "NovaPlayerTests", dependencies: ["NovaPlayerKit"],
                resources: [.copy("Fixtures")])
]
#endif
let package = Package(name: "NovaPlayer", platforms: [.macOS(.v14)],
                      products: products, targets: targets, swiftLanguageModes: [.v5])
