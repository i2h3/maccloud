# Apache Integration

How MacCloud integrates Apache HTTP Server for serving Nextcloud.

## Overview

MacCloud builds Apache HTTP Server 2.4 from source and bundles it with the application. This ensures consistent behavior across different macOS versions and provides all necessary modules for running Nextcloud server.

## Building Apache

Apache is built as part of the MacCloud build process through a dedicated Xcode target. The build script performs the following steps:

1. **Download**: Fetches the Apache source from apache.org
2. **Cache**: Stores the downloaded archive in `BuildCache/` to avoid repeated downloads
3. **Dependencies**: Includes APR and APR-Util as required dependencies
4. **Configure**: Enables necessary modules for Nextcloud:
   - `mod_proxy` - For proxying requests to PHP-FPM
   - `mod_proxy_fcgi` - FastCGI protocol support
   - `mod_rewrite` - URL rewriting for Nextcloud routing
   - `mod_mime` - MIME type handling
   - `mod_dir` - Directory indexing
   - `mod_env` - Environment variables
   - `mod_authz_core` - Authorization framework

## Runtime Configuration

When starting a Nextcloud server, MacCloud generates a custom Apache configuration file with:

- Dynamic port binding based on user input
- Document root pointing to the extracted Nextcloud installation
- FastCGI proxy configuration for PHP-FPM communication via Unix socket
- Logging to the ephemeral deployment directory
- Rewrite rules for Nextcloud's routing requirements

## Process Management

Apache runs in foreground mode (`-D FOREGROUND`) allowing MacCloud to:
- Monitor the Apache process lifecycle
- Capture output for debugging
- Gracefully terminate the server when stopping

The Apache process is tracked in ``ServerManager`` and terminated when the user stops the server or the application exits.

## Example Configuration

```apache
ServerRoot "/path/to/apache"
Listen 8080

LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
LoadModule rewrite_module modules/mod_rewrite.so

DocumentRoot "/path/to/deployment/www/nextcloud"

<Directory "/path/to/deployment/www/nextcloud">
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

<FilesMatch \.php$>
    SetHandler "proxy:unix:/path/to/php-fpm.sock|fcgi://localhost"
</FilesMatch>
```

## See Also

- <doc:PHPIntegration>
- <doc:NextcloudDeployment>
- ``ServerManager``
