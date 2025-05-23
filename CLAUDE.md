# Calibre EPUB QuickLook Project Context

## Project Overview
Creating a macOS QuickLook extension for EPUB files that integrates with Calibre's existing `quicklook_service()` infrastructure.

## Key Technical Details

### Calibre Service
- **Function**: `calibre.srv.render_book.quicklook_service()`
- **Socket**: Unix domain socket at `/tmp/calibre-quicklook-socket` (configurable)
- **Protocol**: JSON over Unix socket
- **Request**: `{"path": "/path/to/book.epub", "output_dir": "/tmp/output"}`
- **Response**: `{"spine": ["index.html"], "metadata": {...}, "is_comic": false}`

### Current Status
- ✅ Research complete - Calibre has existing infrastructure
- ✅ Test client created - Socket communication verified
- ✅ Service processes EPUBs successfully
- 🚧 Swift QuickLook extension skeleton created
- ❌ Socket client implementation in Swift needed
- ❌ Xcode project setup needed

### Known Issues
1. Python test client gets BrokenPipeError - need to handle socket response properly
2. Service must be running for QuickLook to work
3. No caching mechanism currently implemented

### Next Steps
1. Implement Swift Unix socket client
2. Create proper Xcode QuickLook extension project
3. Test with various EPUB formats
4. Fork Calibre and prepare upstream PR

### Testing
```bash
# Terminal 1: Start service
./src/start_service.sh

# Terminal 2: Test client
./src/test_client.py
```

### Key Files
- `/src/quicklook-extension/CalibreQuickLook.swift` - Swift extension (needs implementation)
- `/src/test_client.py` - Python test client
- `/docs/quicklook-service-api.md` - Complete API documentation

### Memories
- to memorize