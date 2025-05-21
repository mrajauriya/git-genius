#!/data/data/com.itsaky.androidide/files/usr/bin/bash

# Git Genius v3.8 – Beautiful Developer-Focused GitHub Helper CLI

CONFIG_FILE="$HOME/.gitquickconfig"
TOKEN_FILE="$HOME/.git-token"
BRANCH_FILE="$HOME/.git-branch"
REMOTE_FILE="$HOME/.git-remote"

GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
NC="\033[0m"

trap 'echo -e "\n${YELLOW}👋 Exiting Git Genius. Goodbye! Stay awesome!${NC}"; exit 0' SIGINT

ensure_git_installed() {
  if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}❌ Git is not installed!${NC}"
    echo -e "${YELLOW}📦 Installing Git...${NC}"
    if command -v pkg >/dev/null 2>&1; then
      pkg install git -y
    elif command -v apt >/dev/null 2>&1; then
      sudo apt update && sudo apt install git -y
    else
      echo -e "${RED}⚠ Unsupported package manager. Please install Git manually.${NC}"
      exit 1
    fi

    if command -v git >/dev/null 2>&1; then
      echo -e "${GREEN}✔ Git installed successfully!${NC}"
    else
      echo -e "${RED}✘ Git installation failed. Exiting...${NC}"
      exit 1
    fi
  fi
}

show_header() {
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "  ${CYAN}✨ GitHub Helper - Terminal GUI v3.8 ✨${BLUE}"
  echo -e "     ${MAGENTA}Crafted with ♥ by moHaN-ShaArmA${BLUE}"
  echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

show_subheading() {
  echo -e "\n${MAGENTA}==> $1 ${NC}"
}

pause_and_continue() {
  echo -e "${YELLOW}⏳ Returning to menu in 2 seconds...${NC}"
  sleep 2
}

show_header
ensure_git_installed

setup_config() {
  echo -e "${YELLOW}⚙ Initial Configuration:${NC}"
  read -p "🧑 GitHub Username: " GITHUB_USER
  read -p "✉️  GitHub Email: " GITHUB_EMAIL
  git config --global user.name "$GITHUB_USER"
  git config --global user.email "$GITHUB_EMAIL"
  echo "username=$GITHUB_USER" > "$CONFIG_FILE"
  echo "email=$GITHUB_EMAIL" >> "$CONFIG_FILE"

  echo -e "${CYAN}🔑 Paste your GitHub Personal Access Token (PAT):${NC}"
  read -s TOKEN
  echo "$TOKEN" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
  echo -e "${GREEN}✔ Token saved securely.${NC}"
}

[ ! -f "$CONFIG_FILE" ] && setup_config

source "$CONFIG_FILE"
TOKEN=$(cat "$TOKEN_FILE")

[ ! -f "$BRANCH_FILE" ] && { read -p "🌿 Default branch name (main/master/custom): " BRANCH; echo "$BRANCH" > "$BRANCH_FILE"; }
BRANCH=$(cat "$BRANCH_FILE")

[ ! -d .git ] && echo -e "${YELLOW}📁 Initializing Git repository...${NC}" && git init
git config --global --add safe.directory "$(pwd)"

[ ! -f "$REMOTE_FILE" ] && {
  read -p "🔗 GitHub repo URL (https://github.com/user/repo.git): " REMOTE_URL
  git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
  echo "$REMOTE_URL" > "$REMOTE_FILE"
}
REMOTE_URL=$(cat "$REMOTE_FILE")
AUTH_REMOTE=$(echo "$REMOTE_URL" | sed "s|https://|https://$GITHUB_USER:$TOKEN@|")

OPTIONS=(
  "🔼 Push Changes"
  "🔽 Pull Latest"
  "🔍 View Status"
  "📝 View Log"
  "🧾 View Diff"
  "🌿 Switch/Create Branch"
  "📦 Generate .gitignore"
  "👀 View File History"
  "🔗 Show Remote URL"
  "⚙ Settings"
  "❓ Help"
  "❌ Exit"
)

show_menu() {
  echo -e "\n${CYAN}🚀 Choose an operation:${NC}"
  for i in "${!OPTIONS[@]}"; do
    echo "  [$((i + 1))] ${OPTIONS[$i]}"
  done
  read -p "👉 Your choice (1-${#OPTIONS[@]}): " CHOICE
  OPERATION="${OPTIONS[$((CHOICE - 1))]}"
}

settings_menu() {
  show_subheading "⚙ Settings"
  echo -e "${CYAN}🔧 What would you like to change?${NC}"
  echo "  [1] ✏️  Change Username & Email"
  echo "  [2] 🔐 Change Token"
  echo "  [3] 🌿 Change Default Branch"
  echo "  [4] 🔗 Change Remote URL"
  echo "  [5] 🔙 Back to Menu"
  read -p "👉 Select option: " SET_CHOICE
  case $SET_CHOICE in
    1)
      read -p "👤 New Username: " NEW_USER
      read -p "✉️  New Email: " NEW_EMAIL
      git config --global user.name "$NEW_USER"
      git config --global user.email "$NEW_EMAIL"
      echo "username=$NEW_USER" > "$CONFIG_FILE"
      echo "email=$NEW_EMAIL" >> "$CONFIG_FILE"
      echo -e "${GREEN}✔ Updated username and email.${NC}"
      ;;
    2)
      echo -e "${CYAN}🔑 Enter new token:${NC}"
      read -s NEW_TOKEN
      echo "$NEW_TOKEN" > "$TOKEN_FILE"
      chmod 600 "$TOKEN_FILE"
      echo -e "${GREEN}✔ Token updated.${NC}"
      ;;
    3)
      read -p "🌿 New branch: " NEW_BRANCH
      echo "$NEW_BRANCH" > "$BRANCH_FILE"
      echo -e "${GREEN}✔ Branch updated.${NC}"
      ;;
    4)
      read -p "🔗 New remote URL: " NEW_REMOTE
      git remote set-url origin "$NEW_REMOTE"
      echo "$NEW_REMOTE" > "$REMOTE_FILE"
      echo -e "${GREEN}✔ Remote URL updated.${NC}"
      ;;
    *)
      echo -e "${YELLOW}🔙 Back to menu...${NC}"
      ;;
  esac
}

