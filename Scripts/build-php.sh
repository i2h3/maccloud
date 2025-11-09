#!/bin/bash

# Build script for PHP-FPM 8.4
# This script downloads, caches, and builds PHP for inclusion in the MacCloud app bundle
# Updated: set up macOS SDK libxml2 detection so configure finds libxml-2.0 without Homebrew

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CACHE_DIR="${PROJECT_ROOT}/Cache"
PHP_VERSION="8.4.3"
PHP_SOURCE="php-${PHP_VERSION}"
PHP_TARBALL="${PHP_SOURCE}.tar.gz"
PHP_URL="https://www.php.net/distributions/${PHP_TARBALL}"
PKG_CONFIG_VERSION="0.29.2"
PKG_CONFIG_SOURCE="pkg-config-${PKG_CONFIG_VERSION}"
PKG_CONFIG_TARBALL="${PKG_CONFIG_SOURCE}.tar.gz"
PKG_CONFIG_URL="https://pkgconfig.freedesktop.org/releases/${PKG_CONFIG_TARBALL}"

BUILD_DIR="${PROJECT_ROOT}/Build"
INSTALL_DIR="${BUILD_PRODUCTS_DIR:-${BUILD_DIR}/Products}/PHP"
PKG_CONFIG_INSTALL_DIR="${BUILD_DIR}/pkg-config-install"

echo "=================================================="
echo "Building PHP ${PHP_VERSION}"
echo "=================================================="

# Ensure BUILD_PRODUCTS_DIR has a value
if [ -z "${BUILD_PRODUCTS_DIR}" ]; then
    echo "Note: BUILD_PRODUCTS_DIR not set, using default: ${BUILD_DIR}/Products"
fi

# Create cache directory if it doesn't exist
mkdir -p "${CACHE_DIR}"
mkdir -p "${BUILD_DIR}"

# Download and cache PHP if not already cached
if [ ! -f "${CACHE_DIR}/${PHP_TARBALL}" ]; then
    echo "Downloading PHP ${PHP_VERSION} from ${PHP_URL}"
    curl -sS -L -o "${CACHE_DIR}/${PHP_TARBALL}" "${PHP_URL}"
else
    echo "Using cached PHP ${PHP_VERSION}"
fi

# Download and cache pkg-config if not already cached
if [ ! -f "${CACHE_DIR}/${PKG_CONFIG_TARBALL}" ]; then
    echo "Downloading pkg-config ${PKG_CONFIG_VERSION} from ${PKG_CONFIG_URL}"
    curl -sS -L -o "${CACHE_DIR}/${PKG_CONFIG_TARBALL}" "${PKG_CONFIG_URL}"
else
    echo "Using cached pkg-config ${PKG_CONFIG_VERSION}"
fi

# Build pkg-config first (required for PHP)
echo "Building pkg-config..."
cd "${BUILD_DIR}"
if [ -d "${PKG_CONFIG_SOURCE}" ]; then
    rm -rf "${PKG_CONFIG_SOURCE}"
fi
tar xzf "${CACHE_DIR}/${PKG_CONFIG_TARBALL}"
cd "${PKG_CONFIG_SOURCE}"

echo "Configuring pkg-config..."
# Use CFLAGS to allow warnings that would otherwise be errors in newer compilers
CFLAGS="-Wno-int-conversion -Wno-incompatible-pointer-types" ./configure --prefix="${PKG_CONFIG_INSTALL_DIR}" --with-internal-glib

echo "Building pkg-config (this may take a few minutes)..."
make -j$(sysctl -n hw.ncpu)

echo "Installing pkg-config to ${PKG_CONFIG_INSTALL_DIR}..."
make install

# Add pkg-config to PATH for PHP build
export PATH="${PKG_CONFIG_INSTALL_DIR}/bin:${PATH}"

