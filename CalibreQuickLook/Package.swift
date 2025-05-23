// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CalibreQuickLook",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CalibreQuickLook",
            type: .dynamic,
            targets: ["CalibreQuickLookExtension"]),
    ],
    targets: [
        .target(
            name: "CalibreQuickLookExtension",
            dependencies: [],
            path: "Sources",
            linkerSettings: [
                .linkedFramework("QuickLook"),
                .linkedFramework("WebKit"),
                .linkedFramework("Cocoa")
            ]
        ),
    ]
)
