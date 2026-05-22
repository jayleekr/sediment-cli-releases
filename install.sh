#!/usr/bin/env bash
# Sediment CLI installer.
#
# Detects platform, downloads the latest release tarball from
# jayleekr/sediment-cli-releases, verifies SHA256, installs the binary
# to ~/.local/bin/sediment (or /usr/local/bin if writable + no ~/.local/bin).
#
# Idempotent — re-running pulls the latest. Safe in CI (no interactive
# prompts; uses SED_INSTALL_DIR to override target).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/jayleekr/sediment-cli-releases/main/install.sh | bash
#   # or with version pin:
#   curl -fsSL https://raw.githubusercontent.com/jayleekr/sediment-cli-releases/main/install.sh | \
#     SED_VERSION=sediment-cli-v0.1.3 bash

set -euo pipefail

REPO="jayleekr/sediment-cli-releases"
BIN="sediment"

# --- platform detection ---
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Darwin-arm64)        TARGET="aarch64-apple-darwin" ;;
  Darwin-x86_64)       TARGET="x86_64-apple-darwin" ;;
  Linux-x86_64)        TARGET="x86_64-unknown-linux-gnu" ;;
  *)
    echo "ERROR: unsupported platform $OS-$ARCH" >&2
    echo "Supported: macOS arm64, macOS x86_64, Linux x86_64" >&2
    echo "Build from source: https://github.com/jayleekr/sediment-cli-releases" >&2
    exit 1
    ;;
esac

# --- version resolution ---
if [ -n "${SED_VERSION:-}" ]; then
  TAG="$SED_VERSION"
  echo "==> Using pinned version: $TAG"
else
  echo "==> Resolving latest release tag..."
  TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  if [ -z "$TAG" ]; then
    echo "ERROR: couldn't resolve latest release tag" >&2
    exit 2
  fi
fi

ASSET="sediment-${TARGET}.tar.gz"
SHA_ASSET="${ASSET}.sha256"
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"
SHA_URL="https://github.com/$REPO/releases/download/$TAG/$SHA_ASSET"

# --- install dir ---
if [ -n "${SED_INSTALL_DIR:-}" ]; then
  INSTALL_DIR="$SED_INSTALL_DIR"
elif [ -d "$HOME/.local/bin" ] || mkdir -p "$HOME/.local/bin" 2>/dev/null; then
  INSTALL_DIR="$HOME/.local/bin"
elif [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
else
  echo "ERROR: no writable install dir found. Set SED_INSTALL_DIR=/abs/path and re-run." >&2
  exit 3
fi

# --- download + verify ---
echo "==> Downloading $TAG / $TARGET..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/$ASSET" "$URL" || {
  echo "ERROR: download failed: $URL" >&2
  exit 4
}
curl -fsSL -o "$TMP/$SHA_ASSET" "$SHA_URL" || {
  echo "WARN: SHA256 file not found at $SHA_URL — proceeding without verify" >&2
}

if [ -f "$TMP/$SHA_ASSET" ]; then
  echo "==> Verifying SHA256..."
  (cd "$TMP" && shasum -a 256 -c "$SHA_ASSET" >/dev/null) || {
    echo "ERROR: checksum mismatch on $ASSET — aborting" >&2
    exit 5
  }
fi

# --- extract + install ---
echo "==> Installing to $INSTALL_DIR/$BIN..."
tar -xzf "$TMP/$ASSET" -C "$TMP"
chmod +x "$TMP/$BIN"
mv "$TMP/$BIN" "$INSTALL_DIR/$BIN"

# --- post-install advice ---
echo "✓ installed $($INSTALL_DIR/$BIN --version 2>/dev/null || echo "$BIN ($TAG)")"
case ":$PATH:" in
  *:$INSTALL_DIR:*) ;;
  *)
    echo
    echo "NOTE: $INSTALL_DIR is not on your PATH."
    echo "Add this to your shell rc (~/.zshrc or ~/.bashrc):"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac
echo
echo "Next: run \`sediment login\` to authenticate."
