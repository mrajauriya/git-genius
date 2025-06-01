#!/bin/bash
# Git Genius v5.0 – Developer-Focused GitHub CLI Toolkit
# Author: moHaN-ShaArmA (Refactored by ChatGPT)
# Purpose: Enhanced robustness, clarity, maintainability, and usability

# ------------------- CONSTANTS & FILE PATHS -------------------

readonly VERSION="v5.0"
readonly GIT_DIR=".git"
readonly GENIUS_DIR="$GIT_DIR/.genius"
readonly CONFIG_FILE="$GENIUS_DIR/config"
readonly TOKEN_FILE="$GENIUS_DIR/token"
readonly BRANCH_FILE="$GENIUS_DIR/branch"
readonly REMOTE_FILE="$GENIUS_DIR/remote"
readonly BACKUP_FILE="$GENIUS_DIR/config.backup"
readonly ERROR_LOG="$GENIUS_DIR/error.log"

# ------------------- COLORS FOR UI -------------------

readonly GREEN="\033[1;32m"
readonly YELLOW="\033[1;33m"
readonly RED="\033[1;31m"
readonly CYAN="\033[1;36m"
readonly BLUE="\033[1;34m"
readonly BOLD="\033[1m"
readonly MAGENTA="\033[1;35m"
readonly NC="\033[0m"  # No Color

# ------------------- TRAP HANDLERS -------------------

# Handle SIGINT (Ctrl+C) gracefully
trap 'echo -e "\n${YELLOW}👋 Exiting Git Genius. Goodbye!${NC}"; exit 0' SIGINT

# Handle errors and log them
trap 'error_handler ${LINENO}' ERR

error_handler() {
    local lineno=$1
    echo -e "${RED}💥 Error occurred at line $lineno. See $ERROR_LOG for details.${NC}"
    echo "[$(date)] Error at line $lineno in script execution." >> "$ERROR_LOG"
    exit 1
}

# ------------------- DEBUG MODE -------------------

DEBUG_MODE=false

debug_log() {
    if $DEBUG_MODE; then
        echo -e "${MAGENTA}[DEBUG] $*${NC}"
    fi
}

# ------------------- UTILITY FUNCTIONS -------------------

# Print separator for UI clarity
print_separator() {
    echo -e "${MAGENTA}────────────────────────────────────────────${NC}"
}

# Colored info message with icon
info_msg() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Colored success message with icon
success_msg() {
    echo -e "${GREEN}✔ $1${NC}"
}

# Colored error message with icon
error_msg() {
    echo -e "${RED}✘ $1${NC}"
}

