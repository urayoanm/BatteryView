// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BatteryView",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(name: "BatteryView", targets: ["BatteryView"])
    ],
    dependencies: [],
    targets: [
        .target(name: "BatteryView", dependencies: [], path: "Sources")
    ],
    swiftLanguageVersions: [.v5]
)
