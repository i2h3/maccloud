import Foundation
import os

///
/// Manages the lifecycle of the local Nextcloud server deployment.
///
/// This class handles creating ephemeral deployment directories, generating configuration files,
/// and starting/stopping Apache and PHP-FPM processes.
///
@MainActor
class ServerManager: ObservableObject {
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ServerManager")
    
    @Published var isRunning = false
    
    private var apacheProcess: Process?
    private var phpFpmProcess: Process?
    private var deploymentDirectory: URL?
    
    ///
    /// Start the Nextcloud server.
    ///
    /// - Parameters:
    ///   - nextcloudArchive: The path to the Nextcloud server archive.
    ///   - port: The port number on which to run the server.
    ///
    /// - Throws: An error if the server fails to start.
    ///
    func start(nextcloudArchive: URL, port: UInt) async throws {
        logger.info("Starting Nextcloud server on port \(port)")
        
        // Create temporary directory for this deployment
        let tempDir = try createDeploymentDirectory()
        self.deploymentDirectory = tempDir
        
        logger.info("Deployment directory: \(tempDir.path(percentEncoded: false))")
        
        // Extract Nextcloud archive
        try await extractNextcloud(archive: nextcloudArchive, to: tempDir)
        
        // Generate configurations
        let apacheConfig = try generateApacheConfig(port: port, deploymentDir: tempDir)
        let phpFpmConfig = try generatePhpFpmConfig(deploymentDir: tempDir)
        
        // Write configuration files
        try apacheConfig.write(to: tempDir.appending(component: "httpd.conf"), atomically: true, encoding: .utf8)
        try phpFpmConfig.write(to: tempDir.appending(component: "php-fpm.conf"), atomically: true, encoding: .utf8)
        
        // Auto-configure Nextcloud
        try await configureNextcloud(deploymentDir: tempDir)
        
        // Start PHP-FPM
        try startPhpFpm(deploymentDir: tempDir)
        
        // Start Apache
        try startApache(deploymentDir: tempDir)
        
        isRunning = true
        logger.info("Nextcloud server started successfully")
    }
    
    ///
    /// Stop the Nextcloud server.
    ///
    func stop() {
        logger.info("Stopping Nextcloud server")
        
        // Stop Apache
        if let process = apacheProcess, process.isRunning {
            process.terminate()
            apacheProcess = nil
        }
        
        // Stop PHP-FPM
        if let process = phpFpmProcess, process.isRunning {
            process.terminate()
            phpFpmProcess = nil
        }
        
        // Clean up deployment directory
        if let deploymentDir = deploymentDirectory {
            try? fileManager.removeItem(at: deploymentDir)
            deploymentDirectory = nil
        }
        
        isRunning = false
        logger.info("Nextcloud server stopped")
    }
    
    // MARK: - Private Methods
    
    private func createDeploymentDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appending(component: "MacCloud-\(UUID().uuidString)")
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create subdirectories
        try fileManager.createDirectory(at: tempDir.appending(component: "logs"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: tempDir.appending(component: "run"), withIntermediateDirectories: true)
        
        return tempDir
    }
    
