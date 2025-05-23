import Cocoa
import Quartz
import WebKit
import os.log

/// QuickLook preview controller for EPUB files using Calibre's rendering service
class PreviewViewController: NSViewController, QLPreviewingController {
    
    /// WebView for displaying the rendered EPUB content
    @IBOutlet var webView: WKWebView!
    
    /// Loading indicator while processing EPUB
    private var progressIndicator: NSProgressIndicator!
    
    /// Error label for displaying issues
    private var errorLabel: NSTextField!
    
    /// Client for communicating with Calibre service
    private let serviceClient = CalibreServiceClient()
    
    /// Logger for debugging
    private let logger = Logger(subsystem: "com.calibre.quicklook", category: "PreviewController")
    
    override func loadView() {
        // Create main view
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 400))
        mainView.wantsLayer = true
        
        // Create WebView
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: mainView.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.width, .height]
        mainView.addSubview(webView)
        self.webView = webView
        
        // Create progress indicator
        progressIndicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 32, height: 32))
        progressIndicator.style = .spinning
        progressIndicator.isIndeterminate = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        mainView.addSubview(progressIndicator)
        
        // Create error label
        errorLabel = NSTextField(frame: mainView.bounds)
        errorLabel.isEditable = false
        errorLabel.isBordered = false
        errorLabel.backgroundColor = .clear
        errorLabel.alignment = .center
        errorLabel.font = NSFont.systemFont(ofSize: 14)
        errorLabel.textColor = .secondaryLabelColor
        errorLabel.isHidden = true
        errorLabel.autoresizingMask = [.width, .height]
        mainView.addSubview(errorLabel)
        
        // Center progress indicator
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: mainView.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: mainView.centerYAnchor)
        ])
        
        self.view = mainView
    }
    
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        logger.info("Preparing preview for: \(url.path)")
        
        // Show loading indicator
        showLoading()
        
        // Create temporary output directory
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CalibreQuickLook")
            .appendingPathComponent(UUID().uuidString)
            .path
        
        // Process EPUB asynchronously
        Task {
            do {
                // Process EPUB with Calibre service
                let response = try await serviceClient.processEPUB(
                    at: url.path,
                    outputDirectory: outputDirectory
                )
                
                // Load the first HTML file from the spine
                if let firstSpineItem = response.spine.first {
                    let htmlURL = URL(fileURLWithPath: firstSpineItem.path)
                    
                    // Load HTML in WebView on main thread
                    await MainActor.run {
                        hideLoading()
                        webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: outputDirectory))
                        logger.info("Loaded preview HTML: \(htmlURL.path)")
                    }
                    
                    handler(nil)
                } else {
                    throw PreviewError.noContent
                }
                
            } catch {
                logger.error("Failed to process EPUB: \(error.localizedDescription)")
                
                // Show error on main thread
                await MainActor.run {
                    hideLoading()
                    showError(error)
                }
                
                handler(error)
            }
        }
    }
    
    /// Show loading indicator
    private func showLoading() {
        progressIndicator.startAnimation(nil)
        progressIndicator.isHidden = false
        webView.isHidden = true
        errorLabel.isHidden = true
    }
    
    /// Hide loading indicator
    private func hideLoading() {
        progressIndicator.stopAnimation(nil)
        progressIndicator.isHidden = true
        webView.isHidden = false
    }
    
    /// Show error message
    private func showError(_ error: Error) {
        webView.isHidden = true
        errorLabel.isHidden = false
        
        if let socketError = error as? CalibreServiceClient.SocketError {
            errorLabel.stringValue = socketError.localizedDescription
        } else if let previewError = error as? PreviewError {
            errorLabel.stringValue = previewError.localizedDescription
        } else {
            errorLabel.stringValue = "Failed to preview EPUB: \(error.localizedDescription)"
        }
    }
}

/// Preview-specific errors
enum PreviewError: LocalizedError {
    case noContent
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noContent:
            return "No readable content found in EPUB"
        case .invalidResponse:
            return "Invalid response from Calibre service"
        }
    }
}

// MARK: - CalibreServiceClient (included in same file for simplicity)

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
    struct ServiceResponse: Decodable {
        let ok: Bool?
        let result: ServiceResult?
        let error: String?
        let traceback: String?
    }
    
    /// Result structure containing the actual preview data
    struct ServiceResult: Decodable {
        let spine: [SpineItem]
        let metadata: [String: String]?
        let is_comic: Bool
    }
    
    /// Individual spine item structure
    struct SpineItem: Decodable {
        let path: String
        let is_linear: Bool
    }
    
    /// Process an EPUB file and get the preview HTML
    /// - Parameters:
    ///   - epubPath: Path to the EPUB file
    ///   - outputDirectory: Directory where preview files will be generated
    /// - Returns: ServiceResult with preview information
    func processEPUB(at epubPath: String, outputDirectory: String) async throws -> ServiceResult {
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
        
        // Check for errors
        if let ok = response.ok, !ok {
            let errorMessage = response.error ?? "Unknown error"
            throw SocketError.serviceError(errorMessage)
        }
        
        // Return result
        guard let result = response.result else {
            throw SocketError.invalidResponse
        }
        
        return result
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
    
    /// Errors that can occur during socket communication
    enum SocketError: LocalizedError {
        case creationFailed(errno: Int32)
        case pathTooLong
        case connectionFailed(errno: Int32)
        case sendFailed(errno: Int32)
        case receiveFailed(errno: Int32)
        case serviceNotRunning
        case serviceError(String)
        case invalidResponse
        
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
            case .serviceError(let message):
                return "Service error: \(message)"
            case .invalidResponse:
                return "Invalid response from service"
            }
        }
    }
}