# Developer CLI Setup Guide

This guide documents the current `dev` CLI setup for a macOS development environment.

The CLI is designed around Git worktrees and a repository layout where the main worktree lives at:

```text
~/codebase/main
```

Additional worktrees are created directly under:

```text
~/codebase/
```

For example:

```text
~/codebase/
├── main
├── feature-payment-api
├── feature-cart
└── bugfix-checkout
```

## 1. Prerequisites

Install the basic dependencies:

```bash
brew install fzf jq
```

Verify:

```bash
fzf --version
jq --version
git --version
```

The CLI also expects:

- Cursor or Devin, depending on your current editor configuration.
- IntelliJ IDEA if you want IntelliJ automatically opened.
- WezTerm if using the terminal integration.

Verify the relevant commands:

```bash
cursor --version
idea --version
wezterm cli --help
```

If a command is not installed, `dev doctor` will identify it.

---

## 2. Create the CLI directory structure

Create:

```bash
mkdir -p ~/.dev-cli/{bin,commands,lib,config}
```

The resulting structure is:

```text
~/.dev-cli/
├── bin/
│   └── dev
├── commands/
│   ├── doctor
│   ├── new
│   ├── clean
│   └── list
├── lib/
│   ├── ui.sh
│   └── git.sh
└── config/
    └── config.sh
```

---

## 3. Add the CLI to PATH

Add this to `~/.zshrc`:

```bash
export PATH="$HOME/.dev-cli/bin:$PATH"
```

Reload the shell:

```bash
source ~/.zshrc
```

Verify:

```bash
which dev
```

Expected:

```text
/Users/<your-user>/.dev-cli/bin/dev
```

If `dev` is not found after restarting WezTerm, check:

```bash
grep dev-cli ~/.zshrc
echo "$PATH"
```

---

## 4. Create the configuration

Create:

```bash
touch ~/.dev-cli/config/config.sh
```

Put the following in it:

```bash
#!/usr/bin/env bash

CODEBASE_ROOT="$HOME/codebase"

MAIN_WORKTREE="main"

DEFAULT_BRANCH="main"

OPEN_CURSOR=true
OPEN_INTELLIJ=true
OPEN_WEZTERM=true
```

### Configuration values

| Variable | Purpose |
|---|---|
| `CODEBASE_ROOT` | Root directory containing all worktrees |
| `MAIN_WORKTREE` | Directory containing the main worktree |
| `DEFAULT_BRANCH` | Branch used when no base branch is supplied |
| `OPEN_CURSOR` | Open Cursor when creating a worktree |
| `OPEN_INTELLIJ` | Open IntelliJ when creating a worktree |
| `OPEN_WEZTERM` | Enable WezTerm integration |

> If you have switched the editor integration from Cursor to Devin Desktop, change the editor-specific portion of `dev new` accordingly. The CLI structure remains the same.

---

# 5. Create the `dev` entrypoint

Create:

```bash
touch ~/.dev-cli/bin/dev
chmod +x ~/.dev-cli/bin/dev
```

Contents:

```bash
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
echo "Available commands:"
echo

ls "$DEVCLI/commands"

echo
```

The entrypoint delegates commands to individual scripts.

For example:

```text
dev doctor
```

runs:

```text
~/.dev-cli/commands/doctor
```

---

# 6. Create the UI library

Create:

```bash
touch ~/.dev-cli/lib/ui.sh
```

Contents:

```bash
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
```

This keeps terminal output consistent across commands.

---

# 7. Create the Git library

Create:

```bash
touch ~/.dev-cli/lib/git.sh
```

The Git library centralizes common Git operations used by the CLI.

The current implementation includes functions for:

- locating the main worktree
- validating the main worktree
- updating a base branch
- checking whether a worktree exists

Example structure:

```bash
#!/usr/bin/env bash

source "$HOME/.dev-cli/config/config.sh"
source "$HOME/.dev-cli/lib/ui.sh"

MAIN="$CODEBASE_ROOT/$MAIN_WORKTREE"

ensure_main_exists() {
    git -C "$MAIN" rev-parse --is-inside-work-tree >/dev/null \
        || error "Main worktree is invalid"
}

update_main() {
    step "Updating main"

    git -C "$MAIN" fetch origin

    git -C "$MAIN" checkout "$DEFAULT_BRANCH" >/dev/null

    git -C "$MAIN" merge --ff-only "origin/$DEFAULT_BRANCH"

    success "main updated"
}

worktree_exists() {
    local destination="$1"

    [[ -e "$destination" ]]
}
```

---

# 8. Create `dev doctor`

Create:

```bash
touch ~/.dev-cli/commands/doctor
chmod +x ~/.dev-cli/commands/doctor
```

The command should validate:

- codebase root
- main worktree
- Git
- Cursor/Devin integration
- WezTerm

Run:

```bash
dev doctor
```

Expected output:

```text
▶ Checking codebase
✔ /Users/<your-user>/codebase

▶ Checking main worktree
✔ main

▶ Checking git
✔ Git

▶ Checking Cursor
✔ Cursor

▶ Checking WezTerm
✔ WezTerm

Everything looks good 🚀
```

The current implementation uses Git itself to validate the worktree rather than checking whether `.git` is a directory. This is important because `.git` can be a file in a Git worktree.

