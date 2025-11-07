# PHP Integration

How MacCloud integrates PHP-FPM for running Nextcloud.

## Overview

MacCloud builds PHP 8.4 from source with FastCGI Process Manager (PHP-FPM) enabled. This provides a high-performance PHP execution environment for Nextcloud server.

## Building PHP

PHP is built as part of the MacCloud build process through a dedicated Xcode target. The build script performs the following steps:

1. **Download**: Fetches the PHP source from php.net
2. **Cache**: Stores the downloaded archive in `BuildCache/` to avoid repeated downloads
3. **Configure**: Enables extensions required for Nextcloud:
   - **mbstring** - Multi-byte string handling
   - **zip** - ZIP archive support for app installations
   - **bcmath** - Arbitrary precision mathematics
   - **intl** - Internationalization support
   - **gd** - Image processing for thumbnails
   - **pdo_sqlite** - SQLite database driver
   - **sqlite3** - SQLite 3 support
   - **curl** - HTTP client for external requests
   - **openssl** - SSL/TLS encryption
   - **zlib** - Compression support
   - **bz2** - Bzip2 compression

## Runtime Configuration

When starting a Nextcloud server, MacCloud generates a custom PHP-FPM configuration file with:

- Process management settings optimized for single-user deployment
- Unix socket communication with Apache for lower latency
- Logging to the ephemeral deployment directory
- User and group settings matching the current user

## Process Management

PHP-FPM runs in foreground mode (`-F`) allowing MacCloud to:
- Monitor the PHP-FPM process lifecycle
- Capture output for debugging
- Gracefully terminate the server when stopping

The PHP-FPM process is tracked in ``ServerManager`` and terminated when the user stops the server or the application exits.

## Example Configuration

```ini
[global]
pid = /path/to/deployment/run/php-fpm.pid
error_log = /path/to/deployment/logs/php-fpm-error.log

[www]
user = username
group = staff
listen = /path/to/deployment/run/php-fpm.sock
listen.owner = username
listen.group = staff
listen.mode = 0660
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

## Communication with Apache

PHP-FPM communicates with Apache HTTP Server through a Unix domain socket. This provides:
- **Performance**: Lower latency than TCP sockets
- **Security**: Socket file permissions restrict access
- **Simplicity**: No port conflicts to manage

Apache's `mod_proxy_fcgi` module forwards PHP requests to the socket:

```apache
<FilesMatch \.php$>
    SetHandler "proxy:unix:/path/to/php-fpm.sock|fcgi://localhost"
</FilesMatch>
```

## Nextcloud Installation

PHP is also used to install and configure Nextcloud through the `occ` command-line tool:

```bash
php occ maintenance:install \
    --database sqlite \
    --data-dir /path/to/data \
    --admin-user admin \
    --admin-pass admin
```

This automates the initial Nextcloud setup without requiring manual configuration through the web interface.

## See Also

- <doc:ApacheIntegration>
- <doc:NextcloudDeployment>
- ``ServerManager``
