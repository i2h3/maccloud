#!/bin/bash

set -e

# Locate self.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set up common environment.
source "${SCRIPT_DIR}/setup-environment.sh"

PHP_VERSION="8.4.3"
PHP_SOURCE="php-${PHP_VERSION}"
PHP_TARBALL="${PHP_SOURCE}.tar.gz"
PHP_URL="https://www.php.net/distributions/${PHP_TARBALL}"

INSTALL_DIR="${BUILT_PRODUCTS_DIR}/PHP"
export INSTALL_DIR
echo "Resolved INSTALL_DIR: ${INSTALL_DIR}"

DSTROOT="${INSTALL_DIR}"
export DSTROOT
echo "Resolved DSTROOT: ${DSTROOT}"

echo "=================================================="
echo "Building PHP ${PHP_VERSION}"
echo "=================================================="

DEPS=(
    pkg-config
    bzip2
    libxml2
    openssl@3
    sqlite
    zlib
    curl
    libzip
    libpng
    jpeg-turbo
    freetype
    webp
    icu4c
    libiconv
)

for f in "${DEPS[@]}"; do
    if ! "$BREW_BIN" list --versions "$f" >/dev/null 2>&1; then
        echo "Installing $f..."
        "$BREW_BIN" install "$f"
    else
        echo "$f already installed"
    fi
done

# Export PATH for brew (ensure preferred locations first)
export PATH="${BREW_PREFIX}/bin:${BREW_PREFIX}/sbin:${PATH}"

# Resolve formula prefixes
BZIP2_PREFIX="$($BREW_BIN --prefix bzip2)"
LIBXML2_PREFIX="$($BREW_BIN --prefix libxml2)"
OPENSSL_PREFIX="$($BREW_BIN --prefix openssl@3 2>/dev/null || true)"
SQLITE_PREFIX="$($BREW_BIN --prefix sqlite)"
ZLIB_PREFIX=""; ZLIB_PREFIX="$($BREW_BIN --prefix zlib 2>/dev/null || echo "")"
CURL_PREFIX="$($BREW_BIN --prefix curl)"
LIBZIP_PREFIX="$($BREW_BIN --prefix libzip)"
PNG_PREFIX="$($BREW_BIN --prefix libpng)"
JPEG_PREFIX="$($BREW_BIN --prefix jpeg-turbo)"
FREETYPE_PREFIX="$($BREW_BIN --prefix freetype)"
WEBP_PREFIX="$($BREW_BIN --prefix webp)"
ICU_PREFIX="$($BREW_BIN --prefix icu4c)"
ICONV_PREFIX="$($BREW_BIN --prefix libiconv 2>/dev/null || true)"

# Some fallbacks (openssl@3 might be unavailable on older setups)
if [ -z "${OPENSSL_PREFIX}" ] || [ ! -d "${OPENSSL_PREFIX}" ]; then
    OPENSSL_PREFIX="$($BREW_BIN --prefix openssl@1.1 2>/dev/null || true)"
fi

# 3) Compose flags to prefer Homebrew headers/libs
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH:-}"
for p in \
    "${LIBXML2_PREFIX}/lib/pkgconfig" \
    "${OPENSSL_PREFIX}/lib/pkgconfig" \
    "${SQLITE_PREFIX}/lib/pkgconfig" \
    "${BZIP2_PREFIX}/lib/pkgconfig" \
    "${ZLIB_PREFIX}/lib/pkgconfig" \
    "${CURL_PREFIX}/lib/pkgconfig" \
    "${LIBZIP_PREFIX}/lib/pkgconfig" \
    "${PNG_PREFIX}/lib/pkgconfig" \
    "${FREETYPE_PREFIX}/lib/pkgconfig" \
    "${JPEG_PREFIX}/lib/pkgconfig" \
    "${WEBP_PREFIX}/lib/pkgconfig" \
    "${ICU_PREFIX}/lib/pkgconfig" \
    "${ICONV_PREFIX}/lib/pkgconfig"; do
    if [ -d "$p" ]; then
        PKG_CONFIG_PATH="$p:${PKG_CONFIG_PATH}"
    fi
done

export PKG_CONFIG_PATH

CPP_INC=(
    "${BREW_PREFIX}/include"
    "${LIBXML2_PREFIX}/include/libxml2"
    "${OPENSSL_PREFIX}/include"
    "${SQLITE_PREFIX}/include"
    "${ZLIB_PREFIX}/include"
    "${BZIP2_PREFIX}/include"
    "${CURL_PREFIX}/include"
    "${LIBZIP_PREFIX}/include"
    "${PNG_PREFIX}/include"
    "${JPEG_PREFIX}/include"
    "${FREETYPE_PREFIX}/include"
    "${WEBP_PREFIX}/include"
    "${ICU_PREFIX}/include"
    "${ICONV_PREFIX}/include"
)

