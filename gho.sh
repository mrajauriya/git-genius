#!/bin/bash

# Git Genius v5.0 – Developer-Focused GitHub CLI Toolkit
# Author: moHaN-ShaArmA
# Features: Offline mode, GPG commit signing, PAT validation, interactive commit picker, GUI-ready

VERSION="v5.0"
GIT_DIR=".git"
GENIUS_DIR="$GIT_DIR/.genius"
CONFIG_FILE="$GENIUS_DIR/config"
TOKEN_FILE="$GENIUS_DIR/token"
BRANCH_FILE="$GENIUS_DIR/branch"
REMOTE_FILE="$GENIUS_DIR/remote"
BACKUP_FILE="$GENIUS_DIR/config.backup"

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
BLUE="\033[1;34m"
BOLD="\033[1m"
MAGENTA="\033[1;35m"
NC="\033[0m"

trap 'echo -e "\n${YELLOW}👋 Exiting Git Genius. Goodbye!${NC}"; exit 0' SIGINT

# ------------ Prerequisite Checks ------------
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
    command -v gh &>/dev/null || echo -e "${YELLOW}⚠ GitHub CLI (gh) not found. Some features disabled.${NC}"
}

check_internet() {
    if ! curl -s https://github.com &>/dev/null; then
        echo -e "${YELLOW}⚠ No internet detected. Offline mode enabled.${NC}"
        ONLINE_MODE=false
    else
        ONLINE_MODE=true
    fi
}

validate_token() {
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(<"$TOKEN_FILE")
        if $ONLINE_MODE; then
            VALID=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | grep login)
            if [[ -z "$VALID" ]]; then
                echo -e "${RED}❌ Invalid or expired GitHub token.${NC}"
                rm -f "$TOKEN_FILE"
                setup_config
            fi
        fi
    fi
}

# ------------ Setup / Config ------------
setup_genius_dir() {
    mkdir -p "$GENIUS_DIR"
}

backup_config() {
    cp "$CONFIG_FILE" "$BACKUP_FILE" 2>/dev/null
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
    echo -e "${MAGENTA}📌 Token must have 'repo' and 'workflow' scopes.${NC}"
    read -s TOKEN
    echo "$TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}✔ Token saved.${NC}"
}

validate_git_repo_directory() {
    if [ ! -d "$GIT_DIR" ]; then
        echo -e "${RED}❌ Not a Git repository!${NC}"
        echo -e "${YELLOW}💡 Use 'git init' or clone a repo.${NC}"
        exit 1
    fi

    [ ! -d "$GENIUS_DIR" ] && setup_genius_dir

    if [ -f "$REMOTE_FILE" ]; then
        CONFIGURED_REMOTE=$(<"$REMOTE_FILE")
        ACTUAL_REMOTE=$(git remote get-url origin 2>/dev/null)
        REPO_NAME=$(basename -s .git "$CONFIGURED_REMOTE")
        CURRENT_DIR_NAME=$(basename "$PWD")

        if [[ "$CONFIGURED_REMOTE" != "$ACTUAL_REMOTE" ]]; then
            echo -e "${RED}⚠ Remote mismatch!${NC}"
            echo -e "${CYAN}Expected: $CONFIGURED_REMOTE"
            echo -e "Found:    $ACTUAL_REMOTE${NC}"
            echo -e "${YELLOW}💡 Fixing it in settings...${NC}"
            settings_menu
        elif [[ "$CURRENT_DIR_NAME" != "$REPO_NAME" ]]; then
            echo -e "${RED}⚠ Folder name mismatch!${NC}"
            echo -e "${CYAN}Expected: $REPO_NAME"
            echo -e "Found:    $CURRENT_DIR_NAME${NC}"
            echo -e "${YELLOW}💡 Please rename folder or adjust remote.${NC}"
            settings_menu
        fi
    fi
}

# ------------ Main Execution Entry Point ------------
show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "  ${CYAN}✨ GitHub CLI – Git Genius $VERSION ✨${BLUE}"
    echo -e "     ${MAGENTA}Crafted with ♥ by moHaN-ShaArmA${BLUE}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ------------ Commit Helpers ------------
