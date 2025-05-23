#!/usr/bin/env swift

import Foundation

/// Simple test client to verify Swift socket communication with Calibre service
struct TestClient {
    
    /// Test the socket client with a sample EPUB
    static func main() async {
        print("Testing Swift socket client...")
        
        // Use the test EPUB we created
        let epubPath = "/Users/robmbp/Projects/software/calibre-epub-quicklook/test-data/test_book.epub"
        let outputDir = "/tmp/swift-test-output"
        
        // Create socket
        let socketFD = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketFD >= 0 else {
            print("❌ Failed to create socket: \(String(cString: strerror(errno)))")
            return
        }
        defer { close(socketFD) }
        
        // Configure address
        var serverAddr = sockaddr_un()
        serverAddr.sun_family = sa_family_t(AF_UNIX)
        let socketPath = "/tmp/calibre-quicklook-socket"
        withUnsafeMutableBytes(of: &serverAddr.sun_path) { pathBuffer in
            socketPath.utf8CString.withUnsafeBytes { bytes in
                pathBuffer.copyMemory(from: bytes)
            }
        }
        
        // Connect
        let connectResult = withUnsafePointer(to: &serverAddr) { addr in
            addr.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockAddr in
                connect(socketFD, sockAddr, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        guard connectResult == 0 else {
            if errno == ECONNREFUSED {
                print("❌ Connection refused - is the Calibre service running?")
                print("   Start it with: ./src/start_service.sh")
            } else {
                print("❌ Failed to connect: \(String(cString: strerror(errno)))")
            }
            return
        }
        
        print("✅ Connected to socket")
        
        // Prepare request
        let request: [String: String] = [
            "path": epubPath,
            "output_dir": outputDir
        ]
        
        do {
            // Send request
            let requestData = try JSONSerialization.data(withJSONObject: request)
            print("📤 Sending request: \(String(data: requestData, encoding: .utf8) ?? "")")
            
            let sentBytes = requestData.withUnsafeBytes { bytes in
                send(socketFD, bytes.bindMemory(to: UInt8.self).baseAddress!, requestData.count, 0)
            }
            
            guard sentBytes == requestData.count else {
                print("❌ Failed to send complete request")
                return
            }
            
            // Read response
            var responseData = Data()
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            while true {
                let bytesRead = recv(socketFD, buffer, bufferSize, 0)
                if bytesRead <= 0 { break }
                responseData.append(buffer, count: bytesRead)
                
                // Check if we have complete JSON
                if let _ = try? JSONSerialization.jsonObject(with: responseData) {
                    break
                }
            }
            
            print("📥 Received \(responseData.count) bytes")
            
            // Parse response
            if let json = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any] {
                print("✅ Response parsed successfully:")
                if let spine = json["spine"] as? [String] {
                    print("   Spine files: \(spine)")
                }
                if let isComic = json["is_comic"] as? Bool {
                    print("   Is comic: \(isComic)")
                }
                
                // Check generated files
                if let firstFile = (json["spine"] as? [String])?.first {
                    let htmlPath = "\(outputDir)/\(firstFile)"
                    if FileManager.default.fileExists(atPath: htmlPath) {
                        let attrs = try? FileManager.default.attributesOfItem(atPath: htmlPath)
                        let size = attrs?[.size] as? Int ?? 0
                        print("   Generated HTML: \(htmlPath) (\(size) bytes)")
                    }
                }
            } else {
                print("❌ Failed to parse response")
                if let str = String(data: responseData, encoding: .utf8) {
                    print("   Raw response: \(str)")
                }
            }
            
        } catch {
            print("❌ Error: \(error)")
        }
    }
}

// Run the test
await TestClient.main()