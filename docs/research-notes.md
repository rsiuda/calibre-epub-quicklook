# Research Notes

## Calibre QuickLook Service

### Key Discovery
Kovid (Calibre founder) already built the backend infrastructure specifically for QuickLook integration:

> "I added a quicklook service to calibre for this exact purpose. It was a weekend project that I never got around to finishing because I dont use a Mac. The idea is to have calibre running in the background as a service and when quicklook wants to preview a book, it calls calibre via a socket to generate the preview."

### Technical Details

- **Location**: `quicklook_service()` function in `calibre.srv.render_book`
- **Communication**: Unix socket + JSON protocol
- **Output**: HTML/CSS for WKWebView rendering
- **Formats**: EPUB, MOBI, AZW, and all Calibre-supported formats

### Kovid's Vision
- Calibre service runs in background
- QuickLook calls Calibre via socket for previews
- WKWebView renders the HTML output
- "Weekend project" scope for Cocoa developer

### Implementation Strategy
1. Study existing `quicklook_service()` code
2. Create Swift QuickLook Extension
3. Implement socket communication
4. Use WKWebView for HTML rendering
5. Submit PR to Calibre

### References
- [Forum statement](https://www.mobileread.com/forums//printthread.php?t=367393)
- [Commit](https://github.com/kovidgoyal/calibre/commit/d90d54528c1ad721c5a1c7f8b80919840a3e5f06)