interactive_commit_picker() {
    echo -e "${CYAN}📝 Choose a commit type:"
    PS3="> "
    select type in "✨ feat" "🐛 fix" "📚 docs" "🎨 style" "🧪 test" "⚙️ chore" "🔀 merge" "⏪ revert" "Custom"; do
        case $REPLY in
            1) TYPE="✨ feat"; break ;;
            2) TYPE="🐛 fix"; break ;;
            3) TYPE="📚 docs"; break ;;
            4) TYPE="🎨 style"; break ;;
            5) TYPE="🧪 test"; break ;;
            6) TYPE="⚙️ chore"; break ;;
            7) TYPE="🔀 merge"; break ;;
            8) TYPE="⏪ revert"; break ;;
            9) read -p "🔤 Custom type: " TYPE; break ;;
            *) echo -e "${RED}❌ Invalid choice.${NC}" ;;
        esac
    done
    read -p "🗒 Commit message: " MSG
    echo "$TYPE: $MSG"
}

make_commit() {
    git add .
    COMMIT_MSG=$(interactive_commit_picker)
    echo -e "${YELLOW}🔐 Sign commit with GPG? (y/n)${NC}"
    read -r SIGN

    if [[ "$SIGN" == "y" ]]; then
        git commit -S -m "$COMMIT_MSG"
    else
        git commit -m "$COMMIT_MSG"
    fi
}

# ------------ Core Git Actions ------------
push_code() {
    echo -e "${CYAN}🚀 Pushing changes..."
    if $ONLINE_MODE; then
        git push origin "$(get_branch)"
    else
        echo -e "${RED}❌ Offline! Push skipped.${NC}"
    fi
}

pull_code() {
    echo -e "${CYAN}📥 Pulling latest changes..."
    if $ONLINE_MODE; then
        git pull origin "$(get_branch)"
    else
        echo -e "${RED}❌ Offline! Pull skipped.${NC}"
    fi
}

get_branch() {
    if [ -f "$BRANCH_FILE" ]; then
        cat "$BRANCH_FILE"
    else
        git rev-parse --abbrev-ref HEAD
    fi
}

git_status() {
    echo -e "${CYAN}📊 Git Status:"
    git status
}

# ------------ Settings / Config Options ------------
settings_menu() {
    echo -e "${CYAN}⚙ Settings:"
    PS3="Select an option: "
    select opt in "Set Remote" "Change Branch" "Edit User Info" "View Config" "Back"; do
        case $REPLY in
            1)
                read -p "🌐 Enter remote URL: " REMOTE
                git remote remove origin 2>/dev/null
                git remote add origin "$REMOTE"
                echo "$REMOTE" > "$REMOTE_FILE"
                ;;
            2)
                read -p "🌿 Enter branch name: " BRANCH
                git checkout -B "$BRANCH"
                echo "$BRANCH" > "$BRANCH_FILE"
                ;;
            3)
                read -p "🧑 New username: " NAME
                read -p "✉️  New email: " EMAIL
                git config --global user.name "$NAME"
                git config --global user.email "$EMAIL"
                sed -i "s/^username=.*/username=$NAME/" "$CONFIG_FILE"
                sed -i "s/^email=.*/email=$EMAIL/" "$CONFIG_FILE"
                ;;
            4)
                echo -e "${CYAN}🔍 Current config:"
                cat "$CONFIG_FILE"
                echo -e "Remote: $(<"$REMOTE_FILE")"
                echo -e "Branch: $(<"$BRANCH_FILE")"
                ;;
            5) break ;;
            *) echo -e "${RED}❌ Invalid option.${NC}" ;;
        esac
    done
}

