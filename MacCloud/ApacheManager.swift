import Foundation

class ApacheManager: ObservableObject {
    @Published var isRunning = false
    
    private var apacheProcess: Process?
    private let httpdPath: String
    private let configPath: String
    private let pidFilePath: String
    private let errorLogPath: String
    private let accessLogPath: String
    
    init() {
        // Get paths to bundled Apache resources
        let bundle = Bundle.main
        let resourcesPath = bundle.resourcePath ?? ""
        let apachePath = (resourcesPath as NSString).appendingPathComponent("apache")
        
        self.httpdPath = (apachePath as NSString).appendingPathComponent("bin/httpd")
        
        // Use temporary directory for runtime files
        let tempDir = NSTemporaryDirectory()
        let apacheTempDir = (tempDir as NSString).appendingPathComponent("maccloud-apache")
        
        // Create temp directory if it doesn't exist
        try? FileManager.default.createDirectory(atPath: apacheTempDir, withIntermediateDirectories: true)
        
        self.pidFilePath = (apacheTempDir as NSString).appendingPathComponent("httpd.pid")
        self.errorLogPath = (apacheTempDir as NSString).appendingPathComponent("error.log")
        self.accessLogPath = (apacheTempDir as NSString).appendingPathComponent("access.log")
        
        // Generate config file with correct paths
        let configTemplatePath = (apachePath as NSString).appendingPathComponent("conf/httpd.conf")
        self.configPath = (apacheTempDir as NSString).appendingPathComponent("httpd.conf")
        
        do {
            let template = try String(contentsOfFile: configTemplatePath, encoding: .utf8)
            let documentRoot = (resourcesPath as NSString).appendingPathComponent("webroot")
            let modulesPath = (apachePath as NSString).appendingPathComponent("modules")
            let mimeTypesPath = (apachePath as NSString).appendingPathComponent("conf/mime.types")
            
            let config = template
                .replacingOccurrences(of: "__SERVER_ROOT__", with: apachePath)
                .replacingOccurrences(of: "__DOCUMENT_ROOT__", with: documentRoot)
                .replacingOccurrences(of: "__PID_FILE__", with: pidFilePath)
                .replacingOccurrences(of: "__ERROR_LOG__", with: errorLogPath)
                .replacingOccurrences(of: "__ACCESS_LOG__", with: accessLogPath)
                .replacingOccurrences(of: "__TYPES_CONFIG__", with: mimeTypesPath)
            
            try config.write(toFile: configPath, atomically: true, encoding: .utf8)
        } catch {
            print("Error creating config file: \(error)")
        }
    }
    
    func start() async throws {
        guard !isRunning else { return }
        
        // Check if httpd binary exists
        guard FileManager.default.fileExists(atPath: httpdPath) else {
            throw ApacheError.httpdNotFound
        }
        
        // Check if config file exists
        guard FileManager.default.fileExists(atPath: configPath) else {
            throw ApacheError.configNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: httpdPath)
        process.arguments = ["-f", configPath, "-DFOREGROUND"]
        
        // Redirect output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Log output
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("Apache stdout: \(output)")
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                print("Apache stderr: \(output)")
            }
        }
        
        do {
            try process.run()
            apacheProcess = process
            
            // Give it a moment to start
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if process is still running
            if process.isRunning {
                await MainActor.run {
                    isRunning = true
                }
            } else {
                throw ApacheError.startFailed
            }
        } catch {
            print("Failed to start Apache: \(error)")
            throw error
        }
    }
    
    func stop() {
        guard isRunning, let process = apacheProcess else { return }
        
        process.terminate()
        
        // Wait for process to terminate
        process.waitUntilExit()
        
        apacheProcess = nil
        isRunning = false
        
        // Clean up PID file
        try? FileManager.default.removeItem(atPath: pidFilePath)
    }
}

enum ApacheError: LocalizedError {
    case httpdNotFound
    case configNotFound
    case startFailed
    
    var errorDescription: String? {
        switch self {
        case .httpdNotFound:
            return "Apache httpd binary not found in app bundle"
        case .configNotFound:
            return "Apache configuration file not found"
        case .startFailed:
            return "Failed to start Apache server"
        }
    }
}
