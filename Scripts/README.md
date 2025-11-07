# Build Scripts

This directory contains build scripts for compiling Apache and PHP-FPM from source as part of the MacCloud build process.

## Overview

MacCloud builds Apache HTTP Server and PHP-FPM from source to ensure:
- Consistent behavior across macOS versions
- All required modules for Nextcloud are available
- No dependency on system-provided versions
- Complete control over configuration

## Scripts

### build-apache.sh

Builds Apache HTTP Server 2.4.65 with required dependencies.

**What it does:**
1. Downloads Apache, APR, APR-Util, and PCRE2 from their respective sources
2. Caches downloaded archives in `Cache/`
3. Builds PCRE2 (required dependency for Apache)
4. Extracts Apache sources to `Build/`
5. Configures Apache with necessary modules for Nextcloud
6. Compiles Apache
7. Installs to the build products directory

**Required modules:**
- mod_proxy - HTTP proxy support
- mod_proxy_fcgi - FastCGI protocol
- mod_rewrite - URL rewriting
- mod_mime - MIME type handling
- mod_dir - Directory indexing
- mod_env - Environment variables
- mod_authz_core - Authorization

### build-php.sh

Builds PHP 8.4.3 with PHP-FPM enabled.

**What it does:**
1. Downloads PHP from php.net and pkg-config from freedesktop.org
2. Caches downloaded archives in `Cache/`
3. Builds pkg-config (required dependency for PHP)
4. Extracts PHP source to `Build/`
5. Configures PHP with extensions required by Nextcloud
6. Compiles PHP
7. Installs to the build products directory

**Required extensions:**
- mbstring - Multi-byte string support
- zip - ZIP archive handling
- bcmath - Arbitrary precision math
- intl - Internationalization
- gd - Image processing
- pdo_sqlite, sqlite3 - SQLite database
- curl - HTTP client
- openssl - Encryption
- And more...

## Build Cache

Downloaded source archives are cached in `Cache/` at the project root:

```
Cache/
├── httpd-2.4.65.tar.bz2
├── apr-1.7.6.tar.bz2
├── apr-util-1.6.3.tar.bz2
├── pcre2-10.47.tar.bz2
├── php-8.4.3.tar.gz
└── pkg-config-0.29.2.tar.gz
```

This cache:
- Speeds up rebuilds significantly
- Enables offline builds after initial download
- Is excluded from version control (see `.gitignore`)

## Build Products

Compiled binaries and modules are installed to `Build/Products/`:

```
Build/Products/
├── Apache/
│   ├── bin/httpd
│   ├── modules/
│   └── ...
└── PHP/
    ├── sbin/php-fpm
    ├── bin/php
    └── ...
```

These products are then bundled into the MacCloud.app during the Xcode build.

## Xcode Integration

These scripts are intended to be run as build phases in Xcode targets:

1. **Apache Target**: Runs `build-apache.sh`
2. **PHP Target**: Runs `build-php.sh`
3. **MacCloud Target**: Depends on both, bundles the products

## Manual Execution

You can also run the scripts manually:

```bash
cd MacCloud
./Scripts/build-apache.sh
./Scripts/build-php.sh
```

## Build Time

**First build:** 10-20 minutes (downloads + compilation)
**Subsequent builds:** 5-10 minutes (uses cache)

Build time varies based on:
- CPU speed (uses all cores)
- Internet speed (for downloads)
- Whether cache exists

## Requirements

- macOS with Xcode Command Line Tools
- Internet connection (for initial download)
- ~500MB free disk space for sources
- ~200MB free disk space for build products

## Cleaning

To perform a clean build:

```bash
# Remove cache (forces re-download)
rm -rf Cache/

# Remove build artifacts
rm -rf Build/
```

## Troubleshooting

### Build fails with "command not found"

Ensure Xcode Command Line Tools are installed:
```bash
xcode-select --install
```

### Download fails

Check internet connection and try again. The script will resume using the cache.

### Compilation errors

Ensure you have sufficient disk space and the latest macOS SDK:
```bash
xcodebuild -version
```

## See Also

- [MacCloud Documentation](../MacCloud/Documentation.docc/MacCloud.md)
- [Apache Integration](../MacCloud/Documentation.docc/ApacheIntegration.md)
- [PHP Integration](../MacCloud/Documentation.docc/PHPIntegration.md)
