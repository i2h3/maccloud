#!/bin/bash

# Build script for PHP-FPM 8.4
# This script downloads, caches, and builds PHP for inclusion in the MacCloud app bundle
# Uses Homebrew packages for dependencies (libxml2, openssl, sqlite3, bzip2, etc.)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CACHE_DIR="${PROJECT_ROOT}/Cache"
PHP_VERSION="8.4.3"
PHP_SOURCE="php-${PHP_VERSION}"
PHP_TARBALL="${PHP_SOURCE}.tar.gz"
PHP_URL="https://www.php.net/distributions/${PHP_TARBALL}"

BUILD_DIR="${PROJECT_ROOT}/Build"
INSTALL_DIR="${BUILD_PRODUCTS_DIR:-${BUILD_DIR}/Products}/PHP"

echo "=================================================="
echo "Building PHP ${PHP_VERSION}"
echo "=================================================="

# Ensure BUILD_PRODUCTS_DIR has a value
if [ -z "${BUILD_PRODUCTS_DIR}" ]; then
    echo "Note: BUILD_PRODUCTS_DIR not set, using default: ${BUILD_DIR}/Products"
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew is not installed. Please install Homebrew first:"
    echo "/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Install required Homebrew packages
echo "Installing Homebrew dependencies..."
brew install pkg-config libxml2 openssl@3 sqlite bzip2 icu4c oniguruma

# Get Homebrew prefix (handles both Intel and Apple Silicon)
BREW_PREFIX=$(brew --prefix)
echo "Homebrew prefix: ${BREW_PREFIX}"

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

# Configure environment to use Homebrew libraries
echo "Configuring build environment for Homebrew dependencies..."

# Set up PKG_CONFIG_PATH to find Homebrew packages
export PKG_CONFIG_PATH="${BREW_PREFIX}/opt/libxml2/lib/pkgconfig:${BREW_PREFIX}/opt/openssl@3/lib/pkgconfig:${BREW_PREFIX}/opt/sqlite/lib/pkgconfig:${BREW_PREFIX}/opt/icu4c/lib/pkgconfig:${BREW_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"

# Set up compiler and linker flags for Homebrew
export CPPFLAGS="-I${BREW_PREFIX}/opt/libxml2/include -I${BREW_PREFIX}/opt/openssl@3/include -I${BREW_PREFIX}/opt/sqlite/include -I${BREW_PREFIX}/opt/bzip2/include -I${BREW_PREFIX}/opt/icu4c/include -I${BREW_PREFIX}/include ${CPPFLAGS:-}"
export LDFLAGS="-L${BREW_PREFIX}/opt/libxml2/lib -L${BREW_PREFIX}/opt/openssl@3/lib -L${BREW_PREFIX}/opt/sqlite/lib -L${BREW_PREFIX}/opt/bzip2/lib -L${BREW_PREFIX}/opt/icu4c/lib -L${BREW_PREFIX}/lib ${LDFLAGS:-}"
export CFLAGS="${CPPFLAGS}"

# Add Homebrew bin to PATH
export PATH="${BREW_PREFIX}/bin:${PATH}"

echo "PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"
echo "CPPFLAGS: ${CPPFLAGS}"
echo "LDFLAGS: ${LDFLAGS}"
echo "Homebrew dependencies configured: libxml2, openssl@3, sqlite, bzip2, icu4c, oniguruma"

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

# Configure PHP with Homebrew libraries
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
    --with-openssl="${BREW_PREFIX}/opt/openssl@3" \
    --with-zlib \
    --with-bz2="${BREW_PREFIX}/opt/bzip2" \
    --with-iconv \
    --with-libxml="${BREW_PREFIX}/opt/libxml2"

echo "Building PHP (this may take several minutes)..."
make -j$(sysctl -n hw.ncpu)

echo "Installing PHP to ${INSTALL_DIR}..."
make install

echo "=================================================="
echo "PHP build complete!"
echo "Installation directory: ${INSTALL_DIR}"
echo "=================================================="
