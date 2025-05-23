#!/usr/bin/env swift

import Foundation

// Simple synchronous test
let socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
print("Socket FD: \(socketFD)")

if socketFD < 0 {
    print("Failed to create socket")
    exit(1)
}

var serverAddr = sockaddr_un()
serverAddr.sun_family = sa_family_t(AF_UNIX)

// Set socket path
let socketPath = "/tmp/calibre-quicklook-socket"
withUnsafeMutableBytes(of: &serverAddr.sun_path) { ptr in
    ptr.storeBytes(of: 0, toByteOffset: 0, as: Int8.self)
    socketPath.withCString { cstr in
        _ = strcpy(ptr.baseAddress!.assumingMemoryBound(to: CChar.self), cstr)
    }
}

// Connect
let result = withUnsafePointer(to: &serverAddr) { addr in
    addr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
        connect(socketFD, sockAddr, socklen_t(MemoryLayout<sockaddr_un>.size))
    }
}

if result != 0 {
    print("Connect failed: \(String(cString: strerror(errno)))")
    close(socketFD)
    exit(1)
}

print("Connected!")

// Send request
let request = """
{"path": "/Users/robmbp/Projects/software/calibre-epub-quicklook/test-data/test_book.epub", "output_dir": "/tmp/swift-test"}
"""

let sent = request.withCString { cstr in
    send(socketFD, cstr, strlen(cstr), 0)
}

print("Sent \(sent) bytes")

// Read response
var buffer = [CChar](repeating: 0, count: 4096)
let received = recv(socketFD, &buffer, buffer.count - 1, 0)

if received > 0 {
    buffer[received] = 0
    let response = String(cString: buffer)
    print("Response: \(response)")
} else {
    print("No response received")
}

close(socketFD)