#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Usage: sudo ./install_node_opt.sh [24.11.0]
# Defaults to v24 family; pass specific version like "24.11.0" to override.

VERSION="${1:-24.11.0}"
MAJOR="v${VERSION%%.*}"
TMPDIR="$(mktemp -d)"
INSTALL_ROOT="/opt/node"
TARGET_DIR="$INSTALL_ROOT/${MAJOR}"      # final path: /opt/node/v24
TMP_TAR="$TMPDIR/node-${VERSION}.tar.xz"

error_exit() {
  echo "[ERROR] $*" >&2
  rm -rf "$TMPDIR" || true
  exit 1
}

info(){ echo "[INFO] $*"; }

if [ "$(id -u)" -ne 0 ]; then
  error_exit "must be run as root (use sudo)"
fi

# detect arch for Node binary name
UNAME_M="$(uname -m)"
case "$UNAME_M" in
  x86_64|amd64) ARCH="linux-x64" ;;
  aarch64|arm64) ARCH="linux-arm64" ;;
  armv7l) ARCH="linux-armv7l" ;;
  *) error_exit "unsupported architecture: $UNAME_M" ;;
esac

NODE_DIST_NAME="node-v${VERSION}-${ARCH}"
NODE_TARBALL="${NODE_DIST_NAME}.tar.xz"
NODE_URL="https://nodejs.org/dist/v${VERSION}/${NODE_TARBALL}"

info "Downloading Node.js $VERSION for $ARCH..."
curl -fsSL "$NODE_URL" -o "$TMP_TAR" || error_exit "download failed: $NODE_URL"

info "Preparing target directory: $TARGET_DIR"
mkdir -p "$INSTALL_ROOT"
# remove old MAJOR dir atomically if present (keep backups if needed)
rm -rf "$TARGET_DIR.tmp" "$TARGET_DIR" || true
mkdir -p "$TARGET_DIR.tmp"

info "Extracting..."
tar -xJf "$TMP_TAR" -C "$TARGET_DIR.tmp" --strip-components=1 || error_exit "extract failed"

# move into place
mv "$TARGET_DIR.tmp" "$TARGET_DIR"
chmod -R 0755 "$TARGET_DIR"
chown -R root:root "$TARGET_DIR"

# create /etc/profile.d entry to add to PATH for all users (login shells)
PROFILE_D="/etc/profile.d/node_${MAJOR}.sh"
cat > "$PROFILE_D" <<EOF
# Node.js $VERSION added by install_node_opt.sh
export PATH="$TARGET_DIR/bin:\$PATH"
EOF
chmod 0644 "$PROFILE_D"

# also add a symlink in /etc/environment-compatible place for non-login shells used by some services
# create a small file that systemd nspawn/other services can source if they choose.
ENV_FILE="/etc/default/node_${MAJOR}"
cat > "$ENV_FILE" <<EOF
NODE_HOME="$TARGET_DIR"
PATH="$TARGET_DIR/bin:\$PATH"
EOF
chmod 0644 "$ENV_FILE"

# create convenience symlinks in /usr/local/bin (idempotent)
for exe in node npm npx; do
  if [ -x "$TARGET_DIR/bin/$exe" ]; then
    ln -sf "$TARGET_DIR/bin/$exe" "/usr/local/bin/$exe"
  fi
done

# cleanup
rm -rf "$TMPDIR"

info "Node $VERSION installed to $TARGET_DIR"
info "PATH updated via $PROFILE_D and symlinks in /usr/local/bin"

# verify quickly
if command -v node >/dev/null 2>&1; then
  echo "node -> $(command -v node) : $(node -v)"
  echo "npm  -> $(command -v npm)  : $(npm -v || echo 'npm not found')"
else
  echo "[WARN] node not visible in current shell. New shells will see the updated PATH. Run: source $PROFILE_D"
fi
