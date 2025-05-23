#!/usr/bin/env swift

import Foundation

// Test program to verify EPUB preview generation works

struct EPUBPreviewTest {
    static func main() {
        print("Testing EPUB preview generation...")
        
        let epubPath = "/Users/robmbp/Projects/software/calibre-epub-quicklook/test-data/test_book.epub" 
        let outputDir = "/tmp/epub-preview-test"
        
        // Create output directory
        try? FileManager.default.createDirectory(atPath: outputDir, 
                                               withIntermediateDirectories: true)
        
        // Create socket connection
        let socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            print("❌ Failed to create socket")
            return
        }
        defer { close(socketFD) }
        
        // Configure socket address
        var serverAddr = sockaddr_un()
        serverAddr.sun_family = sa_family_t(AF_UNIX)
        let socketPath = "/tmp/calibre-quicklook-socket"
        _ = socketPath.withCString { cstr in
            withUnsafeMutablePointer(to: &serverAddr.sun_path.0) { ptr in
                strcpy(ptr, cstr)
            }
        }
        
        // Connect to socket
        let connectResult = withUnsafePointer(to: &serverAddr) { addr in
            addr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
                connect(socketFD, sockAddr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        guard connectResult == 0 else {
            print("❌ Failed to connect: \(String(cString: strerror(errno)))")
            if errno == ECONNREFUSED {
                print("   Start the service with: ./src/start_service.sh")
            }
            return
        }
        
        print("✅ Connected to Calibre service")
        
        // Prepare and send request
        let request = ["path": epubPath, "output_dir": outputDir]
        guard let requestData = try? JSONSerialization.data(withJSONObject: request),
              let requestString = String(data: requestData, encoding: .utf8) else {
            print("❌ Failed to create request")
            return
        }
        
        print("📤 Sending: \(requestString)")
        
        let sent = requestString.withCString { cstr in
            send(socketFD, cstr, strlen(cstr), 0)
        }
        
        guard sent > 0 else {
            print("❌ Failed to send request")
            return
        }
        
        // Read response
        var responseData = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        
        while true {
            let bytesRead = recv(socketFD, &buffer, buffer.count, 0)
            if bytesRead <= 0 { break }
            responseData.append(buffer, count: bytesRead)
            
            // Try to parse JSON to see if complete
            if let _ = try? JSONSerialization.jsonObject(with: responseData) {
                break
            }
        }
        
        print("📥 Received \(responseData.count) bytes")
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            print("❌ Failed to parse response")
            if let str = String(data: responseData, encoding: .utf8) {
                print("Raw: \(str)")
            }
            return
        }
        
        // Check response
        if let ok = json["ok"] as? Bool, ok == false {
            print("❌ Service error: \(json["error"] ?? "unknown")")
            return
        }
        
        // Extract result
        guard let result = json["result"] as? [String: Any],
              let spine = result["spine"] as? [[String: Any]] else {
            print("❌ Invalid response format")
            return
        }
        
        print("✅ Preview generated successfully!")
        print("   Files in spine: \(spine.count)")
        
        // Check first file
        if let firstFile = spine.first,
           let path = firstFile["path"] as? String {
            print("   First HTML: \(path)")
            
            if FileManager.default.fileExists(atPath: path) {
                let attrs = try? FileManager.default.attributesOfItem(atPath: path)
                let size = attrs?[.size] as? Int ?? 0
                print("   File size: \(size) bytes")
                
                // Read first 500 chars
                if let content = try? String(contentsOfFile: path),
                   content.count > 0 {
                    let preview = String(content.prefix(200))
                    print("   Preview: \(preview)...")
                }
            }
        }
        
        print("\n✅ Test complete! The socket communication works.")
        print("   Next step: Build the actual QuickLook extension in Xcode")
    }
}

EPUBPreviewTest.main()