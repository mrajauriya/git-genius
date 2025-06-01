#!/bin/bash

# Git Genius v4.7 – Developer-Focused GitHub CLI

GIT_DIR=".git"
GENIUS_DIR="$GIT_DIR/.genius"
CONFIG_FILE="$GENIUS_DIR/config"
TOKEN_FILE="$GENIUS_DIR/token"
BRANCH_FILE="$GENIUS_DIR/branch"
REMOTE_FILE="$GENIUS_DIR/remote"
VERSION="v4.7"

# Terminal colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
NC="\033[0m"

trap 'echo -e "\n${YELLOW}👋 Exiting Git Genius. Goodbye!${NC}"; exit 0' SIGINT

ensure_git_installed() {
    command -v git &>/dev/null || {
        echo -e "${RED}❌ Git not installed!${NC}"
        echo -e "${YELLOW}📦 Installing Git...${NC}"
        if command -v pkg &>/dev/null; then
            pkg install git -y
        elif command -v apt &>/dev/null; then
            sudo apt update && sudo apt install git -y
        else
            echo -e "${RED}⚠ Unsupported package manager.${NC}"
            exit 1
        fi
    }
    command -v gh &>/dev/null || echo -e "${YELLOW}⚠ GitHub CLI (gh) not found. Release features may be limited.${NC}"
}

check_internet() {
    curl -s https://github.com &>/dev/null || {
        echo -e "${RED}❌ No internet connection!${NC}"
        exit 1
    }
}

show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${CYAN}✨ GitHub CLI – Git Genius $VERSION ✨${BLUE}"
    echo -e "     ${MAGENTA}Crafted with ♥ by moHaN-ShaArmA${BLUE}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

setup_genius_dir() {
    mkdir -p "$GENIUS_DIR"
}

setup_config() {
    echo -e "${YELLOW}⚙ First-time Setup:${NC}"
    read -p "🧑 Username: " GITHUB_USER
    read -p "✉️  Email: " GITHUB_EMAIL
    git config --global user.name "$GITHUB_USER"
    git config --global user.email "$GITHUB_EMAIL"
    echo "username=$GITHUB_USER" > "$CONFIG_FILE"
    echo "email=$GITHUB_EMAIL" >> "$CONFIG_FILE"

    echo -e "${CYAN}🔑 Enter GitHub Personal Access Token (PAT):${NC}"
    echo -e "${MAGENTA}📌 Token must have 'repo' and 'workflow' scopes for full access.${NC}"
    read -s TOKEN
    echo "$TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}✔ Token saved for this repo.${NC}"
}

validate_git_repo_directory() {
    if [ ! -d .git ]; then
        echo -e "${RED}❌ Not a Git repository!${NC}"
        echo -e "${YELLOW}💡 Use 'git init' or clone a repo.${NC}"
        exit 1
    fi

    [ ! -d "$GENIUS_DIR" ] && setup_genius_dir

    if [ -f "$REMOTE_FILE" ]; then
        CONFIGURED_REMOTE=$(cat "$REMOTE_FILE")
        ACTUAL_REMOTE=$(git remote get-url origin 2>/dev/null)
        REPO_NAME=$(basename -s .git "$CONFIGURED_REMOTE")
        CURRENT_DIR_NAME=$(basename "$PWD")

        if [[ "$CONFIGURED_REMOTE" != "$ACTUAL_REMOTE" ]]; then
            echo -e "${RED}⚠ Remote mismatch!${NC}"
            echo -e "${CYAN}Expected: $CONFIGURED_REMOTE"
            echo -e "Found:    $ACTUAL_REMOTE${NC}"
            echo -e "${YELLOW}💡 Redirecting to Settings...${NC}"
            sleep 1
            settings_menu
        elif [[ "$CURRENT_DIR_NAME" != "$REPO_NAME" ]]; then
            echo -e "${RED}⚠ Folder name mismatch!${NC}"
            echo -e "${CYAN}Expected: $REPO_NAME"
            echo -e "Found:    $CURRENT_DIR_NAME${NC}"
            echo -e "${YELLOW}💡 Fix it manually or update remote.${NC}"
            sleep 1
            settings_menu
        fi
    fi
}

