#!/bin/bash

# Git Genius Installer (Improved: Always Try /usr/bin First)
DEFAULT_INSTALL_PATH="/usr/bin/git-genius"
FALLBACK_INSTALL_PATH="$HOME/.local/bin/git-genius"
SCRIPT_NAME="git-genius.sh"
DRY_RUN=false

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "   🛠️  ${CYAN}Git Genius Installer Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Check if dry-run mode
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
  echo -e "${YELLOW}🔍 Running in dry-run mode...${NC}"
fi

# Auto-find script path if not present
if [ ! -f "$SCRIPT_NAME" ]; then
  echo -e "${YELLOW}⚠️  '$SCRIPT_NAME' not found in current directory.${NC}"
  read -p "🔍 Enter full path to your script: " SCRIPT_NAME
  if [ ! -f "$SCRIPT_NAME" ]; then
    echo -e "${RED}❌ Script '$SCRIPT_NAME' not found! Aborting.${NC}"
    exit 1
  fi
fi

INSTALL_PATH="$DEFAULT_INSTALL_PATH"
INSTALL_SUCCESS=false

# Check if already installed
if [ -f "$INSTALL_PATH" ]; then
  echo -e "${YELLOW}⚠️  Git Genius already exists at $INSTALL_PATH${NC}"
  read -p "🔁 Do you want to overwrite it? (y/N): " OVERWRITE
  [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]] && {
    echo -e "${RED}🚫 Installation cancelled.${NC}"
    exit 0
  }
fi

# Try installing to /usr/bin
if [ "$DRY_RUN" = false ]; then
  echo -e "${BLUE}📦 Trying to install to ${CYAN}/usr/bin${NC}..."
  if cp "$SCRIPT_NAME" "$DEFAULT_INSTALL_PATH" 2>/dev/null && chmod +x "$DEFAULT_INSTALL_PATH"; then
    INSTALL_PATH="$DEFAULT_INSTALL_PATH"
    INSTALL_SUCCESS=true
  elif command -v sudo >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Permission denied. Retrying with sudo...${NC}"
    if sudo cp "$SCRIPT_NAME" "$DEFAULT_INSTALL_PATH" && sudo chmod +x "$DEFAULT_INSTALL_PATH"; then
      INSTALL_PATH="$DEFAULT_INSTALL_PATH"
      INSTALL_SUCCESS=true
    fi
  fi
fi

# Fallback if /usr/bin fails
if [ "$INSTALL_SUCCESS" = false ]; then
  echo -e "${YELLOW}📦 Falling back to user-local install: ${CYAN}$FALLBACK_INSTALL_PATH${NC}"
  mkdir -p "$(dirname "$FALLBACK_INSTALL_PATH")"
  INSTALL_PATH="$FALLBACK_INSTALL_PATH"
  if [ "$DRY_RUN" = false ]; then
    cp "$SCRIPT_NAME" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    INSTALL_SUCCESS=true
  fi
fi

# Suggest adding to PATH if fallback used
if [[ "$INSTALL_PATH" == "$FALLBACK_INSTALL_PATH" ]]; then
  echo -e "${YELLOW}📢 Please ensure '${CYAN}~/.local/bin${NC}' is in your PATH."
  echo -e "   Add this line to your shell profile if needed:"
  echo -e "   ${CYAN}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}"
fi

# Verify installation
if command -v git-genius >/dev/null 2>&1; then
  echo -e "${GREEN}✅ Git Genius installed successfully!${NC}"
  echo -e "👉 Run it from anywhere using: ${CYAN}git-genius${NC}"
elif [ -x "$INSTALL_PATH" ]; then
  echo -e "${GREEN}✅ Git Genius installed at: $INSTALL_PATH${NC}"
  echo -e "👉 You may need to restart your terminal or update PATH."
else
  echo -e "${RED}❌ Installation failed. Please check permissions.${NC}"
  exit 1
fi

# Optional: Offer alias
echo -e "${YELLOW}💡 Tip: Create an alias for easier use.${NC}"
read -p "➕ Create Bash alias 'gg' for 'git-genius'? (y/N): " ALIAS
if [[ "$ALIAS" == "y" || "$ALIAS" == "Y" ]]; then
  echo "alias gg='git-genius'" >> ~/.bashrc
  echo -e "${GREEN}✔ Alias added. Restart your terminal to use 'gg'.${NC}"
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"