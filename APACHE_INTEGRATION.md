# Apache HTTP Server Integration

This document describes how Apache HTTP Server 2.4 is integrated into the MacCloud macOS application.

## Overview

MacCloud includes Apache HTTP Server 2.4 bundled within the application, allowing it to serve web content without requiring external dependencies.

## Architecture

### Directory Structure

```
MacCloud.app/
└── Contents/
    └── Resources/
        ├── apache/
        │   ├── bin/
        │   │   └── httpd          # Apache binary
        │   ├── modules/           # Apache modules (.so files)
        │   │   ├── mod_mpm_event.so
        │   │   ├── mod_authz_core.so
        │   │   ├── mod_dir.so
        │   │   ├── mod_mime.so
        │   │   ├── mod_log_config.so
        │   │   └── mod_unixd.so
        │   └── conf/
        │       ├── httpd.conf     # Configuration template
        │       └── mime.types     # MIME type mappings
        └── webroot/
            └── index.html         # Static content
```

### Build Process

1. **Build Script Phase**: The Xcode project includes a "Run Script" build phase that executes `download_apache.sh`
2. **Apache Download**: The script downloads/copies Apache binaries and modules
3. **Resource Bundling**: Xcode automatically includes files in `MacCloud/Resources/` in the app bundle

### Runtime Behavior

1. **Configuration Generation**: At runtime, `ApacheManager` generates a custom `httpd.conf` with correct paths
2. **Process Management**: Apache runs as a subprocess using Swift's `Process` API
3. **Temporary Files**: Runtime files (PID, logs) are stored in `/tmp/maccloud-apache/`

## Components

### ApacheManager.swift

The `ApacheManager` class handles:
- Configuration file generation with proper paths
- Starting the Apache process with appropriate arguments
- Stopping the Apache process cleanly
- Managing server state

### download_apache.sh

Build-time script that:
- Checks for system Apache installation
- Copies necessary binaries and modules to the Resources directory
- Falls back to instructions if Apache is not available

### Configuration Files

- **httpd.conf**: Template with placeholders replaced at runtime
- **mime.types**: MIME type mappings for serving different file types
- **index.html**: Default "Hello, World!" page

## Security Considerations

### App Sandbox Entitlements

The app requires these entitlements to run Apache:
- `com.apple.security.network.server`: Allow incoming network connections
- `com.apple.security.network.client`: Allow outgoing network connections
- Temporary file access for logs and PID files

### Port Usage

- Default port: 8080
- Configurable via httpd.conf

## Development

### Building

1. Ensure Apache is installed: `brew install httpd` (on macOS)
2. Build the project in Xcode
3. The build script will copy Apache files to Resources

### Testing

1. Run the app
2. Click "Start" to launch Apache
3. Open http://localhost:8080 in a browser
4. Verify "Hello, World!" page loads
5. Click "Stop" to shut down Apache

### Troubleshooting

- Check Console.app for Apache logs
- Verify files exist in `MacCloud.app/Contents/Resources/apache/`
- Ensure entitlements are properly signed
- Check that port 8080 is not in use

## Future Enhancements

- Support for custom ports
- PHP-FPM integration for dynamic content
- SQLite database integration
- Nextcloud server integration
- Configuration UI for server settings