LD_LIB=(
    "${BREW_PREFIX}/lib"
    "${LIBXML2_PREFIX}/lib"
    "${OPENSSL_PREFIX}/lib"
    "${SQLITE_PREFIX}/lib"
    "${ZLIB_PREFIX}/lib"
    "${BZIP2_PREFIX}/lib"
    "${CURL_PREFIX}/lib"
    "${LIBZIP_PREFIX}/lib"
    "${PNG_PREFIX}/lib"
    "${JPEG_PREFIX}/lib"
    "${FREETYPE_PREFIX}/lib"
    "${WEBP_PREFIX}/lib"
    "${ICU_PREFIX}/lib"
    "${ICONV_PREFIX}/lib"
)


# Avoid onbound variables.
CPPFLAGS="${CPPFLAGS:-}"
LDFLAGS="${LDFLAGS:-}"

for inc in "${CPP_INC[@]}"; do
    [ -d "$inc" ] && CPPFLAGS="-I$inc ${CPPFLAGS}"
done

for lib in "${LD_LIB[@]}"; do
    [ -d "$lib" ] && LDFLAGS="-L$lib ${LDFLAGS}"
done

export CPPFLAGS
export LDFLAGS
export CFLAGS="${CFLAGS:-} ${CPPFLAGS}"

# Fallback: if Homebrew libiconv is not available, point to the macOS SDK
if [ -z "${ICONV_PREFIX}" ] || [ ! -d "${ICONV_PREFIX}" ]; then
    SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
    if [ -n "${SDKROOT}" ] && [ -d "${SDKROOT}/usr" ]; then
        ICONV_PREFIX="${SDKROOT}/usr"
        CPPFLAGS="-I${ICONV_PREFIX}/include ${CPPFLAGS}"
        LDFLAGS="-L${ICONV_PREFIX}/lib ${LDFLAGS}"
    fi
fi

echo "Final CPPFLAGS: ${CPPFLAGS}"
echo "Final LDFLAGS: ${LDFLAGS}"
echo "Final PKG_CONFIG_PATH: ${PKG_CONFIG_PATH}"

# Download PHP, if necessary.

if [ ! -f "${CACHE_DIR}/${PHP_TARBALL}" ]; then
    echo "Downloading PHP ${PHP_VERSION} from ${PHP_URL}"
    curl -sS -L -o "${CACHE_DIR}/${PHP_TARBALL}" "${PHP_URL}"
else
    echo "Using cached PHP ${PHP_VERSION}"
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

# Prefix variables per library
BZ2_PREFIX="${BZIP2_PREFIX}"
LIBXML_PREFIX="${LIBXML2_PREFIX}"
SSL_PREFIX="${OPENSSL_PREFIX}"
SQLITE_DIR="${SQLITE_PREFIX}"
ZLIB_DIR="${ZLIB_PREFIX}"
CURL_DIR="${CURL_PREFIX}"
ZIP_DIR="${LIBZIP_PREFIX}"
JPEG_DIR="${JPEG_PREFIX}"
PNG_DIR="${PNG_PREFIX}"
FREETYPE_DIR="${FREETYPE_PREFIX}"
WEBP_DIR="${WEBP_PREFIX}"
ICU_DIR="${ICU_PREFIX}"
ICONV_DIR="${ICONV_PREFIX}"

# Note: we explicitly point to Homebrew prefixes and avoid macOS SDK paths.
./configure \
    --prefix="${INSTALL_DIR}" \
    --enable-fpm \
    --with-fpm-user=$(whoami) \
    --with-fpm-group=staff \
    --enable-mbstring \
    --enable-zip \
    --with-zip="${ZIP_DIR}" \
    --enable-bcmath \
    --enable-pcntl \
    --enable-ftp \
    --enable-exif \
    --enable-calendar \
    --enable-intl \
    --with-icu-dir="${ICU_DIR}" \
    --enable-gd \
    --with-jpeg="${JPEG_DIR}" \
    --with-freetype="${FREETYPE_DIR}" \
    --with-webp="${WEBP_DIR}" \
    --disable-short-tags \
    --with-curl="${CURL_DIR}" \
    --with-pdo-sqlite="${SQLITE_DIR}" \
    --with-sqlite3="${SQLITE_DIR}" \
    --enable-pdo \
    --with-openssl="${SSL_PREFIX}" \
    --with-zlib="${ZLIB_DIR}" \
    --with-bz2="${BZ2_PREFIX}" \
    --with-iconv="${ICONV_DIR}" \
    --with-libxml="${LIBXML_PREFIX}"

echo "Building PHP (this may take several minutes)..."
make -j$(sysctl -n hw.ncpu)

echo "Installing PHP to ${INSTALL_DIR}..."
make install

echo "=================================================="
echo "PHP build complete!"
echo "Installation directory: ${INSTALL_DIR}"
echo "=================================================="
