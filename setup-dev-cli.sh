#!/usr/bin/env bash
set -euo pipefail

DEVCLI="$HOME/.dev-cli"
CONFIG_DIR="$DEVCLI/config"
BIN_DIR="$DEVCLI/bin"
COMMANDS_DIR="$DEVCLI/commands"
LIB_DIR="$DEVCLI/lib"
BACKUP_DIR="$HOME/.dev-cli-backups"

echo "==> Installing dev CLI"

# ------------------------------------------------------------
# Backup existing installation
# ------------------------------------------------------------

if [[ -d "$DEVCLI" ]]; then
  mkdir -p "$BACKUP_DIR"
  BACKUP="$BACKUP_DIR/dev-cli-$(date +%Y%m%d-%H%M%S)"
  echo "Backing up existing installation to:"
  echo "  $BACKUP"
  cp -R "$DEVCLI" "$BACKUP"
fi

# ------------------------------------------------------------
# Create structure
# ------------------------------------------------------------

mkdir -p "$CONFIG_DIR" "$BIN_DIR" "$COMMANDS_DIR" "$LIB_DIR"

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

cat > "$CONFIG_DIR/config.sh" <<'EOF'
#!/usr/bin/env bash

CODEBASE_ROOT="$HOME/codebase"
MAIN_WORKTREE="main"
DEFAULT_BRANCH="main"

OPEN_CURSOR=true
OPEN_INTELLIJ=true
OPEN_WEZTERM=true
EOF

# ------------------------------------------------------------
# UI library
# ------------------------------------------------------------

cat > "$LIB_DIR/ui.sh" <<'EOF'
#!/usr/bin/env bash

green() {
    printf "\033[32m%s\033[0m\n" "$1"
}

yellow() {
    printf "\033[33m%s\033[0m\n" "$1"
}

red() {
    printf "\033[31m%s\033[0m\n" "$1"
}

step() {
    echo
    echo "▶ $1"
}

success() {
    green "✔ $1"
}

error() {
    red "✘ $1"
    exit 1
}
EOF

# ------------------------------------------------------------
# Git library
# ------------------------------------------------------------

cat > "$LIB_DIR/git.sh" <<'EOF'
#!/usr/bin/env bash

source "$HOME/.dev-cli/config/config.sh"
source "$HOME/.dev-cli/lib/ui.sh"

MAIN="$CODEBASE_ROOT/$MAIN_WORKTREE"

ensure_main_exists() {
    git -C "$MAIN" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
        || error "Main worktree is invalid: $MAIN"
}

worktree_exists() {
    local destination="$1"
    [[ -e "$destination" ]]
}

update_branch_worktree() {
    local worktree="$1"
    local branch="$2"

    step "Updating $branch"

    git -C "$worktree" fetch origin

    if git -C "$worktree" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        git -C "$worktree" merge --ff-only "origin/$branch"
    fi

    success "$branch updated"
}
EOF

# ------------------------------------------------------------
# dev entrypoint
# ------------------------------------------------------------

cat > "$BIN_DIR/dev" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

DEVCLI="$HOME/.dev-cli"

source "$DEVCLI/config/config.sh"

COMMAND="${1:-help}"
shift || true

COMMAND_FILE="$DEVCLI/commands/$COMMAND"

if [[ -x "$COMMAND_FILE" ]]; then
    exec "$COMMAND_FILE" "$@"
fi

echo
echo "Developer CLI"
echo
echo "Usage:"
echo "  dev doctor"
echo "  dev new <new-branch>"
echo "  dev new <base-branch> <new-branch>"
echo "  dev list"
echo "  dev clean"
echo
exit 1
EOF

# ------------------------------------------------------------
# dev doctor
# ------------------------------------------------------------

cat > "$COMMANDS_DIR/doctor" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.dev-cli/config/config.sh"
source "$HOME/.dev-cli/lib/ui.sh"

step "Checking codebase"
[[ -d "$CODEBASE_ROOT" ]] || error "Missing $CODEBASE_ROOT"
success "$CODEBASE_ROOT"

step "Checking main worktree"
git -C "$CODEBASE_ROOT/$MAIN_WORKTREE" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || error "Main worktree missing: $CODEBASE_ROOT/$MAIN_WORKTREE"
success "$MAIN_WORKTREE"

step "Checking git"
command -v git >/dev/null || error "Git not installed"
git --version
success "Git"

step "Checking fzf"
command -v fzf >/dev/null || error "fzf not installed. Run: brew install fzf"
success "fzf"

