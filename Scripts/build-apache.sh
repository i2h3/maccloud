#!/bin/bash

# Build script for Apache HTTP Server 2.4
# This script downloads, caches, and builds Apache for inclusion in the MacCloud app bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CACHE_DIR="${PROJECT_ROOT}/Cache"
APACHE_VERSION="2.4.65"
APACHE_SOURCE="httpd-${APACHE_VERSION}"
APACHE_TARBALL="${APACHE_SOURCE}.tar.bz2"
APACHE_URL="https://downloads.apache.org/httpd/${APACHE_TARBALL}"
APR_VERSION="1.7.6"
APR_SOURCE="apr-${APR_VERSION}"
APR_TARBALL="${APR_SOURCE}.tar.bz2"
APR_URL="https://downloads.apache.org/apr/${APR_TARBALL}"
APR_UTIL_VERSION="1.6.3"
APR_UTIL_SOURCE="apr-util-${APR_UTIL_VERSION}"
APR_UTIL_TARBALL="${APR_UTIL_SOURCE}.tar.bz2"
APR_UTIL_URL="https://downloads.apache.org/apr/${APR_UTIL_TARBALL}"
PCRE2_VERSION="10.47"
PCRE2_SOURCE="pcre2-${PCRE2_VERSION}"
PCRE2_TARBALL="${PCRE2_SOURCE}.tar.bz2"
PCRE2_URL="https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE2_VERSION}/${PCRE2_TARBALL}"

BUILD_DIR="${PROJECT_ROOT}/Build"
INSTALL_DIR="${BUILD_PRODUCTS_DIR:-${BUILD_DIR}/Products}/Apache"
PCRE2_INSTALL_DIR="${BUILD_DIR}/pcre2-install"

echo "=================================================="
echo "Building Apache HTTP Server ${APACHE_VERSION}"
echo "=================================================="

# Ensure BUILD_PRODUCTS_DIR has a value
if [ -z "${BUILD_PRODUCTS_DIR}" ]; then
    echo "Note: BUILD_PRODUCTS_DIR not set, using default: ${BUILD_DIR}/Products"
fi

# Create cache directory if it doesn't exist
mkdir -p "${CACHE_DIR}"
mkdir -p "${BUILD_DIR}"

# Download and cache Apache if not already cached
if [ ! -f "${CACHE_DIR}/${APACHE_TARBALL}" ]; then
    echo "Downloading Apache ${APACHE_VERSION} from ${APACHE_URL}"
    curl -sS -L -o "${CACHE_DIR}/${APACHE_TARBALL}" "${APACHE_URL}"
else
    echo "Using cached Apache ${APACHE_VERSION}"
fi

# Download and cache APR if not already cached
if [ ! -f "${CACHE_DIR}/${APR_TARBALL}" ]; then
    echo "Downloading APR ${APR_VERSION} from ${APR_URL}"
    curl -sS -L -o "${CACHE_DIR}/${APR_TARBALL}" "${APR_URL}"
else
    echo "Using cached APR ${APR_VERSION}"
fi

# Download and cache APR-Util if not already cached
if [ ! -f "${CACHE_DIR}/${APR_UTIL_TARBALL}" ]; then
    echo "Downloading APR-Util ${APR_UTIL_VERSION} from ${APR_UTIL_URL}"
    curl -sS -L -o "${CACHE_DIR}/${APR_UTIL_TARBALL}" "${APR_UTIL_URL}"
else
    echo "Using cached APR-Util ${APR_UTIL_VERSION}"
fi

# Download and cache PCRE2 if not already cached
if [ ! -f "${CACHE_DIR}/${PCRE2_TARBALL}" ]; then
    echo "Downloading PCRE2 ${PCRE2_VERSION} from ${PCRE2_URL}"
    curl -sS -L -o "${CACHE_DIR}/${PCRE2_TARBALL}" "${PCRE2_URL}"
else
    echo "Using cached PCRE2 ${PCRE2_VERSION}"
fi

# Build PCRE2 first (required for Apache)
echo "Building PCRE2..."
cd "${BUILD_DIR}"
if [ -d "${PCRE2_SOURCE}" ]; then
    rm -rf "${PCRE2_SOURCE}"
fi
tar xjf "${CACHE_DIR}/${PCRE2_TARBALL}"
cd "${PCRE2_SOURCE}"

echo "Configuring PCRE2..."
./configure --prefix="${PCRE2_INSTALL_DIR}" --enable-jit

echo "Building PCRE2 (this may take a few minutes)..."
make -j$(sysctl -n hw.ncpu)

echo "Installing PCRE2 to ${PCRE2_INSTALL_DIR}..."
make install

# Extract Apache
echo "Extracting Apache..."
cd "${BUILD_DIR}"
if [ -d "${APACHE_SOURCE}" ]; then
    rm -rf "${APACHE_SOURCE}"
fi
tar xjf "${CACHE_DIR}/${APACHE_TARBALL}"

# Extract APR into Apache srclib
echo "Extracting APR..."
cd "${BUILD_DIR}/${APACHE_SOURCE}/srclib"
if [ -d "apr" ]; then
    rm -rf "apr"
fi
tar xjf "${CACHE_DIR}/${APR_TARBALL}"
mv "${APR_SOURCE}" apr

# Extract APR-Util into Apache srclib
echo "Extracting APR-Util..."
if [ -d "apr-util" ]; then
    rm -rf "apr-util"
fi
tar xjf "${CACHE_DIR}/${APR_UTIL_TARBALL}"
mv "${APR_UTIL_SOURCE}" apr-util

# Configure and build Apache
echo "Configuring Apache..."
cd "${BUILD_DIR}/${APACHE_SOURCE}"

./configure \
    --prefix="${INSTALL_DIR}" \
    --with-included-apr \
    --with-pcre="${PCRE2_INSTALL_DIR}/bin/pcre2-config" \
    --enable-mods-shared=few \
    --enable-proxy \
    --enable-proxy-fcgi \
    --enable-rewrite \
    --enable-so \
    --enable-mime \
    --enable-dir \
    --enable-env \
    --enable-authz-core \
    --enable-mpm=prefork

echo "Building Apache (this may take several minutes)..."
make -j$(sysctl -n hw.ncpu)

echo "Installing Apache to ${INSTALL_DIR}..."
make install

echo "=================================================="
echo "Apache build complete!"
echo "Installation directory: ${INSTALL_DIR}"
echo "=================================================="