show_help() {
  show_subheading "❓ Help"
  echo -e "${GREEN}🔼 Push:${NC} Stage, commit, and push changes."
  echo -e "${GREEN}🔽 Pull:${NC} Fetch and merge latest changes."
  echo -e "${GREEN}🔍 Status:${NC} See what's changed."
  echo -e "${GREEN}📝 Log:${NC} View commit history."
  echo -e "${GREEN}🧾 Diff:${NC} View uncommitted changes."
  echo -e "${GREEN}🌿 Branch:${NC} Switch or create branches."
  echo -e "${GREEN}📦 .gitignore:${NC} Generate standard ignore rules."
  echo -e "${GREEN}👀 History:${NC} File-level commit history."
  echo -e "${GREEN}🔗 URL:${NC} Show the current Git remote URL."
  echo -e "${GREEN}⚙ Settings:${NC} Update user, branch, token, remote."
  echo -e "${GREEN}❌ Exit:${NC} Quit the helper tool."
}

while true; do
  show_menu
  case "$OPERATION" in
    "🔼 Push Changes")
      show_subheading "🔼 Push Changes"
      git add .
      if git diff --cached --quiet && git diff --quiet; then
        echo -e "${YELLOW}⚠️  Nothing to commit!${NC}"
      else
        git status -s
        read -p "✏️  Commit message: " MSG
        git commit -m "$MSG"
        git remote set-url origin "$AUTH_REMOTE"
        git push origin HEAD:"$BRANCH" && echo -e "${GREEN}✔ Pushed to $BRANCH.${NC}" || echo -e "${RED}✘ Push failed.${NC}"
        git remote set-url origin "$REMOTE_URL"
      fi
      pause_and_continue
      ;;
    "🔽 Pull Latest")
      show_subheading "🔽 Pull Latest"
      git remote set-url origin "$AUTH_REMOTE"
      git pull origin "$BRANCH" && echo -e "${GREEN}✔ Pulled successfully.${NC}" || echo -e "${RED}✘ Pull failed.${NC}"
      git remote set-url origin "$REMOTE_URL"
      pause_and_continue
      ;;
    "🔍 View Status")
      show_subheading "🔍 Git Status"
      git status
      pause_and_continue
      ;;
    "📝 View Log")
      show_subheading "📝 Git Log"
      git log --oneline --graph --decorate -n 10
      pause_and_continue
      ;;
    "🧾 View Diff")
      show_subheading "🧾 Git Diff"
      git diff
      pause_and_continue
      ;;
    "🌿 Switch/Create Branch")
      show_subheading "🌿 Branch Management"
      git branch
      read -p "🌱 Branch name to switch/create: " BR
      git checkout -B "$BR"
      echo "$BR" > "$BRANCH_FILE"
      echo -e "${GREEN}✔ Now on branch '$BR'.${NC}"
      pause_and_continue
      ;;
    "📦 Generate .gitignore")
      show_subheading "📦 Generating .gitignore"
      echo -e "# Android .gitignore\n*.iml\n.gradle/\nbuild/\n.idea/" > .gitignore
      echo -e "${GREEN}✔ .gitignore created.${NC}"
      pause_and_continue
      ;;
    "👀 View File History")
      show_subheading "👀 File Commit History"
      read -p "📄 Enter file path: " FILE
      [ -f "$FILE" ] && git log --follow -- "$FILE" || echo -e "${RED}✘ File not found.${NC}"
      pause_and_continue
      ;;
    "🔗 Show Remote URL")
      show_subheading "🔗 Remote Repository URL"
      echo -e "${CYAN}Remote origin:${NC} $REMOTE_URL"
      pause_and_continue
      ;;
    "⚙ Settings")
      settings_menu
      pause_and_continue
      ;;
    "❓ Help")
      show_help
      pause_and_continue
      ;;
    "❌ Exit")
      echo -e "${YELLOW}👋 Exiting Git Genius. Goodbye!${NC}"
      exit 0
      ;;
    *)
      echo -e "${RED}❗ Invalid selection. Please try again.${NC}"
      pause_and_continue
      ;;
  esac
done
