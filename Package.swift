// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "InputSmith",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "InputSmith", targets: ["InputSmithApp"])
    ],
    targets: [
        .executableTarget(
            name: "InputSmithApp",
            path: "Sources/G7ControlApp",
            linkerSettings: [
                .linkedFramework("IOKit")
            ]
        )
    ]
)
