#!/bin/bash

# Build script for Calibre QuickLook extension

set -e

echo "Building Calibre QuickLook extension..."

# Create build directory
mkdir -p build

# Compile Swift files into a QuickLook plugin
swiftc \
    -o build/CalibreQuickLook \
    -framework QuickLook \
    -framework WebKit \
    -framework Cocoa \
    -parse-as-library \
    -emit-library \
    -module-name CalibreQuickLook \
    src/CalibreQuickLook/PreviewViewController.swift \
    src/CalibreQuickLook/CalibreServiceClient.swift

echo "Build complete. Output in build/"

# Create a simple app bundle structure for testing
BUNDLE_PATH="build/CalibreQuickLook.qlgenerator"
mkdir -p "$BUNDLE_PATH/Contents/MacOS"
mkdir -p "$BUNDLE_PATH/Contents/Resources"

# Copy binary
cp build/CalibreQuickLook "$BUNDLE_PATH/Contents/MacOS/"

# Copy Info.plist
cp src/CalibreQuickLook/Info.plist "$BUNDLE_PATH/Contents/"

echo "QuickLook generator bundle created at: $BUNDLE_PATH"
echo ""
echo "To install for testing:"
echo "  cp -r $BUNDLE_PATH ~/Library/QuickLook/"
echo "  qlmanage -r"
echo ""
echo "To test:"
echo "  qlmanage -p test-data/test_book.epub"