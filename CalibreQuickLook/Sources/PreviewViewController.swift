import Cocoa
import Quartz
import WebKit
import os.log

/// QuickLook preview controller for EPUB files using Calibre's rendering service
class PreviewViewController: NSViewController, QLPreviewingController {
    
    /// WebView for displaying the rendered EPUB content
    @IBOutlet weak var webView: WKWebView!
    
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
        webView = WKWebView(frame: mainView.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.width, .height]
        mainView.addSubview(webView)
        
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
                if let firstHTML = response.spine.first {
                    let htmlURL = URL(fileURLWithPath: outputDirectory)
                        .appendingPathComponent(firstHTML)
                    
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
        
        if let socketError = error as? SocketError {
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