---

# 9. Create `dev list`

The command lists all Git worktrees.

Create:

```bash
touch ~/.dev-cli/commands/list
chmod +x ~/.dev-cli/commands/list
```

Basic implementation:

```bash
#!/usr/bin/env bash

set -euo pipefail

source "$HOME/.dev-cli/config/config.sh"

git -C "$CODEBASE_ROOT/$MAIN_WORKTREE" worktree list
```

Run:

```bash
dev list
```

Example:

```text
/Users/<your-user>/codebase/main
/Users/<your-user>/codebase/feature-payment-api
/Users/<your-user>/codebase/feature-cart
```

---

# 10. Create a new worktree

The primary command is:

```bash
dev new <new-branch>
```

For example:

```bash
dev new feature/payment-api
```

The CLI:

1. Locates the main worktree.
2. Updates the base branch.
3. Checks whether the target branch already exists locally.
4. Checks whether it exists on `origin`.
5. Reuses an existing local branch when possible.
6. Creates a local tracking branch when an origin branch exists.
7. Otherwise creates a brand-new branch.
8. Creates the worktree under `~/codebase`.
9. Opens the configured development tools.

Example resulting layout:

```text
~/codebase/
├── main
└── feature-payment-api
```

The Git branch can still contain `/`:

```text
feature/payment-api
```

while the directory uses:

```text
feature-payment-api
```

---

# 11. Create a worktree from another feature branch

The CLI also supports stacked feature development.

Syntax:

```bash
dev new <base-branch> <new-branch>
```

Example:

```bash
dev new feature/cart feature/payment-api
```

This means:

```text
main
  │
  └── feature/cart
          │
          └── feature/payment-api
```

Instead of updating `main`, the CLI updates:

```text
feature/cart
```

and creates:

```text
feature/payment-api
```

from that branch.

This is useful when a new feature depends on changes that haven't been merged into `main` yet.

---

# 12. Existing remote branches

If you run:

```bash
dev new feature/payment-api
```

and:

```text
origin/feature/payment-api
```

already exists, the CLI should use that branch rather than creating a new branch with the same name.

The intended decision tree is:

```text
Does the target worktree already exist?
    → Stop

Does the local branch exist?
    → Use it

Does origin/<branch> exist?
    → Create a local tracking branch and use it

Otherwise
    → Create a new branch
```

This makes `dev new` useful both for starting new work and picking up existing remote work.

---

# 13. `dev clean`

`dev clean` provides interactive worktree cleanup.

Run:

```bash
dev clean
```

It uses `fzf` to select a worktree.

The main worktree is excluded from deletion.

After selecting a worktree, the command:

1. Shows the selected worktree.
2. Asks whether the local branch should also be deleted.
3. Removes the worktree.
4. Optionally deletes the branch.
5. Runs `git worktree prune`.

Example:

```text
Worktree : /Users/<your-user>/codebase/feature-payment-api
Branch   : feature/payment-api

Delete local branch too? (y/N):
```

This gives you a safe, interactive way to clean up old worktrees.

---

# 14. Current recommended workflow

### Start a new feature from main

```bash
dev new feature/payment-api
```

### Start a feature from another feature branch

```bash
dev new feature/cart feature/payment-api
```

### See all worktrees

```bash
dev list
```

### Clean up old worktrees

```bash
dev clean
```

### Check the CLI environment

```bash
dev doctor
```

---

# 15. Recommended directory convention

Keep `main` permanently dedicated to the main branch:

```text
~/codebase/main
```

Use sibling directories for all other worktrees:

```text
~/codebase/
├── main
├── feature-cart
├── feature-payment-api
├── bugfix-checkout
└── hotfix-production
```

The directory name is derived from the branch name by replacing `/` with `-`.

For example:

```text
feature/payment-api
```

becomes:

```text
feature-payment-api
```

---

# 16. Current development philosophy

The CLI is deliberately split into small components:

```text
~/.dev-cli/
├── bin/dev
├── commands/
├── lib/
└── config/
```

`bin/dev` is only the dispatcher.

Command-specific logic lives in:

```text
commands/
```

Reusable functionality lives in:

```text
lib/
```

Environment-specific settings live in:

```text
config/
```

This makes it straightforward to add commands later without turning `dev` into one giant shell script.

---

# 17. Planned next features

The next useful additions are:

### `dev open`

Select an existing worktree with `fzf` and open it in the configured IDE and WezTerm.

```bash
dev open
```

### Better `dev list`

Display:

- branch
- worktree
- clean/dirty status
- last commit
- age
- potentially merge status

### `dev update`

Update multiple worktrees safely.

### `dev switch`

Quickly switch your development environment to an existing worktree.

### Stacked branch support

Eventually track:

```text
main
 └── feature/A
      └── feature/B
           └── feature/C
```

This could enable commands such as:

```bash
dev graph
dev rebase
dev sync
```

### AI workspace automation

The longer-term goal is for:

```bash
dev new feature/payment-api
```

to create the worktree and launch the complete development environment:

```text
Devin
IntelliJ
WezTerm
AI agent
lazygit
Spring Boot
Docker/Kubernetes tooling
```

That turns `dev` into a personal developer workspace manager rather than just a Git wrapper.
