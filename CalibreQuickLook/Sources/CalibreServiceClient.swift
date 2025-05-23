import Foundation
import os.log

/// Client for communicating with Calibre's quicklook service via Unix domain socket
class CalibreServiceClient {
    
    /// Default socket path for the Calibre quicklook service
    private let defaultSocketPath = "/tmp/calibre-quicklook-socket"
    
    /// Logger for debugging socket communication
    private let logger = Logger(subsystem: "com.calibre.quicklook", category: "ServiceClient")
    
    /// Request structure for the Calibre service
    struct ServiceRequest: Codable {
        let path: String
        let output_dir: String
    }
    
    /// Response structure from the Calibre service
    struct ServiceResponse: Codable {
        let spine: [String]
        let metadata: [String: Any]?
        let is_comic: Bool
        
        /// Custom decoding to handle dynamic metadata
        enum CodingKeys: String, CodingKey {
            case spine
            case metadata
            case is_comic
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            spine = try container.decode([String].self, forKey: .spine)
            is_comic = try container.decode(Bool.self, forKey: .is_comic)
            
            // Handle metadata as optional dictionary
            if let metadataDict = try? container.decode([String: String].self, forKey: .metadata) {
                metadata = metadataDict
            } else {
                metadata = nil
            }
        }
    }
    
    /// Process an EPUB file and get the preview HTML
    /// - Parameters:
    ///   - epubPath: Path to the EPUB file
    ///   - outputDirectory: Directory where preview files will be generated
    /// - Returns: ServiceResponse with preview information
    func processEPUB(at epubPath: String, outputDirectory: String) async throws -> ServiceResponse {
        logger.info("Processing EPUB at: \(epubPath)")
        
        // Create output directory if needed
        try FileManager.default.createDirectory(atPath: outputDirectory, 
                                               withIntermediateDirectories: true, 
                                               attributes: nil)
        
        // Create socket connection
        let socketHandle = try createSocketConnection()
        defer {
            close(socketHandle)
        }
        
        // Prepare request
        let request = ServiceRequest(path: epubPath, output_dir: outputDirectory)
        let requestData = try JSONEncoder().encode(request)
        
        logger.debug("Sending request: \(String(data: requestData, encoding: .utf8) ?? "")")
        
        // Send request
        try await sendData(requestData, to: socketHandle)
        
        // Read response
        let responseData = try await readResponse(from: socketHandle)
        
        logger.debug("Received response: \(String(data: responseData, encoding: .utf8) ?? "")")
        
        // Parse response
        let response = try JSONDecoder().decode(ServiceResponse.self, from: responseData)
        
        return response
    }
    
    /// Create a Unix domain socket connection
    private func createSocketConnection() throws -> Int32 {
        // Create socket
        let socketHandle = socket(AF_UNIX, SOCK_STREAM, 0)
        guard socketHandle >= 0 else {
            throw SocketError.creationFailed(errno: errno)
        }
        
        // Configure socket address
        var serverAddress = sockaddr_un()
        serverAddress.sun_family = sa_family_t(AF_UNIX)
        
        // Copy socket path
        let pathBytes = defaultSocketPath.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: serverAddress.sun_path) else {
            close(socketHandle)
            throw SocketError.pathTooLong
        }
        
        withUnsafeMutableBytes(of: &serverAddress.sun_path) { pathBuffer in
            pathBytes.withUnsafeBytes { bytes in
                pathBuffer.copyMemory(from: bytes)
            }
        }
        
        // Connect to socket
        let connectResult = withUnsafePointer(to: &serverAddress) { addressPointer in
            addressPointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                connect(socketHandle, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_un>.size))
            }
        }
        
        guard connectResult == 0 else {
            close(socketHandle)
            throw SocketError.connectionFailed(errno: errno)
        }
        
        logger.info("Connected to Calibre service socket")
        return socketHandle
    }
    
    /// Send data to the socket
    private func sendData(_ data: Data, to socket: Int32) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            data.withUnsafeBytes { bytes in
                let bytePtr = bytes.bindMemory(to: UInt8.self).baseAddress!
                let totalBytes = data.count
                var sentBytes = 0
                
                while sentBytes < totalBytes {
                    let result = send(socket, bytePtr + sentBytes, totalBytes - sentBytes, 0)
                    if result < 0 {
                        continuation.resume(throwing: SocketError.sendFailed(errno: errno))
                        return
                    }
                    sentBytes += result
                }
                
                continuation.resume()
            }
        }
    }
    
    /// Read response from the socket
    private func readResponse(from socket: Int32) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            var responseData = Data()
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            
            while true {
                let bytesRead = recv(socket, buffer, bufferSize, 0)
                
                if bytesRead < 0 {
                    continuation.resume(throwing: SocketError.receiveFailed(errno: errno))
                    return
                } else if bytesRead == 0 {
                    // Connection closed
                    break
                } else {
                    responseData.append(buffer, count: bytesRead)
                    
                    // Check if we have a complete JSON response
                    if let jsonString = String(data: responseData, encoding: .utf8),
                       jsonString.contains("}") && isValidJSON(responseData) {
                        break
                    }
                }
            }
            
            continuation.resume(returning: responseData)
        }
    }
    
    /// Check if data contains valid JSON
    private func isValidJSON(_ data: Data) -> Bool {
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return true
        } catch {
            return false
        }
    }
}

/// Errors that can occur during socket communication
enum SocketError: LocalizedError {
    case creationFailed(errno: Int32)
    case pathTooLong
    case connectionFailed(errno: Int32)
    case sendFailed(errno: Int32)
    case receiveFailed(errno: Int32)
    case serviceNotRunning
    
    var errorDescription: String? {
        switch self {
        case .creationFailed(let errno):
            return "Failed to create socket: \(String(cString: strerror(errno)))"
        case .pathTooLong:
            return "Socket path is too long"
        case .connectionFailed(let errno):
            if errno == ECONNREFUSED {
                return "Calibre service is not running. Please start it with: calibre-debug -c 'from calibre.srv.render_book import quicklook_service; quicklook_service()'"
            }
            return "Failed to connect to socket: \(String(cString: strerror(errno)))"
        case .sendFailed(let errno):
            return "Failed to send data: \(String(cString: strerror(errno)))"
        case .receiveFailed(let errno):
            return "Failed to receive data: \(String(cString: strerror(errno)))"
        case .serviceNotRunning:
            return "Calibre quicklook service is not running"
        }
    }
}