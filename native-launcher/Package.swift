// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SkyGoFixedLauncher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SkyGoFixedLauncher", targets: ["SkyGoFixedLauncher"]),
        .executable(name: "SkyGoFixedInstaller", targets: ["SkyGoFixedInstaller"])
    ],
    targets: [
        .executableTarget(
            name: "SkyGoFixedLauncher",
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .executableTarget(
            name: "SkyGoFixedInstaller",
            linkerSettings: [.linkedFramework("AppKit")]
        )
    ]
)
