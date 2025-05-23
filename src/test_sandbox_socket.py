#!/usr/bin/env python3
"""Test if we can access sockets from different locations."""

import os
import tempfile
import socket
import json

def test_socket_path(path):
    """Test if we can create/access a socket at given path."""
    print(f"\nTesting socket at: {path}")
    try:
        # Clean up if exists
        if os.path.exists(path):
            os.unlink(path)
        
        # Try to create socket
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.bind(path)
        sock.listen(1)
        print(f"✅ Can create socket at {path}")
        sock.close()
        os.unlink(path)
        return True
    except Exception as e:
        print(f"❌ Cannot use {path}: {e}")
        return False

# Test various locations
print("Testing socket locations for QuickLook sandbox compatibility:\n")

# Standard /tmp
test_socket_path("/tmp/test-quicklook-socket")

# User's temporary directory
user_tmp = tempfile.gettempdir()
test_socket_path(os.path.join(user_tmp, "test-quicklook-socket"))

# Application Support (might work with proper entitlements)
app_support = os.path.expanduser("~/Library/Application Support/CalibreQuickLook")
os.makedirs(app_support, exist_ok=True)
test_socket_path(os.path.join(app_support, "test-quicklook-socket"))

# Caches directory (often more permissive)
caches = os.path.expanduser("~/Library/Caches/CalibreQuickLook")
os.makedirs(caches, exist_ok=True)
test_socket_path(os.path.join(caches, "test-quicklook-socket"))

print("\nRecommendation: Use Caches or Application Support with proper entitlements")