initialize_git_settings() {
    [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
    username=${username:-$(git config user.name)}
    email=${email:-$(git config user.email)}

    TOKEN=$(cat "$TOKEN_FILE" 2>/dev/null)
    BRANCH=$(cat "$BRANCH_FILE" 2>/dev/null)
    REMOTE_URL=$(cat "$REMOTE_FILE" 2>/dev/null)

    [ -z "$BRANCH" ] && {
        BRANCH=$(git remote show origin 2>/dev/null | grep 'HEAD branch' | awk '{print $NF}')
        BRANCH=${BRANCH:-main}
        echo "$BRANCH" > "$BRANCH_FILE"
    }

    git config --global --add safe.directory "$(pwd)"

    if [ -z "$REMOTE_URL" ]; then
        read -p "🔗 GitHub repo URL (https://github.com/user/repo.git): " REMOTE_URL
        git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
        echo "$REMOTE_URL" > "$REMOTE_FILE"
    fi

    AUTH_REMOTE=$(echo "$REMOTE_URL" | sed "s|https://|https://$username:$TOKEN@|")
}

show_menu() {
    echo -e "\n${CYAN}🚀 Choose operation:${NC}"
    OPTIONS=(
        "🔼 Push Changes" "🔽 Pull Latest" "🔍 View Status" "📝 View Log"
        "🧾 View Diff" "🔎 View Staged Diff" "🌿 Switch/Create Branch"
        "📦 Generate .gitignore" "👀 View File History" "🔗 Show Remote URL"
        "🏷️ Create & Push Tag" "🚀 Create GitHub Release" "⚙ Settings"
        "🔐 Reauthenticate" "🧼 Clean Genius Config" "❓ Help" "❌ Exit"
    )
    for i in "${!OPTIONS[@]}"; do echo "  [$((i+1))] ${OPTIONS[$i]}"; done
    read -p "👉 Your choice (1-${#OPTIONS[@]}): " CHOICE
    OPERATION="${OPTIONS[$((CHOICE - 1))]}"
}
execute_action() {
    case "$OPERATION" in
        *"Push Changes"*)
            git add .
            read -p "📝 Commit message: " MSG
            git commit -m "$MSG" && git push origin "$BRANCH"
            ;;

        *"Pull Latest"*)
            git pull origin "$BRANCH"
            ;;

        *"View Status"*)
            git status
            ;;

        *"View Log"*)
            git log --oneline --graph --decorate
            ;;

        *"View Diff"*)
            git diff
            ;;

        *"View Staged Diff"*)
            git diff --cached
            ;;

        *"Switch/Create Branch"*)
            read -p "🌿 Enter branch name: " NEW_BRANCH
            git checkout -B "$NEW_BRANCH"
            echo "$NEW_BRANCH" > "$BRANCH_FILE"
            ;;

        *"Generate .gitignore"*)
            echo -e "# Ignore OS junk\n.DS_Store\nThumbs.db" > .gitignore
            echo -e "# Ignore IDE/editor config\n.vscode/\n.idea/" >> .gitignore
            echo -e "# Ignore build artifacts\nbuild/\n*.apk\n*.exe" >> .gitignore
            echo -e "${GREEN}✔ .gitignore created.${NC}"
            ;;

        *"View File History"*)
            read -p "📂 File name to view history: " FILE
            git log --follow -- "$FILE"
            ;;

        *"Show Remote URL"*)
            echo -e "${CYAN}🔗 Remote: ${NC}$(git remote get-url origin)"
            ;;

        *"Create & Push Tag"*)
            read -p "🏷️  Tag name (e.g., v1.0.0): " TAG
            git tag "$TAG"
            git push origin "$TAG"
            echo -e "${GREEN}✔ Tag $TAG pushed to remote.${NC}"
            ;;

        *"Create GitHub Release"*)
            if command -v gh &>/dev/null; then
                read -p "🏷️  Release tag (e.g., v1.0.0): " TAG
                read -p "📄 Release title: " TITLE
                read -p "📝 Description (optional): " DESC
                gh release create "$TAG" -t "$TITLE" -n "$DESC"
            else
                echo -e "${RED}❌ GitHub CLI (gh) not installed.${NC}"
                echo -e "${YELLOW}🔧 Install it to use release features.${NC}"
            fi
            ;;

        *"Settings"*)
            settings_menu
            ;;

        *"Reauthenticate"*)
            echo -e "${YELLOW}🔁 Re-authentication...${NC}"
            rm -f "$TOKEN_FILE"
            setup_config
            ;;

        *"Clean Genius Config"*)
            echo -e "${RED}⚠ Deleting all saved config for this repo...${NC}"
            rm -rf "$GENIUS_DIR"
            echo -e "${GREEN}✔ Done. Run again to reconfigure.${NC}"
            exit 0
            ;;

        *"Help"*)
            echo -e "${MAGENTA}"
            echo "📘 Git Genius Help"
            echo "--------------------"
            echo "1. Push = add + commit + push to current branch."
            echo "2. Tag = create + push version tags (e.g., v1.2.3)."
            echo "3. Release = create GitHub releases (needs gh CLI)."
            echo "4. .gitignore = auto generates base ignore rules."
            echo "5. Settings = change saved name/email/token/remote."
            echo "6. All config is repo-specific, stored in .git/.genius"
            echo "7. Directory must match remote repo name."
            echo -e "${NC}"
            ;;

        *"Exit"*)
            echo -e "${YELLOW}👋 Exiting...${NC}"
            exit 0
            ;;

        *)
            echo -e "${RED}❌ Invalid choice!${NC}"
            ;;
    esac
}

settings_menu() {
    echo -e "\n${CYAN}⚙ Settings Menu:${NC}"
    echo "1. Change Name & Email"
    echo "2. Change GitHub Token"
    echo "3. Change Remote URL"
    echo "4. Back to Main Menu"
    read -p "👉 Your choice (1-4): " SETTING_CHOICE

    case "$SETTING_CHOICE" in
        1)
            read -p "🧑 New Name: " NEW_NAME
            read -p "✉️  New Email: " NEW_EMAIL
            git config --global user.name "$NEW_NAME"
            git config --global user.email "$NEW_EMAIL"
            echo "username=$NEW_NAME" > "$CONFIG_FILE"
            echo "email=$NEW_EMAIL" >> "$CONFIG_FILE"
            echo -e "${GREEN}✔ Name and email updated.${NC}"
            ;;
        2)
            read -p "🔑 New GitHub Token: " NEW_TOKEN
            echo "$NEW_TOKEN" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
            echo -e "${GREEN}✔ Token updated.${NC}"
            ;;
        3)
            read -p "🔗 New Remote URL: " NEW_REMOTE
            git remote set-url origin "$NEW_REMOTE"
            echo "$NEW_REMOTE" > "$REMOTE_FILE"
            echo -e "${GREEN}✔ Remote updated.${NC}"
            ;;
        4)
            echo -e "${YELLOW}↩ Returning to main menu...${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid option!${NC}"
            ;;
    esac
}

# 🚀 Launch Flow
ensure_git_installed
check_internet
validate_git_repo_directory

if [ ! -f "$CONFIG_FILE" ] || [ ! -f "$TOKEN_FILE" ]; then
    setup_config
fi

initialize_git_settings
show_header

while true; do
    show_menu
    execute_action
done