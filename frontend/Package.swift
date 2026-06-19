// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "DengKiller",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "DengKillerCore", targets: ["DengKillerCore"])
    ],
    targets: [
        .target(
            name: "DengKillerCore",
            path: "DengKillerCore/Sources"
        ),
        .testTarget(
            name: "DengKillerTests",
            dependencies: ["DengKillerCore"],
            path: "DengKillerTests"
        )
    ]
)

