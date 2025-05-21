#!/bin/bash

# Git Genius v4.5 – Beautiful Developer-Focused GitHub Helper CLI

CONFIG_FILE="$HOME/.gitquickconfig"
TOKEN_FILE="$HOME/.git-token"
BRANCH_FILE="$HOME/.git-branch"
REMOTE_FILE="$HOME/.git-remote"
VERSION="v4.5"

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
NC="\033[0m"

trap 'echo -e "\n${YELLOW}👋 Exiting Git Genius. Goodbye!${NC}"; exit 0' SIGINT

ensure_git_installed() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}❌ Git is not installed!${NC}"
        echo -e "${YELLOW}📦 Installing Git...${NC}"
        if command -v pkg &> /dev/null; then
            pkg install git -y
        elif command -v apt &> /dev/null; then
            sudo apt update && sudo apt install git -y
        else
            echo -e "${RED}⚠ Unsupported package manager. Please install Git manually.${NC}"
            exit 1
        fi
    fi
}

check_internet() {
    curl -s https://github.com &> /dev/null || {
        echo -e "${RED}❌ No internet connection!${NC}"
        exit 1
    }
}

show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${CYAN}✨ GitHub Helper - Terminal GUI $VERSION ✨${BLUE}"
    echo -e "     ${MAGENTA}Crafted with ♥ by moHaN-ShaArmA${BLUE}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

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

validate_git_repo_directory() {
    if [ ! -d .git ]; then
        echo -e "${RED}❌ Not a Git repository!${NC}"
        echo -e "${YELLOW}💡 Tip: cd into a valid cloned repo folder before running Git Genius.${NC}"
        exit 1
    fi

    if [ -f "$REMOTE_FILE" ]; then
        CONFIGURED_REMOTE=$(cat "$REMOTE_FILE")
        ACTUAL_REMOTE=$(git remote get-url origin 2>/dev/null)

        REPO_NAME=$(basename -s .git "$CONFIGURED_REMOTE")
        CURRENT_DIR_NAME=$(basename "$PWD")

        if [[ "$CONFIGURED_REMOTE" != "$ACTUAL_REMOTE" ]]; then
            echo -e "${RED}⚠ Remote URL mismatch!${NC}"
            echo -e "Expected: $CONFIGURED_REMOTE"
            echo -e "Found:    $ACTUAL_REMOTE"
            echo -e "${YELLOW}💡 Tip: Run '⚙ Settings' to update the remote URL.${NC}"
            exit 1
        elif [[ "$CURRENT_DIR_NAME" != "$REPO_NAME" ]]; then
            echo -e "${RED}⚠ Directory name doesn't match the repository name!${NC}"
            echo -e "Expected directory: ${GREEN}$REPO_NAME${NC}"
            echo -e "Current directory:  ${RED}$CURRENT_DIR_NAME${NC}"
            echo -e "${YELLOW}💡 Tip: Make sure you’re in the folder named after your repo.${NC}"
            exit 1
        fi
    fi
}

initialize_git_settings() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
    TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null)
    BRANCH=$(cat "$BRANCH_FILE" 2>/dev/null)

    [ -z "$BRANCH" ] && {
        DEFAULT_BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
        BRANCH=${DEFAULT_BRANCH:-main}
        echo "$BRANCH" > "$BRANCH_FILE"
    }

    git config --global --add safe.directory "$(pwd)"

    [ ! -f "$REMOTE_FILE" ] && {
        read -p "🔗 GitHub repo URL (https://github.com/user/repo.git): " REMOTE_URL
        git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
        echo "$REMOTE_URL" > "$REMOTE_FILE"
    }

    REMOTE_URL=$(cat "$REMOTE_FILE" 2>/dev/null)
    AUTH_REMOTE=$(echo "$REMOTE_URL" | sed "s|https://|https://$username:$TOKEN@|")
}

OPTIONS=(
    "🔼 Push Changes" "🔽 Pull Latest" "🔍 View Status"
    "📝 View Log" "🧾 View Diff" "🌿 Switch/Create Branch"
    "📦 Generate .gitignore" "👀 View File History"
    "🔗 Show Remote URL" "⚙ Settings"
    "🔐 Reauthenticate" "❓ Help" "❌ Exit"
)

