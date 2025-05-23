#!/usr/bin/env python3
import socket
import json
import tempfile
import os

# Test client for Calibre quicklook service
def test_quicklook_service():
    sock_path = '/tmp/calibre-quicklook-socket'
    epub_path = '/Users/robmbp/Projects/software/calibre-epub-quicklook/test-data/test_book.epub'
    
    # Create temp output directory
    output_dir = tempfile.mkdtemp(prefix='calibre-quicklook-')
    print(f"Output directory: {output_dir}")
    
    # Connect to socket
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.connect(sock_path)
        
        # Send request
        request = {
            'path': epub_path,
            'output_dir': output_dir
        }
        sock.send((json.dumps(request) + '\n').encode('utf-8'))
        
        # Read response
        response = b''
        while True:
            data = sock.recv(4096)
            if not data:
                break
            response += data
            if b'\n' in response:
                break
        
        result = json.loads(response.decode('utf-8').strip())
        print(f"Response: {json.dumps(result, indent=2)}")
        
        # List generated files
        print(f"\nGenerated files:")
        for root, dirs, files in os.walk(output_dir):
            for file in files:
                print(f"  {os.path.join(root, file)}")
        
    finally:
        sock.close()

if __name__ == '__main__':
    test_quicklook_service()