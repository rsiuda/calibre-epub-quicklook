# Creating the Calibre QuickLook App for macOS Sequoia

## Steps to Create in Xcode

1. **Create New Project**
   - Open Xcode
   - File → New → Project
   - Choose **macOS → App**
   - Product Name: **CalibreQuickLook**
   - Team: (your team)
   - Organization Identifier: **com.calibre**
   - Bundle Identifier will be: **com.calibre.CalibreQuickLook**
   - Language: **Swift**
   - User Interface: **SwiftUI**
   - ✅ Use Core Data: **No**
   - ✅ Include Tests: **No** (for now)

2. **Add Quick Look Preview Extension**
   - With project selected: File → New → Target
   - Search for "Quick Look" in the filter
   - Select **Quick Look Preview Extension**
   - Product Name: **EPUBPreview**
   - Language: **Swift**
   - Project: **CalibreQuickLook**
   - Embed in Application: **CalibreQuickLook**
   - Click **Finish**
   - When asked to activate scheme, click **Activate**

3. **Configure the Extension**
   - Select the **EPUBPreview** target
   - Go to Info tab
   - Expand **NSExtension → NSExtensionAttributes → QLSupportedContentTypes**
   - Add these UTIs:
     - `org.idpf.epub-container`
     - `org.idpf.epub-folder`
     - `public.epub`
     - `com.apple.ibooks.epub`

4. **Replace Extension Files**
   - In EPUBPreview group, delete the default PreviewViewController.swift
   - Copy our files:
     - Drag `src/CalibreQuickLook/PreviewViewController.swift` to EPUBPreview group
     - Drag `src/CalibreQuickLook/CalibreServiceClient.swift` to EPUBPreview group
   - Make sure "Copy items if needed" is checked
   - Target Membership: **EPUBPreview** (not the main app)

5. **Configure Build Settings**
   - Select EPUBPreview target → Build Settings
   - Search for "App Sandbox"
   - Set **Enable App Sandbox** to **NO** (for testing)
   - Later we'll add proper entitlements

6. **Build and Run**
   - Select **CalibreQuickLook** scheme
   - Build (Cmd+B)
   - Run (Cmd+R) - this will launch the container app
   - The extension is now available to QuickLook

## Testing
```bash
# The app will be in ~/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/
# QuickLook will automatically find the extension inside the app

# Reset QuickLook
qlmanage -r

# Test
qlmanage -p test-data/test_book.epub
```

## Files to Use
- `/src/CalibreQuickLook/PreviewViewController.swift`
- `/src/CalibreQuickLook/CalibreServiceClient.swift`