step "Checking WezTerm"
if [[ "$OPEN_WEZTERM" == "true" ]]; then
    command -v wezterm >/dev/null || error "WezTerm CLI not installed"
    success "WezTerm"
else
    yellow "WezTerm integration disabled"
fi

step "Checking IntelliJ"
if [[ "$OPEN_INTELLIJ" == "true" ]]; then
    command -v idea >/dev/null || error "IntelliJ 'idea' launcher not found"
    success "IntelliJ"
else
    yellow "IntelliJ integration disabled"
fi

step "Checking Cursor"
if [[ "$OPEN_CURSOR" == "true" ]]; then
    command -v cursor >/dev/null || error "Cursor CLI not found"
    success "Cursor"
else
    yellow "Cursor integration disabled"
fi

echo
green "Everything looks good 🚀"
EOF

# ------------------------------------------------------------
# dev list
# ------------------------------------------------------------

cat > "$COMMANDS_DIR/list" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.dev-cli/config/config.sh"

git -C "$CODEBASE_ROOT/$MAIN_WORKTREE" worktree list
EOF

# ------------------------------------------------------------
# dev new
# ------------------------------------------------------------

cat > "$COMMANDS_DIR/new" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.dev-cli/config/config.sh"
source "$HOME/.dev-cli/lib/ui.sh"
source "$HOME/.dev-cli/lib/git.sh"

