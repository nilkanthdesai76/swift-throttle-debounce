// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ThrottleDebounce",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "ThrottleDebounce",
            targets: ["ThrottleDebounce"]
        )
    ],
    targets: [
        .target(
            name: "ThrottleDebounce",
            dependencies: []
        ),
        .testTarget(
            name: "ThrottleDebounceTests",
            dependencies: ["ThrottleDebounce"]
        )
    ]
)