    private func extractNextcloud(archive: URL, to destination: URL) async throws {
        logger.info("Extracting Nextcloud archive")
        
        let webRoot = destination.appending(component: "www")
        try fileManager.createDirectory(at: webRoot, withIntermediateDirectories: true)
        
        // Use unzip command to extract the archive
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", archive.path(percentEncoded: false), "-d", webRoot.path(percentEncoded: false)]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "ServerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract Nextcloud archive"])
        }
    }
    
    private func generateApacheConfig(port: UInt, deploymentDir: URL) throws -> String {
        let wwwRoot = deploymentDir.appending(component: "www/nextcloud")
        let logsDir = deploymentDir.appending(component: "logs")
        let runDir = deploymentDir.appending(component: "run")
        
        // Get the path to bundled Apache
        guard let apachePath = Bundle.main.path(forResource: "httpd", ofType: nil) else {
            throw NSError(domain: "ServerManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Apache binary not found in bundle"])
        }
        
        let apacheModulesDir = URL(fileURLWithPath: apachePath).deletingLastPathComponent().appending(component: "modules")
        
        return """
        ServerRoot "\(URL(fileURLWithPath: apachePath).deletingLastPathComponent().path(percentEncoded: false))"
        Listen \(port)
        
        LoadModule mpm_prefork_module \(apacheModulesDir.path(percentEncoded: false))/mod_mpm_prefork.so
        LoadModule authz_core_module \(apacheModulesDir.path(percentEncoded: false))/mod_authz_core.so
        LoadModule dir_module \(apacheModulesDir.path(percentEncoded: false))/mod_dir.so
        LoadModule env_module \(apacheModulesDir.path(percentEncoded: false))/mod_env.so
        LoadModule mime_module \(apacheModulesDir.path(percentEncoded: false))/mod_mime.so
        LoadModule rewrite_module \(apacheModulesDir.path(percentEncoded: false))/mod_rewrite.so
        LoadModule proxy_module \(apacheModulesDir.path(percentEncoded: false))/mod_proxy.so
        LoadModule proxy_fcgi_module \(apacheModulesDir.path(percentEncoded: false))/mod_proxy_fcgi.so
        
        ServerName localhost
        PidFile "\(runDir.path(percentEncoded: false))/httpd.pid"
        ErrorLog "\(logsDir.path(percentEncoded: false))/apache-error.log"
        CustomLog "\(logsDir.path(percentEncoded: false))/apache-access.log" common
        
        DocumentRoot "\(wwwRoot.path(percentEncoded: false))"
        
        <Directory "\(wwwRoot.path(percentEncoded: false))">
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
            
            <IfModule mod_rewrite.c>
                RewriteEngine On
                RewriteCond %{REQUEST_FILENAME} !-f
                RewriteCond %{REQUEST_FILENAME} !-d
                RewriteRule ^(.*)$ index.php [QSA,L]
            </IfModule>
        </Directory>
        
        <FilesMatch \\.php$>
            SetHandler "proxy:unix:\(runDir.path(percentEncoded: false))/php-fpm.sock|fcgi://localhost"
        </FilesMatch>
        
        <IfModule mime_module>
            TypesConfig /etc/apache2/mime.types
            AddType application/x-compress .Z
            AddType application/x-gzip .gz .tgz
            AddType text/html .shtml
            AddOutputFilter INCLUDES .shtml
        </IfModule>
        """
    }
    
    private func generatePhpFpmConfig(deploymentDir: URL) throws -> String {
        let logsDir = deploymentDir.appending(component: "logs")
        let runDir = deploymentDir.appending(component: "run")
        
        return """
        [global]
        pid = \(runDir.path(percentEncoded: false))/php-fpm.pid
        error_log = \(logsDir.path(percentEncoded: false))/php-fpm-error.log
        
        [www]
        user = \(NSUserName())
        group = staff
        listen = \(runDir.path(percentEncoded: false))/php-fpm.sock
        listen.owner = \(NSUserName())
        listen.group = staff
        listen.mode = 0660
        pm = dynamic
        pm.max_children = 5
        pm.start_servers = 2
        pm.min_spare_servers = 1
        pm.max_spare_servers = 3
        """
    }
    
    private func configureNextcloud(deploymentDir: URL) async throws {
        logger.info("Configuring Nextcloud")
        
        let nextcloudDir = deploymentDir.appending(component: "www/nextcloud")
        let dataDir = deploymentDir.appending(component: "data")
        
        // Create data directory
        try fileManager.createDirectory(at: dataDir, withIntermediateDirectories: true)
        
        // Get path to bundled PHP
        guard let phpPath = Bundle.main.path(forResource: "php", ofType: nil) else {
            throw NSError(domain: "ServerManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "PHP binary not found in bundle"])
        }
        
        // Run Nextcloud installation command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: phpPath)
        process.currentDirectoryURL = nextcloudDir
        process.arguments = [
            "occ",
            "maintenance:install",
            "--database", "sqlite",
            "--database-name", "nextcloud",
            "--data-dir", dataDir.path(percentEncoded: false),
            "--admin-user", "admin",
            "--admin-pass", "admin"
        ]
        
        // Set environment variables
        var environment = ProcessInfo.processInfo.environment
        environment["NEXTCLOUD_ADMIN_USER"] = "admin"
        environment["NEXTCLOUD_ADMIN_PASSWORD"] = "admin"
        process.environment = environment
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "ServerManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to configure Nextcloud"])
        }
    }
    
    private func startPhpFpm(deploymentDir: URL) throws {
        logger.info("Starting PHP-FPM")
        
        guard let phpFpmPath = Bundle.main.path(forResource: "php-fpm", ofType: nil) else {
            throw NSError(domain: "ServerManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "PHP-FPM binary not found in bundle"])
        }
        
        let configPath = deploymentDir.appending(component: "php-fpm.conf")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: phpFpmPath)
        process.arguments = ["-y", configPath.path(percentEncoded: false), "-F"]
        
        try process.run()
        phpFpmProcess = process
    }
    
    private func startApache(deploymentDir: URL) throws {
        logger.info("Starting Apache")
        
        guard let apachePath = Bundle.main.path(forResource: "httpd", ofType: nil) else {
            throw NSError(domain: "ServerManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "Apache binary not found in bundle"])
        }
        
        let configPath = deploymentDir.appending(component: "httpd.conf")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: apachePath)
        process.arguments = ["-f", configPath.path(percentEncoded: false), "-D", "FOREGROUND"]
        
        try process.run()
        apacheProcess = process
    }
}