# Get the SDK path (if available) and configure flags so PHP finds macOS SDK libxml2
SDK_PATH=$(xcrun --show-sdk-path 2>/dev/null || echo "")
if [ -n "${SDK_PATH}" ]; then
    echo "Using SDK path: ${SDK_PATH}"

    # Make compiler and linker use the SDK (helps find system headers/libs that aren't in /usr/include anymore)
    # Explicitly include the libxml2 headers inside the SDK
    export SDKROOT="${SDK_PATH}"
    export CPPFLAGS="-I${SDKROOT}/usr/include/libxml2 -isysroot ${SDKROOT} ${CPPFLAGS:-}"
    export CFLAGS="${CPPFLAGS}"
    export LDFLAGS="-L${SDKROOT}/usr/lib -isysroot ${SDKROOT} ${LDFLAGS:-}"

    # pkg-config inside the SDK might not provide libxml-2.0.pc. Include SDK pkgconfig path anyway.
    export PKG_CONFIG_PATH="${SDKROOT}/usr/lib/pkgconfig:/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

    # Set environment variables for all common SDK libraries that PHP extensions need
    # This avoids the need to rely on pkg-config for each library individually
    
    # libxml2 (required for XML support)
    export LIBXML_CFLAGS="-I${SDKROOT}/usr/include/libxml2 -isysroot ${SDKROOT}"
    export LIBXML_LIBS="-L${SDKROOT}/usr/lib -lxml2 -isysroot ${SDKROOT}"
    
    # OpenSSL (required for SSL/TLS support)
    export OPENSSL_CFLAGS="-I${SDKROOT}/usr/include -isysroot ${SDKROOT}"
    export OPENSSL_LIBS="-L${SDKROOT}/usr/lib -lssl -lcrypto -isysroot ${SDKROOT}"
    
    # SQLite3 (required for SQLite database support)
    export SQLITE_CFLAGS="-I${SDKROOT}/usr/include -isysroot ${SDKROOT}"
    export SQLITE_LIBS="-L${SDKROOT}/usr/lib -lsqlite3 -isysroot ${SDKROOT}"
    
    # zlib (required for compression support)
    export ZLIB_CFLAGS="-I${SDKROOT}/usr/include -isysroot ${SDKROOT}"
    export ZLIB_LIBS="-L${SDKROOT}/usr/lib -lz -isysroot ${SDKROOT}"
    
    # bz2 (required for bzip2 compression)
    export BZ2_CFLAGS="-I${SDKROOT}/usr/include -isysroot ${SDKROOT}"
    export BZ2_LIBS="-L${SDKROOT}/usr/lib -lbz2 -isysroot ${SDKROOT}"
    
    # curl (required for HTTP client support)
    export CURL_CFLAGS="-I${SDKROOT}/usr/include -isysroot ${SDKROOT}"
    export CURL_LIBS="-L${SDKROOT}/usr/lib -lcurl -isysroot ${SDKROOT}"
    
    # iconv (required for character encoding conversion)
    export ICONV_CFLAGS="-I${SDKROOT}/usr/include -isysroot ${SDKROOT}"
    export ICONV_LIBS="-L${SDKROOT}/usr/lib -liconv -isysroot ${SDKROOT}"

    echo "CPPFLAGS: ${CPPFLAGS}"
    echo "LDFLAGS: ${LDFLAGS}"
    echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
    echo "SDK library environment variables configured for: libxml2, openssl, sqlite3, zlib, bz2, curl, iconv"
else
    echo "Warning: Could not determine SDK path. Falling back to default paths."
    export PKG_CONFIG_PATH="/usr/lib/pkgconfig:/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
fi

# Extract PHP
echo "Extracting PHP..."
cd "${BUILD_DIR}"
if [ -d "${PHP_SOURCE}" ]; then
    rm -rf "${PHP_SOURCE}"
fi
tar xzf "${CACHE_DIR}/${PHP_TARBALL}"

# Configure and build PHP
echo "Configuring PHP..."
cd "${BUILD_DIR}/${PHP_SOURCE}"

# Add --with-libxml-dir pointing at the SDK /usr (this plus LIBXML_CFLAGS/LIBXML_LIBS above
# avoids needing a libxml-2.0 .pc file or xml2-config binary)
./configure \
    --prefix="${INSTALL_DIR}" \
    --enable-fpm \
    --with-fpm-user=$(whoami) \
    --with-fpm-group=staff \
    --enable-mbstring \
    --enable-zip \
    --enable-bcmath \
    --enable-pcntl \
    --enable-ftp \
    --enable-exif \
    --enable-calendar \
    --enable-intl \
    --enable-gd \
    --disable-short-tags \
    --with-curl \
    --with-pdo-mysql \
    --with-pdo-sqlite \
    --with-sqlite3 \
    --enable-pdo \
    --with-openssl \
    --with-zlib \
    --with-bz2="${SDKROOT:-/usr}" \
    --with-iconv \
    --with-libxml-dir="${SDKROOT:-/usr}"

echo "Building PHP (this may take several minutes)..."
make -j$(sysctl -n hw.ncpu)

echo "Installing PHP to ${INSTALL_DIR}..."
make install

echo "=================================================="
echo "PHP build complete!"
echo "Installation directory: ${INSTALL_DIR}"
echo "=================================================="
