#!/bin/bash

# Git Genius Uninstaller Script
SCRIPT_NAME="git-genius"
POSSIBLE_PATHS=(
  "/usr/bin/$SCRIPT_NAME"
  "$HOME/.local/bin/$SCRIPT_NAME"
  "$PREFIX/bin/$SCRIPT_NAME"  # for Termux
)

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
NC="\033[0m"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "   🧹  ${CYAN}Git Genius Uninstaller Script${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

FOUND_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
  if [ -f "$path" ]; then
    FOUND_PATH="$path"
    break
  fi
done

if [ -z "$FOUND_PATH" ]; then
  echo -e "${RED}❌ Git Genius is not installed in known locations.${NC}"
  exit 1
fi

echo -e "${YELLOW}📦 Found installed at: ${CYAN}$FOUND_PATH${NC}"
read -p "❓ Do you want to remove it? (y/N): " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && {
  echo -e "${RED}❌ Uninstallation cancelled.${NC}"
  exit 0
}

# Try removing the file (with sudo if needed)
if rm "$FOUND_PATH" 2>/dev/null; then
  echo -e "${GREEN}✔ Removed successfully from $FOUND_PATH${NC}"
elif command -v sudo >/dev/null 2>&1 && sudo rm "$FOUND_PATH"; then
  echo -e "${GREEN}✔ Removed with sudo from $FOUND_PATH${NC}"
else
  echo -e "${RED}❌ Failed to remove $FOUND_PATH. Please try manually.${NC}"
  exit 1
fi

# Remove alias
ALIAS_LINE="alias gg='git-genius'"
if grep -Fxq "$ALIAS_LINE" ~/.bashrc; then
  read -p "➖ Remove 'gg' alias from .bashrc? (y/N): " REMOVE_ALIAS
  if [[ "$REMOVE_ALIAS" == "y" || "$REMOVE_ALIAS" == "Y" ]]; then
    sed -i "/$ALIAS_LINE/d" ~/.bashrc
    echo -e "${GREEN}✔ Alias removed. Restart your terminal to apply changes.${NC}"
  fi
fi

echo -e "${GREEN}🎉 Git Genius has been successfully uninstalled.${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"