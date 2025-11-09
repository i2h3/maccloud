#!/bin/bash
# Shared helper to robustly locate (and optionally install) Homebrew in minimal Xcode/CI envs.
# Exposes BREW_BIN and BREW_PREFIX and ensures PATH contains their bin/sbin.
# Usage: source "$(dirname "$0")/detect-homebrew.sh"; ensure_homebrew

set -euo pipefail

ensure_homebrew() {
  if [ -n "${BREW_BIN:-}" ] && [ -x "${BREW_BIN}" ]; then
    return 0
  fi
  local candidates=(
    "/opt/homebrew/bin/brew"
    "/usr/local/bin/brew"
    "$HOME/.linuxbrew/bin/brew"
  )
  for c in "${candidates[@]}"; do
    if [ -x "$c" ]; then
      BREW_BIN="$c"
      break
    fi
  done
  if [ -z "${BREW_BIN:-}" ]; then
    if command -v brew >/dev/null 2>&1; then
      BREW_BIN="$(command -v brew)"
    else
      echo "[detect-homebrew] Homebrew nicht gefunden – Installation wird versucht..." >&2
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        echo "[detect-homebrew] Fehler: Homebrew-Installation fehlgeschlagen." >&2
        return 1
      }
      for c in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
        if [ -x "$c" ]; then
          BREW_BIN="$c"
          break
        fi
      done
    fi
  fi
  if [ -z "${BREW_BIN:-}" ]; then
    echo "[detect-homebrew] Fehler: Homebrew konnte nicht gefunden werden." >&2
    return 1
  fi
  BREW_PREFIX="$("$BREW_BIN" --prefix 2>/dev/null || true)"
  local brew_bin_dir
  brew_bin_dir="$(dirname "$BREW_BIN")"
  local brew_sbin_dir
  brew_sbin_dir="${BREW_PREFIX}/sbin"
  export PATH="${brew_bin_dir}:${brew_sbin_dir}:${PATH}"
  export BREW_BIN BREW_PREFIX
  echo "[detect-homebrew] Verwende Homebrew unter: ${BREW_PREFIX}" >&2
}
