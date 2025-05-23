# Calibre QuickLook Service API Documentation

## Overview
The `quicklook_service()` function provides a Unix socket-based service for generating HTML previews of ebooks. It's designed specifically for QuickLook integration on macOS.

## Starting the Service
```bash
calibre-debug -c "from calibre.srv.render_book import *; quicklook_service('/tmp/qs')"
```

## Communication Protocol

### Socket Type
- Unix domain socket
- Path specified as parameter to `quicklook_service()`

### Request Format
JSON object sent over socket:
```json
{
  "path": "/absolute/path/to/ebook.epub",
  "output_dir": "/absolute/path/to/output/directory"
}
```

### Response Format

#### Success Response
```json
{
  "ok": true,
  "result": {
    "spine": [
      {
        "path": "relative/path/to/html/file.html",
        "is_linear": true
      }
    ],
    "metadata": {
      "title": "Book Title",
      "authors": ["Author Name"],
      "series": "Series Name",
      "series_index": 1.0,
      "tags": ["tag1", "tag2"],
      "publisher": "Publisher Name",
      "pubdate": "2023-01-01T00:00:00+00:00",
      "comments": "Book description...",
      "language": "eng"
    },
    "is_comic": false,
    "raster_cover": "path/to/cover.jpg",  // optional
    "titlepage": "path/to/titlepage.html" // optional
  }
}
```

#### Error Response
```json
{
  "ok": false,
  "path": "/original/requested/path.epub",
  "error": "Error message string",
  "traceback": "Full Python traceback..."
}
```

## Usage Example
```bash
# Start the service
calibre-debug -c "from calibre.srv.render_book import *; quicklook_service('/tmp/qs')" &

# Send a request
echo '{"path": "/path/to/book.epub", "output_dir": "/tmp/preview"}' | socat - unix-connect:/tmp/qs

# Send multiple requests (newline-separated)
printf '{"path": "/book1.epub", "output_dir": "/tmp/p1"}\n{"path": "/book2.epub", "output_dir": "/tmp/p2"}' | socat - unix-connect:/tmp/qs

# Shutdown the service
echo '' | socat - unix-connect:/tmp/qs
```

## Key Features
1. **Multiple Requests**: Send multiple book requests separated by newlines
2. **Batch Processing**: Responses are also newline-separated
3. **HTML Extraction**: Extracts ebook content as HTML files
4. **Metadata Extraction**: Returns comprehensive book metadata
5. **Cover Support**: Provides path to raster cover image if available
6. **Comic Detection**: Identifies comic books vs regular books
7. **Clean Shutdown**: Send empty line to shutdown service

## Output Directory Structure
The service extracts the ebook into the specified output directory with:
- HTML files for each chapter/section
- Images and other assets
- Spine information indicating reading order
- Cover image (if available)

## Supported Formats
All formats supported by Calibre, including:
- EPUB
- MOBI
- AZW/AZW3
- PDF
- And many more

## Notes
- The service runs as a background process
- Socket path must be writable
- Output directory must exist and be writable
- Service handles one connection at a time
- Designed for integration with macOS QuickLook extensions