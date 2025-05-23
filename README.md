# Calibre EPUB QuickLook

A macOS QuickLook extension for EPUB files that leverages Calibre's powerful EPUB rendering engine.

## Status: 🚧 Implementation Ready for Xcode

- ✅ Calibre's `quicklook_service()` verified working
- ✅ Unix socket communication established  
- ✅ Swift implementation complete
- ⚠️ Requires manual Xcode project creation (macOS Sequoia uses app-based extensions)

## Creating the QuickLook Extension (macOS Sequoia)

### Prerequisites
- macOS Sequoia (15.0+)
- Xcode 16+
- Calibre installed: `brew install --cask calibre`

### Step 1: Create Xcode Project
1. Open Xcode → File → New → Project
2. Choose **macOS → App**
3. Configure:
   - Product Name: **CalibreQuickLook**
   - Organization Identifier: **com.calibre**
   - Language: **Swift**
   - User Interface: **SwiftUI**

### Step 2: Add Quick Look Extension
1. File → New → Target
2. Search and select **Quick Look Preview Extension**
3. Configure:
   - Product Name: **EPUBPreview**
   - Language: **Swift**
   - Embed in: **CalibreQuickLook**

### Step 3: Configure Extension
1. Select EPUBPreview target → Info tab
2. Under NSExtension → NSExtensionAttributes → QLSupportedContentTypes, add:
   - `org.idpf.epub-container`
   - `public.epub`
   - `com.apple.ibooks.epub`

### Step 4: Add Implementation
1. Delete the default PreviewViewController.swift in EPUBPreview
2. Add `src/QuickLookExtension/EPUBPreviewViewController.swift` to EPUBPreview target
3. Ensure Target Membership is set to EPUBPreview only

### Step 5: Disable Sandbox (for testing)
1. Select EPUBPreview target → Build Settings
2. Search "App Sandbox"
3. Set Enable App Sandbox = NO

### Step 6: Build and Test
```bash
# Start Calibre service
./src/start_service.sh

# Build in Xcode (Cmd+B)

# Test QuickLook
qlmanage -r
qlmanage -p test-data/test_book.epub
```

## How It Works

1. **QuickLook Extension** receives EPUB file path
2. **Socket Client** connects to Calibre service at `/tmp/calibre-quicklook-socket`
3. **Calibre Service** extracts and renders EPUB to HTML
4. **WebView** displays the HTML preview

## Project Structure

```
├── src/
│   ├── QuickLookExtension/         # Swift implementation (all-in-one file)
│   │   └── EPUBPreviewViewController.swift
│   ├── test_client.py              # Python test client
│   └── start_service.sh            # Calibre service launcher
├── test-data/
│   └── test_book.epub              # Sample EPUB for testing
└── docs/
    └── quicklook-service-api.md    # API documentation
```

## Troubleshooting

### Service Not Running
```bash
# Check if service is running
ps aux | grep calibre-debug | grep quicklook

# Start service
./src/start_service.sh
```

### QuickLook Not Working
1. Check Console.app for errors
2. Ensure no other EPUB QuickLook extensions are installed
3. Reset QuickLook: `qlmanage -r`

### Socket Connection Failed
- Service must be running before testing
- Check socket exists: `ls -la /tmp/calibre-quicklook-socket`

## Future Improvements

1. **Auto-start Service**: LaunchAgent to start service on demand
2. **Caching**: Store rendered previews to improve performance
3. **Sandbox Support**: Move socket to accessible location
4. **Distribution**: Package as standalone app or Calibre integration

## Contributing

This project is a proof of concept for adding QuickLook support to Calibre. Contributions welcome!