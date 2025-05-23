#!/bin/bash

# Create a minimal test EPUB for QuickLook testing
mkdir -p sample/META-INF sample/OEBPS

# mimetype (must be first and uncompressed)
echo -n "application/epub+zip" > sample/mimetype

# META-INF/container.xml
cat > sample/META-INF/container.xml << 'EOF'
<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
EOF

# OEBPS/content.opf
cat > sample/OEBPS/content.opf << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="uid" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">test-epub-001</dc:identifier>
    <dc:title>Test EPUB for Calibre QuickLook</dc:title>
    <dc:creator>Test Author</dc:creator>
    <dc:language>en</dc:language>
    <meta property="dcterms:modified">2024-01-01T00:00:00Z</meta>
  </metadata>
  <manifest>
    <item id="toc" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="toc">
    <itemref idref="chapter1"/>
  </spine>
</package>
EOF

# OEBPS/chapter1.xhtml
cat > sample/OEBPS/chapter1.xhtml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Chapter 1</title>
</head>
<body>
  <h1>Chapter 1: Calibre QuickLook Test</h1>
  <p>This is a test EPUB file for the Calibre QuickLook integration project.</p>
  <p>It will be used to test the Swift QuickLook Extension communicating with Calibre's quicklook_service().</p>
</body>
</html>
EOF

# OEBPS/toc.ncx
cat > sample/OEBPS/toc.ncx << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-epub-001"/>
  </head>
  <docTitle>
    <text>Test EPUB for Calibre QuickLook</text>
  </docTitle>
  <navMap>
    <navPoint id="navpoint-1" playOrder="1">
      <navLabel>
        <text>Chapter 1</text>
      </navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>
EOF

# Create EPUB
cd sample
zip -0 -X ../test_book.epub mimetype
zip -r ../test_book.epub META-INF/ OEBPS/
cd ..

echo "Created test_book.epub for Calibre QuickLook testing"