# ------------ GUI Stub for Future Enhancement ------------
launch_gui() {
    if command -v yad &>/dev/null; then
        yad --form --title="Git Genius GUI" \
            --text="This is a placeholder GUI." \
            --field="Commit message" \
            --field="Push to origin:CHK" "" TRUE
    else
        echo -e "${YELLOW}💡 GUI support (YAD) not installed.${NC}"
    fi
}
# ------------ Multi-repo Dashboard ------------
multi_repo_dashboard() {
    echo -e "${CYAN}📂 Multi-Repo Dashboard"
    read -p "📁 Enter parent directory of repos: " DIR

    if [[ ! -d "$DIR" ]]; then
        echo -e "${RED}❌ Invalid directory.${NC}"
        return
    fi

    ORIGINAL_DIR=$(pwd)
    REPO_COUNT=0

    for repo in "$DIR"/*; do
        if [[ -d "$repo/.git" ]]; then
            REPO_COUNT=$((REPO_COUNT + 1))
            echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo -e "📌 Repo: ${GREEN}${repo}${NC}"
            cd "$repo" || continue

            BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
            echo -e "🔀 Branch: ${YELLOW}${BRANCH}${NC}"

            # Show last commit info
            LAST_COMMIT=$(git log -1 --pretty=format:"%C(cyan)%s%Creset by %C(green)%an%Creset on %C(yellow)%ad%Creset" --date=short)
            echo -e "🕒 Last Commit: $LAST_COMMIT"

            # Git status
            STATUS=$(git status --porcelain)
            if [[ -z "$STATUS" ]]; then
                echo -e "${GREEN}✔ Clean working tree${NC}"
            else
                echo -e "${RED}⚠ Uncommitted changes present${NC}"
            fi

            # Sync check
            LOCAL=$(git rev-parse @ 2>/dev/null)
            REMOTE=$(git rev-parse @{u} 2>/dev/null)
            BASE=$(git merge-base @ @{u} 2>/dev/null)

            if [[ "$LOCAL" == "$REMOTE" ]]; then
                echo -e "${GREEN}✔ Local and remote in sync${NC}"
            elif [[ "$LOCAL" == "$BASE" ]]; then
                echo -e "${YELLOW}⬇ Behind remote (need pull)${NC}"
            elif [[ "$REMOTE" == "$BASE" ]]; then
                echo -e "${YELLOW}⬆ Ahead of remote (need push)${NC}"
            else
                echo -e "${RED}⚠ Diverged from remote${NC}"
            fi

            cd "$ORIGINAL_DIR"
        fi
    done

    echo -e "\n${CYAN}✅ Dashboard complete. ${REPO_COUNT} repositories scanned.${NC}"
}
# ------------ Git Log Viewer ------------
view_git_log() {
    echo -e "${CYAN}📖 Commit Log:"
    git log --pretty=format:"%C(yellow)%h%Creset - %C(cyan)%an%Creset | %Cgreen%ad%Creset%n%s%n" --date=short -n 10
}

# ------------ Remote Sync Verification ------------
check_sync_status() {
    echo -e "${CYAN}🔃 Checking remote sync..."
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo -e "${GREEN}✔ Local and remote are in sync.${NC}"
    elif [ "$LOCAL" = "$BASE" ]; then
        echo -e "${YELLOW}⬇ Need to pull.${NC}"
    elif [ "$REMOTE" = "$BASE" ]; then
        echo -e "${YELLOW}⬆ Need to push.${NC}"
    else
        echo -e "${RED}⚠️ Local and remote have diverged.${NC}"
    fi
}

# ------------ Main Menu ------------
main_menu() {
    echo -e "${BOLD}${CYAN}
███████╗██╗ ██████╗     ██████╗ ███████╗███╗   ██╗██╗██╗   ██╗███████╗
██╔════╝██║██╔════╝     ██╔══██╗██╔════╝████╗  ██║██║██║   ██║██╔════╝
█████╗  ██║██║  ███╗    ██████╔╝█████╗  ██╔██╗ ██║██║██║   ██║███████╗
██╔══╝  ██║██║   ██║    ██╔═══╝ ██╔══╝  ██║╚██╗██║██║╚██╗ ██╔╝╚════██║
██║     ██║╚██████╔╝    ██║     ███████╗██║ ╚████║██║ ╚████╔╝ ███████║
╚═╝     ╚═╝ ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═══╝  ╚══════╝
${NC}"

    while true; do
        echo -e "${BLUE}🧠 What do you want to do?"
        PS3="> "
        select opt in "📝 Commit" "🚀 Push" "📥 Pull" "📊 Status" "📖 View Log" "🔃 Check Sync" "🛠 Settings" "📂 Multi-Repo Dashboard" "🖼 GUI (YAD)" "Exit"; do
            case $REPLY in
                1) make_commit ;;
                2) push_code ;;
                3) pull_code ;;
                4) git_status ;;
                5) view_git_log ;;
                6) check_sync_status ;;
                7) settings_menu ;;
                8) multi_repo_dashboard ;;
                9) launch_gui ;;
                10) echo -e "${MAGENTA}👋 Exiting Git Genius!"; exit ;;
                *) echo -e "${RED}❌ Invalid choice.${NC}" ;;
            esac
            break
        done
    done
}

# ------------ Start Script ------------
setup_genius_dir
ensure_git_installed
check_internet
validate_git_repo_directory
validate_token
show_header
main_menu
