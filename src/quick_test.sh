#!/bin/bash
# Quick test of Calibre quicklook service

# Start service in background
echo "Starting Calibre quicklook service..."
calibre-debug -c "from calibre.srv.render_book import *; quicklook_service('/tmp/calibre-quicklook-socket')" &
SERVICE_PID=$!

# Give it time to start
sleep 2

# Test with netcat
echo "Testing service..."
EPUB_PATH="/Users/robmbp/Projects/software/calibre-epub-quicklook/test-data/test_book.epub"
OUTPUT_DIR=$(mktemp -d)

echo "{\"path\": \"$EPUB_PATH\", \"output_dir\": \"$OUTPUT_DIR\"}" | nc -U /tmp/calibre-quicklook-socket

echo "Output directory: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"

# Kill the service
kill $SERVICE_PID
rm -f /tmp/calibre-quicklook-socket