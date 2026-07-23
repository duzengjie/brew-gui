// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BrewGUI",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BrewGUI", targets: ["BrewGUI"])
    ],
    targets: [
        .executableTarget(
            name: "BrewGUI",
            path: "Sources/BrewGUI",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "BrewGUITests",
            dependencies: ["BrewGUI"],
            path: "Tests/BrewGUITests"
        )
    ]
)
