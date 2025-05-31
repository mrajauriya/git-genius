#!/bin/bash

# Git Genius Installer
INSTALL_PATH="/usr/bin/git-genius"
SCRIPT_NAME="git-genius.sh"

echo "🔧 Installing Git Genius..."

# Check permissions
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root using: sudo ./install.sh"
  exit 1
fi

# Check if script exists
if [ ! -f "$SCRIPT_NAME" ]; then
  echo "❌ Script '$SCRIPT_NAME' not found in current directory!"
  exit 1
fi

# Copy to /usr/bin
cp "$SCRIPT_NAME" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "✅ Git Genius installed successfully!"
echo "👉 Run it from anywhere using: ${GREEN}git-genius${NC}"