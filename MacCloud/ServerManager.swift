import Combine
import Foundation
import os

///
/// Manages the lifecycle of the local Nextcloud server deployment.
///
/// This class handles creating ephemeral deployment directories, generating configuration files,
/// and starting/stopping Apache and PHP-FPM processes.
///
actor ServerManager: ObservableObject {
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ServerManager")

    private var apacheProcess: Process?
    private var phpFpmProcess: Process?

    private(set) var deploymentDirectory: URL?

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
        logger.info("Starting Nextcloud server on port \(port)...")

        // Create temporary directory for this deployment
        let tempDir = try createDeploymentDirectory()
        self.deploymentDirectory = tempDir
        
        logger.info("Created deployment directory: \(tempDir.path(percentEncoded: false))")

        // Extract Nextcloud archive
        try await extractNextcloud(archive: nextcloudArchive, to: tempDir)
        
        // Generate configurations
        let apacheConfig = try generateApacheConfig(port: port, deploymentDir: tempDir)
        let phpFpmConfig = try generatePhpFpmConfig(deploymentDir: tempDir)
        
        // Write configuration files
        try apacheConfig.write(to: tempDir.appending(component: "httpd.conf"), atomically: true, encoding: .utf8)
        try phpFpmConfig.write(to: tempDir.appending(component: "php-fpm.conf"), atomically: true, encoding: .utf8)
        
        // Auto-configure Nextcloud
        try await configureNextcloud(deploymentDirectory: tempDir)
        
        // Start PHP-FPM
        try startPHPFPM(deploymentDir: tempDir)
        
        // Start Apache
        try startApache(deploymentDir: tempDir)

        logger.info("Nextcloud server started successfully.")
    }
    
    ///
    /// Stop the Nextcloud server.
    ///
    func stop() {
        logger.info("Stopping Nextcloud server...")

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

        logger.info("Nextcloud server stopped.")
    }
    
    // MARK: - Private Methods
    
    private func createDeploymentDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
            .appending(component: UUID().uuidString)
        
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // Create subdirectories
        try fileManager.createDirectory(at: tempDir.appending(component: "logs"), withIntermediateDirectories: true)
        try fileManager.createDirectory(at: tempDir.appending(component: "run"), withIntermediateDirectories: true)
        
        return tempDir
    }
    
    private func extractNextcloud(archive: URL, to destination: URL) async throws {
        logger.info("Extracting Nextcloud archive at \(archive.path(percentEncoded: false)) to \(destination.path(percentEncoded: false))")

        let webRoot = destination.appending(component: "www")
        try fileManager.createDirectory(at: webRoot, withIntermediateDirectories: true)
        
        // Find unzip command
        let unzipPath = findUnzip()
        guard fileManager.fileExists(atPath: unzipPath) else {
            throw NSError(domain: "ServerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "unzip command not found. Please install Command Line Tools."])
        }
        
        // Use unzip command to extract the archive
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unzipPath)
        process.arguments = ["-q", archive.path(percentEncoded: false), "-d", webRoot.path(percentEncoded: false)]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "ServerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to extract Nextcloud archive"])
        }
    }
    
    private func findUnzip() -> String {
        // Try common locations for unzip
        let commonPaths = [
            "/usr/bin/unzip",
            "/bin/unzip",
            "/opt/homebrew/bin/unzip",
            "/usr/local/bin/unzip"
        ]
        
        for path in commonPaths {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try using which command as fallback
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["unzip"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
                    return path
                }
            }
        } catch {
            // Fall back to default if which fails
        }
        
        // Default fallback
        return "/usr/bin/unzip"
    }
    
    private func generateApacheConfig(port: UInt, deploymentDir: URL) throws -> String {
        let wwwRoot = deploymentDir.appending(component: "www/nextcloud")
        let logsDir = deploymentDir.appending(component: "logs")
        let runDir = deploymentDir.appending(component: "run")
        
        // Locate Homebrew Apache installation
        let apacheRoot = findHomebrewApacheRoot()
        let apacheModulesDir = "\(apacheRoot)/lib/httpd/modules"
        let mimeTypesPath = "\(apacheRoot)/etc/httpd/mime.types"
        
        return """
        ServerRoot "\(apacheRoot)"
        Listen \(port)
        
        LoadModule mpm_prefork_module \(apacheModulesDir)/mod_mpm_prefork.so
        LoadModule authz_core_module \(apacheModulesDir)/mod_authz_core.so
        LoadModule dir_module \(apacheModulesDir)/mod_dir.so
        LoadModule env_module \(apacheModulesDir)/mod_env.so
        LoadModule mime_module \(apacheModulesDir)/mod_mime.so
        LoadModule rewrite_module \(apacheModulesDir)/mod_rewrite.so
        LoadModule proxy_module \(apacheModulesDir)/mod_proxy.so
        LoadModule proxy_fcgi_module \(apacheModulesDir)/mod_proxy_fcgi.so
        LoadModule unixd_module \(apacheModulesDir)/mod_unixd.so
        
        ServerName localhost
        PidFile "\(runDir.path(percentEncoded: false))/httpd.pid"
        ErrorLog "\(logsDir.path(percentEncoded: false))/apache-error.log"
        
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
            TypesConfig "\(mimeTypesPath)"
            AddType application/x-compress .Z
            AddType application/x-gzip .gz .tgz
            AddType application/x-httpd-php .php
            AddType text/html .html .htm
        </IfModule>
        """
    }
    
    private func findHomebrewApacheRoot() -> String {
        // Try common Homebrew locations for Apache
        let homebrewPrefixes = [
            "/opt/homebrew",  // Apple Silicon
            "/usr/local"      // Intel
        ]
        
        for prefix in homebrewPrefixes {
            let cellarPath = "\(prefix)/Cellar/httpd"
            if fileManager.fileExists(atPath: cellarPath) {
                // Find the latest version directory
                if let versions = try? fileManager.contentsOfDirectory(atPath: cellarPath).sorted().last {
                    return "\(cellarPath)/\(versions)"
                }
            }
            
            // Also check opt symlink
            let optPath = "\(prefix)/opt/httpd"
            if fileManager.fileExists(atPath: optPath) {
                return optPath
            }
        }
        
        // Fallback to /usr/local if nothing found
        return "/usr/local"
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
    
    private func configureNextcloud(deploymentDirectory: URL) async throws {
        logger.info("Configuring Nextcloud...")

        let nextcloudDirectory = deploymentDirectory.appending(component: "www/nextcloud")
        let dataDirectory = deploymentDirectory.appending(component: "data")

        logger.debug("Nextcloud directory: \(nextcloudDirectory.path)")

        // Locate Homebrew PHP
        guard let phpPath = findHomebrewPHP() else {
            throw MacCloudError.missingPHP
        }

        // Run Nextcloud installation command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: phpPath)
        process.currentDirectoryURL = nextcloudDirectory

        process.arguments = [
            "occ",
            "maintenance:install",
            "--database", "sqlite",
            "--database-name", "nextcloud",
            "--admin-user", "admin",
            "--admin-pass", "admin"
        ]
        
        // Set environment variables
        var environment = ProcessInfo.processInfo.environment
        environment["NEXTCLOUD_ADMIN_USER"] = "admin"
        environment["NEXTCLOUD_ADMIN_PASSWORD"] = "admin"
        process.environment = environment

        logger.debug("About to run \(process.executableURL?.path ?? "nil") \(process.arguments?.joined(separator: " ") ?? "nil")")

        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            logger.error("PHP terminated with status \(process.terminationStatus): \(process)")

            throw MacCloudError.processExitStatus(executable: process.executableURL, arguments: process.arguments, status: process.terminationStatus)
        }
    }

    ///
    /// Check the usual paths for PHP installed via Homebrew and return the first hit.
    ///
    /// - Returns: `nil`, if none of the conventional PHP binary locations were found.
    ///
    private func findHomebrewPHP() -> String? {
        logger.debug("Looking for the PHP binary...")

        let homebrewPrefixes = [
            "/opt/homebrew/bin/php", // Apple Silicon
            "/usr/local/bin/php"     // Intel
        ]
        
        for phpPath in homebrewPrefixes {
            if fileManager.fileExists(atPath: phpPath) {
                logger.debug("Found PHP binary at \(phpPath)")
                return phpPath
            } else {
                logger.debug("PHP binary not found at \(phpPath)")
            }
        }
        
        // Fallback
        return nil
    }
    
    private func startPHPFPM(deploymentDir: URL) throws {
        logger.info("Starting PHP-FPM...")

        // Locate Homebrew PHP-FPM
        let phpFpmPath = findHomebrewPhpFpm()
        let configPath = deploymentDir.appending(component: "php-fpm.conf")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: phpFpmPath)
        process.arguments = ["-y", configPath.path(percentEncoded: false), "-F"]
        
        try process.run()
        phpFpmProcess = process
    }
    
    private func findHomebrewPhpFpm() -> String {
        // Try common Homebrew locations for PHP-FPM
        let homebrewPrefixes = [
            "/opt/homebrew/sbin/php-fpm",  // Apple Silicon
            "/usr/local/sbin/php-fpm"      // Intel
        ]
        
        for phpFpmPath in homebrewPrefixes {
            if fileManager.fileExists(atPath: phpFpmPath) {
                return phpFpmPath
            }
        }
        
        // Fallback
        return "/usr/sbin/php-fpm"
    }
    
    private func startApache(deploymentDir: URL) throws {
        logger.info("Starting Apache")
        
        // Locate Homebrew Apache (httpd)
        let apachePath = findHomebrewApache()
        let configPath = deploymentDir.appending(component: "httpd.conf")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: apachePath)
        process.arguments = ["-f", configPath.path(percentEncoded: false), "-D", "FOREGROUND"]
        
        try process.run()
        apacheProcess = process
    }
    
    private func findHomebrewApache() -> String {
        // Try common Homebrew locations for Apache (httpd)
        let homebrewPrefixes = [
            "/opt/homebrew/bin/httpd",  // Apple Silicon
            "/usr/local/bin/httpd"      // Intel
        ]
        
        for apachePath in homebrewPrefixes {
            if fileManager.fileExists(atPath: apachePath) {
                return apachePath
            }
        }
        
        // Fallback
        return "/usr/sbin/httpd"
    }
}