show_menu() {
    echo -e "\n${CYAN}🚀 Choose an operation:${NC}"
    for i in "${!OPTIONS[@]}"; do
        echo "  [$((i + 1))] ${OPTIONS[$i]}"
    done
    read -p "👉 Your choice (1-${#OPTIONS[@]}): " CHOICE
    if [[ "$CHOICE" =~ ^[0-9]+$ && "$CHOICE" -ge 1 && "$CHOICE" -le ${#OPTIONS[@]} ]]; then
        OPERATION="${OPTIONS[$((CHOICE - 1))]}"
    else
        echo -e "${RED}❗ Invalid selection. Try again.${NC}"
        sleep 1
        show_menu
    fi
}

settings_menu() {
    echo -e "${MAGENTA}⚙ Settings:${NC}"
    echo "  [1] ✏️  Change Username & Email"
    echo "  [2] 🔐 Change Token"
    echo "  [3] 🌿 Change Default Branch"
    echo "  [4] 🔗 Change Remote URL"
    echo "  [5] 🔙 Back"
    read -p "👉 Select option: " SET_CHOICE
    case $SET_CHOICE in
        1) read -p "👤 Username: " U; read -p "✉️ Email: " E
           git config --global user.name "$U"
           git config --global user.email "$E"
           echo "username=$U" > "$CONFIG_FILE"
           echo "email=$E" >> "$CONFIG_FILE"
           ;;
        2) read -s -p "🔐 New Token: " T; echo "$T" > "$TOKEN_FILE"; chmod 600 "$TOKEN_FILE";;
        3) read -p "🌿 Branch: " B; echo "$B" > "$BRANCH_FILE";;
        4) read -p "🔗 Remote URL: " R
           git remote set-url origin "$R" || git remote add origin "$R"
           echo "$R" > "$REMOTE_FILE";;
    esac
}

show_help() {
    echo -e "${MAGENTA}❓ Git Genius Help:${NC}"
    echo -e "${GREEN}Push:${NC} Stage, commit, and push your changes"
    echo -e "${GREEN}Pull:${NC} Fetch and merge from origin"
    echo -e "${GREEN}Status:${NC} Shows current working directory status"
    echo -e "${GREEN}Log:${NC} View commit history (pretty graph)"
    echo -e "${GREEN}Diff:${NC} Show uncommitted changes"
    echo -e "${GREEN}Branch:${NC} Switch or create branches"
    echo -e "${GREEN}.gitignore:${NC} Generates ignore rules"
    echo -e "${GREEN}File History:${NC} Shows file's commit history"
    echo -e "${GREEN}Remote URL:${NC} Show current origin URL"
    echo -e "${GREEN}Settings:${NC} Update config, token, branch, remote"
    echo -e "${GREEN}Reauth:${NC} Shortcut to re-enter token only"
}

reauthenticate_token() {
    echo -e "${CYAN}🔐 Enter GitHub Token:${NC}"
    read -s NEW_TOKEN
    echo "$NEW_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}✔ Token updated.${NC}"
}

# --- CORE FLOW ---

show_header
echo -e "${YELLOW}⚡ Version: $VERSION | Checking dependencies...${NC}"
ensure_git_installed
check_internet
[ ! -f "$CONFIG_FILE" ] && setup_config
validate_git_repo_directory
initialize_git_settings

LAST_COMMIT=$(git log -1 --pretty=format:"%h - %s by %an")
echo -e "${MAGENTA}🔂 Last Commit:${NC} $LAST_COMMIT"

while true; do
    show_menu
    case "$OPERATION" in
        "🔼 Push Changes")
            git add .
            git diff --cached --quiet && git diff --quiet && {
                echo -e "${YELLOW}⚠ Nothing to commit.${NC}"
            } || {
                git status -s
                read -p "✏️  Commit message: " MSG
                git commit -m "$MSG"
                git remote set-url origin "$AUTH_REMOTE"
                git push origin HEAD:"$BRANCH" && echo -e "${GREEN}✔ Push success.${NC}" || echo -e "${RED}✘ Push failed.${NC}"
                git remote set-url origin "$REMOTE_URL"
            }
            ;;
        "🔽 Pull Latest")
            git remote set-url origin "$AUTH_REMOTE"
            git pull origin "$BRANCH" && echo -e "${GREEN}✔ Pull success.${NC}" || echo -e "${RED}✘ Pull failed.${NC}"
            git remote set-url origin "$REMOTE_URL"
            ;;
        "🔍 View Status") git status ;;
        "📝 View Log") git log --oneline --graph --decorate -n 10 ;;
        "🧾 View Diff") git diff | less ;;
        "🌿 Switch/Create Branch")
            git branch
            read -p "🌱 Branch name: " B
            git checkout -B "$B"
            echo "$B" > "$BRANCH_FILE"
            ;;
        "📦 Generate .gitignore")
            [ -f .gitignore ] && cp .gitignore .gitignore.bak
            echo -e "# .gitignore\n*.iml\n.gradle/\nbuild/\n.idea/\n*.log\n.DS_Store\n.env" > .gitignore
            echo -e "${GREEN}✔ .gitignore updated.${NC}"
            ;;
        "👀 View File History")
            read -p "📄 File path: " FILE
            [ -f "$FILE" ] && git log --follow "$FILE" || echo -e "${RED}✘ File not found.${NC}"
            ;;
        "🔗 Show Remote URL") echo -e "${CYAN}Remote:${NC} $REMOTE_URL" ;;
        "⚙ Settings") settings_menu ;;
        "🔐 Reauthenticate") reauthenticate_token ;;
        "❓ Help") show_help ;;
        "❌ Exit") echo -e "${YELLOW}👋 Exiting Git Genius. Goodbye!${NC}"; exit 0 ;;
    esac
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    sleep 1
done