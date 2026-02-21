#!/usr/bin/env bash

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Run as root (sudo ./install-plantuml.sh)"
  exit 1
fi

USER_HOME="$(eval echo ~${SUDO_USER:-$USER})"
PLANTUML_DIR="$USER_HOME/.local/share/plantuml"
BIN_DIR="$USER_HOME/.local/bin"

install_if_missing() {
  if ! command -v "$1" >/dev/null 2>&1; then
    apt-get update -y
    apt-get install -y "$2"
  fi
}

# Install Java if missing
install_if_missing java default-jre

# Install Graphviz if missing
install_if_missing dot graphviz

# Create directories
mkdir -p "$PLANTUML_DIR"
mkdir -p "$BIN_DIR"

# Download PlantUML jar if not present
if [ ! -f "$PLANTUML_DIR/plantuml.jar" ]; then
  curl -L https://github.com/plantuml/plantuml/releases/latest/download/plantuml.jar \
    -o "$PLANTUML_DIR/plantuml.jar"
fi

# Create wrapper script if missing
if [ ! -f "$BIN_DIR/plantuml" ]; then
cat > "$BIN_DIR/plantuml" <<EOF
#!/usr/bin/env bash
java -jar "$PLANTUML_DIR/plantuml.jar" "\$@"
EOF
  chmod +x "$BIN_DIR/plantuml"
  chown "$SUDO_USER":"$SUDO_USER" "$BIN_DIR/plantuml"
fi

# Ensure PATH in bashrc
if ! grep -q "$BIN_DIR" "$USER_HOME/.bashrc"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
fi

chown -R "$SUDO_USER":"$SUDO_USER" "$USER_HOME/.local"

echo "PlantUML installed."
echo "Run as user: plantuml -version"
