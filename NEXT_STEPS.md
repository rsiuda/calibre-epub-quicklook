# Next Steps - Creating the QuickLook Extension in Xcode

## What We Have Working
✅ Calibre service running and responding to requests
✅ Socket communication protocol verified 
✅ Swift socket client code written (CalibreServiceClient.swift)
✅ PreviewViewController implementation ready
✅ Test EPUB files available

## Manual Steps in Xcode

1. **Create New Project**
   - Open Xcode
   - File → New → Project
   - Choose: macOS → Quick Look Extension
   - Product Name: CalibreQuickLook
   - Language: Swift
   - Bundle Identifier: com.calibre.quicklook

2. **Replace Generated Files**
   - Delete the generated PreviewViewController.swift
   - Copy our files from `src/CalibreQuickLook/`:
     - PreviewViewController.swift
     - CalibreServiceClient.swift
   - Update Info.plist with our version

3. **Configure Build Settings**
   - Remove App Sandbox temporarily for testing
   - Add entitlements later if needed
   - Set deployment target to macOS 13.0

4. **Build and Test**
   ```bash
   # Make sure service is running
   ./src/start_service.sh
   
   # Build in Xcode (Cmd+B)
   
   # Install for testing
   cp -r ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug/*.qlgenerator ~/Library/QuickLook/
   
   # Reset QuickLook
   qlmanage -r
   
   # Test
   qlmanage -p test-data/test_book.epub
   ```

## Known Issues to Fix
1. Socket path may need adjustment for sandbox
2. Need to handle service not running gracefully
3. Add proper error UI in PreviewViewController

## Files Ready to Use
- `/src/CalibreQuickLook/PreviewViewController.swift` - Complete implementation
- `/src/CalibreQuickLook/CalibreServiceClient.swift` - Socket client
- `/src/CalibreQuickLook/Info.plist` - QuickLook configuration