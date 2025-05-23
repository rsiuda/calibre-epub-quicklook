# Calibre EPUB QuickLook Extension

A macOS QuickLook extension for EPUB files that integrates with Calibre's existing infrastructure.

## Overview

This project adds EPUB QuickLook support directly to Calibre by creating a Swift QuickLook Extension that communicates with Calibre's existing `quicklook_service()` backend.

## Why Calibre Integration?

1. **Proven Infrastructure**: Calibre already has `quicklook_service()` built specifically for this purpose
2. **Community Welcome**: Kovid (Calibre founder) explicitly welcomes community contribution  
3. **Better Solution**: Leverages Calibre's mature EPUB parsing and multi-format support
4. **Long-term Maintenance**: Benefits from Calibre's established development team

## Technical Architecture

- **Backend**: Calibre's existing `quicklook_service()` (Unix socket + JSON)
- **Frontend**: Swift QuickLook Extension using WKWebView
- **Integration**: Add QuickLook Extension target to Calibre's build system
- **Distribution**: Upstream contribution to Calibre repository

## Implementation Plan

1. **Research Phase**
   - [ ] Fork Calibre repository
   - [ ] Study `quicklook_service()` implementation in `calibre.srv.render_book`
   - [ ] Understand Calibre's build system and contribution guidelines

2. **Development Phase**
   - [ ] Create Swift QuickLook Extension
   - [ ] Implement Unix socket communication with Calibre backend
   - [ ] Add WKWebView-based HTML rendering
   - [ ] Integrate with Calibre's macOS build system

3. **Integration Phase**
   - [ ] Test with various EPUB formats
   - [ ] Submit PR to upstream Calibre repository
   - [ ] Work with Calibre team for integration

## Key References

- [Kovid's QuickLook statement](https://www.mobileread.com/forums//printthread.php?t=367393) - "I added a quicklook service to calibre for this exact purpose"
- [Calibre QuickLook service commit](https://github.com/kovidgoyal/calibre/commit/d90d54528c1ad721c5a1c7f8b80919840a3e5f06)
- [Calibre repository](https://github.com/kovidgoyal/calibre)

## Development Setup

*Coming soon - after initial research phase*

## Contributing

This project aims to contribute EPUB QuickLook support upstream to Calibre. All development will be done with the goal of submitting a PR to the main Calibre repository.