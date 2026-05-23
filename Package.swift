// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "BatteryView",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(name: "BatteryView",    targets: ["BatteryView"]),
        .library(name: "BatteryViewSUI", targets: ["BatteryViewSUI"]),
    ],
    dependencies: [],
    targets: [
        // UIKit-based battery view (iOS 9+)
        .target(
            name: "BatteryView",
            dependencies: [],
            path: "Sources/BatteryView"
        ),
        // SwiftUI-based battery view (iOS 15+, macOS 12+, tvOS 15+, watchOS 8+)
        .target(
            name: "BatteryViewSUI",
            dependencies: [],
            path: "Sources/BatteryViewSUI"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
