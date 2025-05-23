#!/bin/bash
# Start Calibre quicklook service for testing

echo "Starting Calibre quicklook service..."
echo "Socket path: /tmp/calibre-quicklook-socket"
echo "Press Ctrl+C to stop"
echo ""

calibre-debug -c "from calibre.srv.render_book import *; quicklook_service('/tmp/calibre-quicklook-socket')"