# Prompt for confirmation (yes/no)
confirm_action() {
    while true; do
        read -rp "$1 (y/n): " yn
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Validate that string is a valid branch or remote name (basic alphanumeric, dash, underscore)
validate_name() {
    local name=$1
    if [[ "$name" =~ ^[A-Za-z0-9._/-]+$ ]]; then
        return 0
    else
        error_msg "Invalid name: '$name'. Allowed characters: letters, numbers, dot, underscore, dash, slash."
        return 1
    fi
}

# Validate URL format (simple regex, not 100% accurate but practical)
validate_url() {
    local url=$1
    if [[ "$url" =~ ^(https?|git|ssh):// ]]; then
        return 0
    else
        error_msg "Invalid URL format: '$url'. Must start with http(s)://, git://, or ssh://"
        return 1
    fi
}
# ------------------- PART 2: INITIALIZATION FUNCTIONS -------------------

# Ensure we are inside a Git repository
# Load token, branch, and remote from genius config files into variables
load_config() {
    if [ -f "$TOKEN_FILE" ]; then
        TOKEN=$(<"$TOKEN_FILE")
    else
        TOKEN=""
    fi

    if [ -f "$BRANCH_FILE" ]; then
        BRANCH=$(<"$BRANCH_FILE")
    else
        BRANCH="main"
    fi

    if [ -f "$REMOTE_FILE" ]; then
        REMOTE=$(<"$REMOTE_FILE")
    else
        REMOTE="origin"
    fi

    debug_log "Config loaded: Branch=$BRANCH, Remote=$REMOTE, Token set=$( [ -n "$TOKEN" ] && echo "yes" || echo "no" )"
}

ensure_git_repo() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        error_msg "This script must be run inside a Git repository."
        exit 1
    fi
    debug_log "Confirmed inside a Git repository."
}

# Ensure git and optionally gh CLI installed, attempt to install git if missing
ensure_git_installed() {
    if ! command -v git &>/dev/null; then
        error_msg "Git is not installed!"
        echo -e "${YELLOW}Attempting to install Git...${NC}"
        if command -v pkg &>/dev/null; then
            sudo pkg install git -y || {
                error_msg "Failed to install Git via pkg."
                exit 1
            }
        elif command -v apt &>/dev/null; then
            sudo apt update && sudo apt install git -y || {
                error_msg "Failed to install Git via apt."
                exit 1
            }
        else
            error_msg "Unsupported package manager. Please install Git manually."
            exit 1
        fi
        success_msg "Git installed successfully."
    else
        debug_log "Git is installed."
    fi

    if ! command -v gh &>/dev/null; then
        info_msg "GitHub CLI (gh) not found. Some features will be disabled."
    else
        debug_log "GitHub CLI is installed."
    fi
}

# Check internet connectivity (ping GitHub)
check_internet() {
    if curl -s --head https://github.com >/dev/null 2>&1; then
        ONLINE_MODE=true
        debug_log "Internet connectivity detected."
    else
        ONLINE_MODE=false
        info_msg "No internet detected. Offline mode enabled."
    fi
}

# Initialize genius directory and config files if not present
init_genius_directory() {
    if [ ! -d "$GENIUS_DIR" ]; then
        mkdir -p "$GENIUS_DIR"
        success_msg "Created genius directory at $GENIUS_DIR"
    fi

    # Create config file if missing
    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE"
        debug_log "Created config file."
    fi

    # Create token file if missing
    if [ ! -f "$TOKEN_FILE" ]; then
        touch "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"  # Secure token file permissions
        debug_log "Created and secured token file."
    fi

    # Set default branch file if missing
    if [ ! -f "$BRANCH_FILE" ]; then
        echo "main" > "$BRANCH_FILE"
        debug_log "Default branch set to 'main'."
    fi

    # Set default remote file if missing
    if [ ! -f "$REMOTE_FILE" ]; then
        echo "origin" > "$REMOTE_FILE"
        debug_log "Default remote set to 'origin'."
    fi

    # Create or reset error log file
    if [ ! -f "$ERROR_LOG" ]; then
        touch "$ERROR_LOG"
        debug_log "Error log created."
    fi
}
# ------------------- PART 3: TOKEN MANAGEMENT -------------------

# Prompt user securely for GitHub Personal Access Token
prompt_token() {
    while true; do
        echo -e "${CYAN}🔐 Enter your GitHub Personal Access Token (repo scope required):${NC}"
        read -rsp "Token: " token
        echo
        if [ -z "$token" ]; then
            error_msg "Token cannot be empty. Please try again."
        else
            echo "$token" > "$TOKEN_FILE"
            chmod 600 "$TOKEN_FILE"
            success_msg "✅ Token saved successfully."
            break
        fi
    done
}
# Validate token by calling GitHub API for user info
validate_token() {
    if [ ! -f "$TOKEN_FILE" ]; then
        info_msg "No token file found. Please set your GitHub token."
        prompt_token
    fi

    TOKEN=$(<"$TOKEN_FILE")
    if [ -z "$TOKEN" ]; then
        info_msg "Token file empty. Please set your GitHub token."
        prompt_token
    fi

    if [ "$ONLINE_MODE" = true ]; then
        # Query GitHub API for user login, suppress errors
        user=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | grep '"login"' | awk -F '"' '{print $4}')
        if [ -z "$user" ]; then
            error_msg "❌ Invalid or expired GitHub token."
            rm -f "$TOKEN_FILE"
            prompt_token
        else
            success_msg "GitHub token validated for user: $user"
        fi
    else
        info_msg "Offline mode detected; token validation skipped."
    fi
}
# ------------------- PART 4: BRANCH & REMOTE SETUP & MANAGEMENT -------------------

# Prompt user to set default branch and remote, with defaults
setup_branch_and_remote() {
    echo -e "${CYAN}🔀 Default branch name (default: main):${NC}"
    read -rp "Branch: " branch
    branch=${branch:-main}
    echo "$branch" > "$BRANCH_FILE"

    echo -e "${CYAN}🌐 Git remote name (default: origin):${NC}"
    read -rp "Remote: " remote
    remote=${remote:-origin}
    echo "$remote" > "$REMOTE_FILE"
    read -p "🔑 New GitHub Token: " NEW_TOKEN
    echo "$NEW_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo -e "${GREEN}✔ Token updated.${NC}"
            

    success_msg "✅ Branch and remote configuration saved."
}

# Show current branch and remote from saved config
show_current_branch_and_remote() {
    [ -f "$BRANCH_FILE" ] && BRANCH=$(<"$BRANCH_FILE") || BRANCH="main"
    [ -f "$REMOTE_FILE" ] && REMOTE=$(<"$REMOTE_FILE") || REMOTE="origin"
    echo -e "${BOLD}Current branch:${NC} $BRANCH"
    echo -e "${BOLD}Current remote:${NC} $REMOTE"
}


# Switch git branch, create if doesn't exist, save to config
switch_branch() {
    echo -e "${CYAN}Enter new branch name to switch to:${NC}"
    read -rp "Branch: " new_branch
    if [ -z "$new_branch" ]; then
        error_msg "Branch name cannot be empty."
        return 1
    fi

    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/"$new_branch"; then
        git checkout "$new_branch" && echo "$new_branch" > "$BRANCH_FILE" && success_msg "Switched to existing branch $new_branch"
    else
        if confirm_action "Branch $new_branch does not exist locally. Create and switch?"; then
            git checkout -b "$new_branch" && echo "$new_branch" > "$BRANCH_FILE" && success_msg "Created and switched to new branch $new_branch"
        else
            error_msg "Branch switch aborted."
        fi
    fi
}

# Switch git remote, add if missing, save to config
switch_remote() {
    echo -e "${CYAN}Enter new remote name to use:${NC}"
    read -rp "Remote: " new_remote
    if [ -z "$new_remote" ]; then
        error_msg "Remote name cannot be empty."
        return 1
    fi

    if git remote | grep -q "^$new_remote$"; then
        echo "$new_remote" > "$REMOTE_FILE"
        success_msg "Remote switched to $new_remote"
    else
        if confirm_action "Remote $new_remote not found. Add it?"; then
            read -rp "Enter remote URL: " remote_url
            if [ -z "$remote_url" ]; then
                error_msg "Remote URL cannot be empty."
                return 1
            fi
            git remote add "$new_remote" "$remote_url" && echo "$new_remote" > "$REMOTE_FILE" && success_msg "Remote $new_remote added and selected."
        else
            error_msg "Remote switch aborted."
        fi
    fi
}
# ------------------- PART 5: GIT OPERATIONS -------------------

# Git push changes with commit message; handles empty commits gracefully
git_push_changes() {
    git add .
    if ! git commit -m "$1"; then
        error_msg "Commit failed. Are there changes to commit?"
        return 1
    fi

    if git push "$REMOTE" "$BRANCH"; then
        success_msg "Changes pushed successfully to $REMOTE/$BRANCH."
    else
        error_msg "Push failed. Check your network or Git setup."
    fi
}

# Git pull changes with fetch + merge; detects conflicts and shows conflicted files
git_pull_changes() {
    info_msg "Fetching latest changes from $REMOTE/$BRANCH..."
    git fetch "$REMOTE" "$BRANCH"
    if [ $? -ne 0 ]; then
        error_msg "Failed to fetch from remote $REMOTE. Check your network or remote configuration."
        return 1
    fi

    info_msg "Merging $REMOTE/$BRANCH into local $BRANCH..."
    git merge "$REMOTE/$BRANCH"
    local merge_status=$?

    if [ $merge_status -eq 0 ]; then
        success_msg "Successfully pulled and merged latest changes."
    elif [ $merge_status -eq 1 ]; then
        error_msg "Merge conflict detected! Please resolve conflicts manually."
        git diff --name-only --diff-filter=U
    else
        error_msg "Merge failed with status code $merge_status."
    fi
}

# Git fetch all remotes
git_fetch_changes() {
    info_msg "Fetching all remotes..."
    git fetch --all
    if [ $? -eq 0 ]; then
        success_msg "Fetch completed successfully."
    else
        error_msg "Fetch failed. Check your network or remote settings."
    fi
}

# Show git status for current branch
git_status() {
    info_msg "Git status for branch $BRANCH:"
    git status
}

# ------------------- MAIN MENU -------------------

main_menu() {
    clear
    echo -e "${BOLD}${CYAN}
███████╗██╗ ██████╗     ██████╗ ███████╗███╗   ██╗██╗██╗   ██╗███████╗
██╔════╝██║██╔════╝     ██╔══██╗██╔════╝████╗  ██║██║██║   ██║██╔════╝
█████╗  ██║██║  ███╗    ██████╔╝█████╗  ██╔██╗ ██║██║██║   ██║███████╗
██╔══╝  ██║██║   ██║    ██╔═══╝ ██╔══╝  ██║╚██╗██║██║╚██╗ ██╔╝╚════██║
██║     ██║╚██████╔╝    ██║     ███████╗██║ ╚████║██║ ╚████╔╝ ███████║
╚═╝     ╚═╝ ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═══╝  ╚══════╝
${NC}"
    print_separator
    show_current_branch_and_remote
    print_separator

    echo -e "${CYAN}Select an option:${NC}"
    echo "1) Switch Branch"
    echo "2) Switch Remote"
    echo "3) Validate GitHub Token"
    echo "4) Push Changes"
    echo "5) Pull Latest Changes"
    echo "6) Fetch All Remotes"
    echo "7) Show Git Status"
    echo "8) Setup / Reconfigure"
    echo "9) Exit"
    print_separator

    read -rp "Enter choice [1-9]: " choice

    case $choice in
        1) switch_branch ;;
        2) switch_remote ;;
        3) validate_token ;;  # Fixed here
        4)
            echo -e "${CYAN}Enter commit message:${NC}"
            read -r commit_msg
            if [ -z "$commit_msg" ]; then
                error_msg "Commit message cannot be empty."
            else
                git_push_changes "$commit_msg"
            fi
            ;;
        5) git_pull_changes ;;
        6) git_fetch_changes ;;
        7) git_status ;;
        8) setup_branch_and_remote ;;  # Fix function call from 'setup_config' to 'setup_branch_and_remote'
        9) echo -e "${YELLOW}Goodbye!${NC}"; exit 0 ;;
        *) error_msg "Invalid option selected." ;;
    esac
    read -rp "Press Enter to continue..."
}
# ------------------- PART 6: MAIN EXECUTION LOOP & ENTRY POINT -------------------

run() {
    ensure_git_installed || { error_msg "Git installation check failed."; exit 1; }
    check_internet          # sets ONLINE_MODE variable
    load_config

    validate_token          # will prompt if token invalid or missing

    # Enter interactive main menu loop
    while true; do
        main_menu
    done
}

# Only execute run() if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run
fi