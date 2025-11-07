# Server Configuration

Configuring and customizing MacCloud server deployments.

## Overview

MacCloud provides simple configuration options through its user interface while handling complex server configuration automatically behind the scenes.

## User Configuration

### Nextcloud Version

Select from available Nextcloud server versions:

```swift
availableNextcloudServerVersions = [
    NextcloudServerVersion("30.0.17"),
    NextcloudServerVersion("31.0.10"),
    NextcloudServerVersion("32.0.0"),
    NextcloudServerVersion("32.0.1")
]
```

The selected version is downloaded from the official Nextcloud download server and cached locally for reuse.

### Port Number

Specify the port on which the server should listen. Default is `8080`.

The port must be:
- Available (not already in use)
- Above 1024 (no root privileges required)

After starting, the server is accessible at `http://localhost:<port>/`

## Automatic Configuration

MacCloud automatically generates all necessary configuration files:

### Apache Configuration

Generated for each deployment with:

```apache
ServerRoot "<bundled-apache-path>"
Listen <user-port>

# Module loading
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
LoadModule rewrite_module modules/mod_rewrite.so
# ... more modules

# Server settings
ServerName localhost
PidFile "<deployment>/run/httpd.pid"
ErrorLog "<deployment>/logs/apache-error.log"
DocumentRoot "<deployment>/www/nextcloud"

# Directory configuration
<Directory "<deployment>/www/nextcloud">
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    
    # Nextcloud rewrite rules
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ index.php [QSA,L]
</Directory>

# PHP-FPM proxy
<FilesMatch \.php$>
    SetHandler "proxy:unix:<deployment>/run/php-fpm.sock|fcgi://localhost"
</FilesMatch>
```

### PHP-FPM Configuration

Generated for each deployment with:

```ini
[global]
pid = <deployment>/run/php-fpm.pid
error_log = <deployment>/logs/php-fpm-error.log

[www]
user = <current-user>
group = staff
listen = <deployment>/run/php-fpm.sock
listen.owner = <current-user>
listen.group = staff
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

### Nextcloud Configuration

Nextcloud is configured automatically using the `occ` command:

```bash
php occ maintenance:install \
    --database sqlite \
    --database-name nextcloud \
    --data-dir <deployment>/data \
    --admin-user admin \
    --admin-pass admin
```

This creates a `config/config.php` with:
- Database configuration (SQLite)
- Data directory path
- Instance ID and secret
- Initial admin account

## Default Credentials

All deployments use the same default credentials for simplicity in testing:

- **Username**: `admin`
- **Password**: `admin`

> **Security Warning**: These are insecure defaults suitable only for temporary testing environments. Do not use MacCloud deployments for production or with sensitive data. Always use MacCloud in isolated, non-production environments only.

## Logging

All logs are written to the deployment directory:

```
<deployment>/logs/
├── apache-error.log    # Apache errors and warnings
├── apache-access.log   # HTTP access logs
└── php-fpm-error.log  # PHP-FPM errors and warnings
```

These logs are useful for debugging but are removed when the server stops.

## Process Management

### Startup Sequence

1. Create deployment directory structure
2. Extract Nextcloud archive
3. Generate Apache configuration
4. Generate PHP-FPM configuration
5. Run Nextcloud installation (occ)
6. Start PHP-FPM process
7. Start Apache process

### Shutdown Sequence

1. Terminate Apache process
2. Terminate PHP-FPM process
3. Remove deployment directory

Both processes run in foreground mode, allowing MacCloud to monitor and control them directly.

## Customization

While MacCloud is designed for simplicity with sensible defaults, the ``ServerManager`` class can be extended for custom configurations:

```swift
class ServerManager {
    // Modify configuration generation
    private func generateApacheConfig(...) -> String {
        // Custom Apache settings
    }
    
    private func generatePhpFpmConfig(...) -> String {
        // Custom PHP-FPM settings
    }
}
```

## Environment Variables

MacCloud sets environment variables during Nextcloud installation:

```swift
environment["NEXTCLOUD_ADMIN_USER"] = "admin"
environment["NEXTCLOUD_ADMIN_PASSWORD"] = "admin"
```

This matches the environment variable approach used by the official Nextcloud Docker images.

## See Also

- <doc:DeploymentArchitecture>
- <doc:NextcloudDeployment>
- ``ServerManager``
- ``ContentView``
