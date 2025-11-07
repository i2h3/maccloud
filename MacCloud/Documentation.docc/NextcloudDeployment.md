# Nextcloud Deployment

How MacCloud deploys and configures Nextcloud server instances.

## Overview

MacCloud automates the deployment of Nextcloud server from official release archives. Each deployment is ephemeral, meaning it exists only for the duration of the server session and is completely removed when stopped.

## Deployment Process

The deployment process consists of several automated steps:

### 1. Archive Retrieval

MacCloud uses ``NextcloudServerRepository`` to fetch Nextcloud server archives:

- Downloads from the official Nextcloud download server
- Caches archives locally for reuse
- Supports multiple Nextcloud versions through ``NextcloudServerVersion``

### 2. Temporary Directory Creation

Each deployment gets a unique temporary directory:

```
/tmp/MacCloud-<UUID>/
├── www/
│   └── nextcloud/         # Extracted Nextcloud installation
├── data/                   # Nextcloud data directory
├── logs/                   # Apache and PHP-FPM logs
├── run/                    # PID files and Unix sockets
├── httpd.conf             # Generated Apache configuration
└── php-fpm.conf           # Generated PHP-FPM configuration
```

This isolation ensures:
- Multiple MacCloud instances can run simultaneously (on different ports)
- No interference with system-wide installations
- Complete cleanup when the server stops

### 3. Archive Extraction

The Nextcloud ZIP archive is extracted to the `www/` subdirectory using the `unzip` command-line tool.

### 4. Automatic Configuration

MacCloud automatically configures Nextcloud using the `occ` command-line tool with environment variables similar to the official Nextcloud Docker image:

```bash
php occ maintenance:install \
    --database sqlite \
    --database-name nextcloud \
    --data-dir /path/to/data \
    --admin-user admin \
    --admin-pass admin
```

This creates:
- An admin user with username `admin` and password `admin`
- A SQLite database (no separate database server required)
- Initial configuration in `config/config.php`

### 5. Server Startup

After configuration, MacCloud starts:
1. PHP-FPM with the generated configuration
2. Apache with the generated configuration pointing to the Nextcloud installation

## Accessing the Server

Once running, the Nextcloud server is accessible at:

```
http://localhost:<port>/
```

Where `<port>` is the port number specified in the ``ContentView``.

You can log in with:
- **Username**: `admin`
- **Password**: `admin`

## Ephemeral Nature

The deployment is designed to be temporary:

- **Isolated**: Each deployment uses a unique directory
- **Self-contained**: All files are in one location
- **Automatic cleanup**: The entire deployment directory is removed when the server stops

This makes MacCloud ideal for:
- Automated testing in CI pipelines
- Development and debugging
- Quick Nextcloud experiments without persistent state

## Configuration Files

### Apache Configuration

Generated dynamically with:
- User-specified port binding
- Document root pointing to extracted Nextcloud
- FastCGI proxy for PHP requests
- Rewrite rules for Nextcloud routing

### PHP-FPM Configuration

Generated dynamically with:
- Unix socket for Apache communication
- Current user as the process owner
- Minimal process pool for single-user deployment

## Example Usage

```swift
// In ContentView.swift
let serverManager = ServerManager()

// Start server
try await serverManager.start(
    nextcloudArchive: archiveURL,
    port: 8080
)

// Server is now running at http://localhost:8080

// Stop server (cleans up everything)
serverManager.stop()
```

## See Also

- <doc:ApacheIntegration>
- <doc:PHPIntegration>
- <doc:DeploymentArchitecture>
- ``ServerManager``
- ``NextcloudServerRepository``
