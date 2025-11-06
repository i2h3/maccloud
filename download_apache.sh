#!/bin/bash
set -e

# Script to download and prepare Apache HTTP Server for macOS app bundle

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/MacCloud/Resources/apache"
TEMP_DIR="/tmp/apache-build"

echo "Downloading Apache HTTP Server..."

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "Warning: This script is designed for macOS. Skipping Apache download on $(uname)."
    exit 0
fi

# Create temp directory
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# For now, we'll use httpd from the system or provide instructions
# In a real scenario, you would:
# 1. Download Apache source from https://httpd.apache.org/download.cgi
# 2. Compile it with appropriate flags
# 3. Or download pre-built binaries from a trusted source

# Check if system httpd exists
if command -v httpd &> /dev/null; then
    HTTPD_PATH=$(which httpd)
    echo "Found system httpd at: $HTTPD_PATH"
    
    # Copy httpd binary
    mkdir -p "$RESOURCES_DIR/bin"
    cp "$HTTPD_PATH" "$RESOURCES_DIR/bin/"
    
    # Find and copy modules
    # System Apache modules are typically in /usr/libexec/apache2/
    if [ -d "/usr/libexec/apache2" ]; then
        mkdir -p "$RESOURCES_DIR/modules"
        # Copy only the modules we need
        for module in mod_mpm_event.so mod_authz_core.so mod_dir.so mod_mime.so mod_log_config.so mod_unixd.so; do
            if [ -f "/usr/libexec/apache2/$module" ]; then
                cp "/usr/libexec/apache2/$module" "$RESOURCES_DIR/modules/"
            fi
        done
    fi
    
    # Copy mime.types if available
    mkdir -p "$RESOURCES_DIR/conf"
    if [ -f "/etc/apache2/mime.types" ]; then
        cp "/etc/apache2/mime.types" "$RESOURCES_DIR/conf/"
    elif [ -f "/private/etc/apache2/mime.types" ]; then
        cp "/private/etc/apache2/mime.types" "$RESOURCES_DIR/conf/"
    fi
    
    echo "Apache files copied successfully"
else
    echo "Warning: httpd not found. Please install Apache HTTP Server."
    echo "You can install it via Homebrew: brew install httpd"
    exit 1
fi

echo "Apache setup complete!"
