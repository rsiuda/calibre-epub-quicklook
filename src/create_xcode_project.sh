#!/bin/bash

# Create a proper Xcode project for the QuickLook extension

echo "Creating Xcode project for Calibre QuickLook..."

cd /Users/robmbp/Projects/software/calibre-epub-quicklook

# Create project directory structure
mkdir -p CalibreQuickLook
cd CalibreQuickLook

# Create a Package.swift for Swift Package Manager
cat > Package.swift << 'EOF'
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
EOF

# Create source directory
mkdir -p Sources

# Copy source files
cp ../src/CalibreQuickLook/PreviewViewController.swift Sources/
cp ../src/CalibreQuickLook/CalibreServiceClient.swift Sources/
cp ../src/CalibreQuickLook/Info.plist Sources/

# Generate Xcode project
echo "Generating Xcode project..."
swift package generate-xcodeproj

echo "Done! Open CalibreQuickLook.xcodeproj in Xcode"
echo ""
echo "Next steps in Xcode:"
echo "1. Select the CalibreQuickLook scheme"
echo "2. Change product type to 'Quick Look Plugin'"
echo "3. Update Info.plist settings"
echo "4. Build and test with: qlmanage -p test.epub"