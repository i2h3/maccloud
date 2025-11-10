#!/bin/bash

set -euo pipefail

# MARK: - Set up Homebrew.

export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

if [ -n "${BREW_BIN:-}" ] && [ -x "${BREW_BIN}" ]; then
    return 0
fi

BREW_BIN_CANDIDATES=(
    "/opt/homebrew/bin/brew"
    "/usr/local/bin/brew"
    "$HOME/.linuxbrew/bin/brew"
)

for c in "${BREW_BIN_CANDIDATES[@]}"; do
    if [ -x "$c" ]; then
        BREW_BIN="$c"
        break
    fi
done

if [ -z "${BREW_BIN:-}" ]; then
    echo "Error: failed to find Hombrew!" >&2
    return 1
fi

BREW_PREFIX="$("$BREW_BIN" --prefix 2>/dev/null || true)"
BREW_BIN_DIR="$(dirname "$BREW_BIN")"
BREW_SBIN_DIR="${BREW_PREFIX}/sbin"
export PATH="${BREW_BIN_DIR}:${BREW_SBIN_DIR}:${PATH}"
export BREW_BIN BREW_PREFIX
echo "Using Homebrew at: ${BREW_PREFIX}" >&2

echo "Ensuring Homebrew dependencies are installed..."
"$BREW_BIN" update

# MARK: - Set up build paths.

PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DEPENDENCIES_ROOT="${PROJECT_ROOT}/Dependencies"
CACHE_DIR="${DEPENDENCIES_ROOT}/Cache"
BUILD_DIR="${DEPENDENCIES_ROOT}/Build"
BUILT_PRODUCTS_DIR="${DEPENDENCIES_ROOT}/Products"

mkdir -p "${CACHE_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${BUILT_PRODUCTS_DIR}"

echo "Resolved PROJECT_ROOT: ${PROJECT_ROOT}"
echo "Resolved CACHE_DIR: ${CACHE_DIR}"
echo "Resolved BUILD_DIR: ${BUILD_DIR}"
echo "Resolved BUILT_PRODUCTS_DIR: ${BUILT_PRODUCTS_DIR}"
