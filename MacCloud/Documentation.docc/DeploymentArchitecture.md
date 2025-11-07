# Deployment Architecture

Understanding MacCloud's deployment architecture and design decisions.

## Overview

MacCloud implements a self-contained, ephemeral deployment architecture that packages Apache, PHP-FPM, and Nextcloud server into a single macOS application. This architecture enables rapid deployment of Nextcloud servers for testing without requiring system-level installations or administrator privileges.

## Architecture Components

### Application Bundle

MacCloud is distributed as a standard macOS `.app` bundle that contains:

- **Swift Application**: The macOS UI and orchestration logic
- **Apache Binary**: HTTP server compiled from source
- **PHP Binary**: PHP-FPM compiled from source
- **Build Products**: All necessary modules and dependencies

### Process Architecture

When running, MacCloud manages three processes:

```
MacCloud.app (Swift)
├── httpd (Apache)
└── php-fpm (PHP-FPM)
```

- **MacCloud.app**: Parent process that manages lifecycle
- **Apache**: HTTP server in foreground mode
- **PHP-FPM**: FastCGI process manager in foreground mode

### Communication Flow

```
User Browser
    ↓ HTTP (port 8080)
Apache HTTP Server
    ↓ FastCGI (Unix socket)
PHP-FPM
    ↓ File operations
Nextcloud Server
    ↓ SQL queries
SQLite Database
```

## Ephemeral Deployments

Each server instance creates a temporary deployment directory:

```
/tmp/MacCloud-<UUID>/
```

This design provides:

### Isolation
- Multiple instances can run simultaneously (different ports)
- No conflicts with existing installations
- Each deployment is completely independent

### Security
- Runs in the application sandbox
- Uses temporary directories only
- No system modifications required

### Cleanup
- Everything removed when server stops
- No persistent state between runs
- Fresh installation every time

## Build System Integration

### Xcode Targets

The project uses multiple Xcode targets:

1. **Apache Target**: Builds Apache from source
   - Downloads source from apache.org
   - Caches in `BuildCache/`
   - Compiles with necessary modules
   - Installs to build products

2. **PHP Target**: Builds PHP-FPM from source
   - Downloads source from php.net
   - Caches in `BuildCache/`
   - Compiles with Nextcloud extensions
   - Installs to build products

3. **MacCloud Target**: Main application
   - Depends on Apache and PHP targets
   - Bundles compiled binaries
   - Implements UI and orchestration

### Build Cache

Source archives are cached in `BuildCache/` to avoid repeated downloads:

```
BuildCache/
├── httpd-2.4.62.tar.gz
├── apr-1.7.5.tar.gz
├── apr-util-1.6.3.tar.gz
└── php-8.4.3.tar.gz
```

This significantly speeds up rebuilds and works offline after the initial build.

## Runtime Configuration

### Dynamic Configuration Generation

MacCloud generates configuration files at runtime based on user inputs:

- **Port**: User specifies the port number
- **Paths**: All paths reference the temporary deployment directory
- **User/Group**: Matches the current user for proper permissions

This flexibility allows:
- Multiple instances on different ports
- No hardcoded paths
- Adaptation to the current environment

### Configuration Templates

Configuration generation uses string templates with variable interpolation:

```swift
"""
Listen \(port)
DocumentRoot "\(wwwRoot.path())"
ErrorLog "\(logsDir.path())/apache-error.log"
"""
```

## Sandbox Compatibility

MacCloud is designed to work within the macOS application sandbox:

- **Temporary Directory**: Uses sandboxed temp directory
- **Network**: Outgoing connections for downloads
- **No System Access**: Doesn't modify system files
- **User Files**: Read-only access as needed

## Design Rationale

### Why Build from Source?

Building Apache and PHP from source provides:
- **Control**: Exact module configuration
- **Consistency**: Same behavior across macOS versions
- **Independence**: No reliance on system installations
- **Compatibility**: All required Nextcloud extensions

### Why Ephemeral Deployments?

Temporary deployments provide:
- **Cleanliness**: No leftover files
- **Reproducibility**: Same state every time
- **Testing Focus**: Ideal for CI/CD environments
- **Simplicity**: No complex state management

### Why SQLite?

SQLite as the database provides:
- **No Dependencies**: No separate database server
- **Simplicity**: Single file database
- **Performance**: Sufficient for testing
- **Portability**: Works everywhere

## See Also

- <doc:ApacheIntegration>
- <doc:PHPIntegration>
- <doc:NextcloudDeployment>
- <doc:ServerConfiguration>