if [[ $# -eq 1 ]]; then
    BASE_BRANCH="$DEFAULT_BRANCH"
    NEW_BRANCH="$1"
elif [[ $# -eq 2 ]]; then
    BASE_BRANCH="$1"
    NEW_BRANCH="$2"
else
    error $'Usage:\n  dev new <new-branch>\n  dev new <base-branch> <new-branch>'
fi

ensure_main_exists

FOLDER="${NEW_BRANCH//\//-}"
DESTINATION="$CODEBASE_ROOT/$FOLDER"

if worktree_exists "$DESTINATION"; then
    error "Worktree already exists: $DESTINATION"
fi

# Locate an existing worktree for the base branch.
BASE_WORKTREE=""

while read -r path _ branch; do
    branch="${branch#[}"
    branch="${branch%]}"

    if [[ "$branch" == "$BASE_BRANCH" ]]; then
        BASE_WORKTREE="$path"
        break
    fi
done < <(git -C "$MAIN" worktree list)

# If the base branch has no worktree, create a temporary one.
TEMP_WORKTREE=""

if [[ -z "$BASE_WORKTREE" ]]; then
    TEMP_WORKTREE="$CODEBASE_ROOT/.dev-temp-${BASE_BRANCH//\//-}-$$"

    step "Preparing base branch"

    if git -C "$MAIN" show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
        git -C "$MAIN" worktree add "$TEMP_WORKTREE" "$BASE_BRANCH" >/dev/null

    elif git -C "$MAIN" ls-remote --exit-code --heads origin "$BASE_BRANCH" >/dev/null 2>&1; then
        if ! git -C "$MAIN" show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
            git -C "$MAIN" branch --track "$BASE_BRANCH" "origin/$BASE_BRANCH"
        fi
        git -C "$MAIN" worktree add "$TEMP_WORKTREE" "$BASE_BRANCH" >/dev/null

    else
        error "Base branch '$BASE_BRANCH' not found locally or on origin."
    fi

    BASE_WORKTREE="$TEMP_WORKTREE"
    success "Base branch available"
fi

# Update the base branch before branching from it.
update_branch_worktree "$BASE_WORKTREE" "$BASE_BRANCH"

# Create/use target branch.
step "Preparing target branch"

if git -C "$MAIN" show-ref --verify --quiet "refs/heads/$NEW_BRANCH"; then
    success "Using existing local branch"

    git -C "$BASE_WORKTREE" worktree add \
        "$DESTINATION" \
        "$NEW_BRANCH"

elif git -C "$MAIN" ls-remote --exit-code --heads origin "$NEW_BRANCH" >/dev/null 2>&1; then
    success "Found remote branch"

    git -C "$MAIN" branch \
        --track \
        "$NEW_BRANCH" \
        "origin/$NEW_BRANCH"

    git -C "$BASE_WORKTREE" worktree add \
        "$DESTINATION" \
        "$NEW_BRANCH"

else
    success "Creating new branch"

    git -C "$BASE_WORKTREE" worktree add \
        -b "$NEW_BRANCH" \
        "$DESTINATION"
fi

# Remove temporary base worktree if we created one.
if [[ -n "$TEMP_WORKTREE" ]]; then
    git -C "$MAIN" worktree remove "$TEMP_WORKTREE" >/dev/null
fi

# Open development tools.
if [[ "$OPEN_CURSOR" == "true" ]]; then
    step "Opening Cursor"
    cursor "$DESTINATION" >/dev/null 2>&1 &
    success "Cursor opened"
fi

if [[ "$OPEN_INTELLIJ" == "true" ]]; then
    step "Opening IntelliJ"
    idea --new-window "$DESTINATION" >/dev/null 2>&1 &
    success "IntelliJ opened"
fi

# Open a new WezTerm tab and create an agent pane when invoked
# from inside WezTerm. WezTerm's CLI uses the current pane/window
# context via WEZTERM_PANE.
if [[ "$OPEN_WEZTERM" == "true" ]]; then
    if [[ -n "${WEZTERM_PANE:-}" ]]; then
        step "Opening WezTerm development tab"

        NEW_PANE_ID="$(
            wezterm cli spawn \
                --cwd "$DESTINATION" \
                --pane-id "$WEZTERM_PANE"
        )"

        AGENT_PANE_ID="$(
            wezterm cli split-pane \
                --right \
                --percent 45 \
                --cwd "$DESTINATION" \
                --pane-id "$NEW_PANE_ID" \
                -- zsh -l
        )"

        wezterm cli send-text \
            --pane-id "$AGENT_PANE_ID" \
            --no-paste \
            'agent --approve-mcps'

        wezterm cli send-text \
            --pane-id "$AGENT_PANE_ID" \
            --no-paste \
            $'\n'

        success "WezTerm tab + agent pane opened"
    else
        yellow "WezTerm CLI skipped: run dev new from inside WezTerm"
    fi
fi

echo
green "🚀 Ready: $DESTINATION"
EOF

# ------------------------------------------------------------
# dev clean
# ------------------------------------------------------------

cat > "$COMMANDS_DIR/clean" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.dev-cli/config/config.sh"
source "$HOME/.dev-cli/lib/ui.sh"

MAIN="$CODEBASE_ROOT/$MAIN_WORKTREE"

step "Scanning worktrees"

selection=$(
    git -C "$MAIN" worktree list \
    | grep -v "^$MAIN " \
    | fzf --prompt="Select worktree > "
)

[[ -z "$selection" ]] && exit 0

path=$(echo "$selection" | awk '{print $1}')
branch=$(echo "$selection" | grep -o '\[[^]]*\]' | tr -d '[]')

echo
echo "Worktree : $path"
echo "Branch   : $branch"
echo

# Safety check for uncommitted changes.
if [[ -n "$(git -C "$path" status --porcelain 2>/dev/null || true)" ]]; then
    yellow "⚠ Worktree has uncommitted changes."
    read -r -p "Continue deleting it? (y/N): " force_answer

    if [[ ! "$force_answer" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

read -r -p "Delete local branch too? (y/N): " answer

step "Removing worktree"

git -C "$MAIN" worktree remove "$path"

success "Worktree removed"

if [[ "$answer" =~ ^[Yy]$ ]]; then
    step "Deleting branch"

    git -C "$MAIN" branch -D "$branch"

    success "Branch deleted"
fi

step "Pruning"

git -C "$MAIN" worktree prune

success "Pruned"

echo
green "🚀 Cleanup complete"
EOF

# ------------------------------------------------------------
# Permissions
# ------------------------------------------------------------

chmod +x "$BIN_DIR/dev"
chmod +x "$COMMANDS_DIR/"*
chmod +x "$LIB_DIR/"*.sh
chmod +x "$CONFIG_DIR/config.sh"

# ------------------------------------------------------------
# PATH
# ------------------------------------------------------------

ZSHRC="$HOME/.zshrc"
PATH_LINE='export PATH="$HOME/.dev-cli/bin:$PATH"'

touch "$ZSHRC"

if ! grep -Fqx "$PATH_LINE" "$ZSHRC"; then
    {
        echo
        echo "# Personal developer CLI"
        echo "$PATH_LINE"
    } >> "$ZSHRC"

    echo "Added dev CLI to ~/.zshrc"
else
    echo "dev CLI PATH already configured"
fi

# ------------------------------------------------------------
# Final checks
# ------------------------------------------------------------

echo
echo "==> Installation complete"
echo
echo "Reload your shell:"
echo "  source ~/.zshrc"
echo
echo "Then run:"
echo "  dev doctor"
echo
echo "Useful commands:"
echo "  dev new <branch>"
echo "  dev new <base-branch> <new-branch>"
echo "  dev list"
echo "  dev clean"
