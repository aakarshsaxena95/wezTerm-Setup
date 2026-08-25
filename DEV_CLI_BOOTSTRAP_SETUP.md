# Developer CLI Bootstrap Script — Setup Instructions

This document explains how to install the `dev` CLI from the bootstrap script on a fresh macOS setup.

## 1. Prerequisites

The script assumes:

- macOS
- Homebrew
- Git
- WezTerm
- `fzf`
- Cursor CLI if Cursor integration is enabled
- IntelliJ `idea` launcher if IntelliJ integration is enabled

Install the CLI dependencies:

```bash
brew install fzf jq
```

Verify:

```bash
git --version
fzf --version
```

If you use the WezTerm integration:

```bash
wezterm cli --help
```

If you use IntelliJ integration:

```bash
```

If you use Cursor integration:

```bash
```

---

## 2. Make sure the repository layout exists

The current CLI expects:

```text
~/codebase/
└── main/
```

where `main` is the Git worktree containing the main branch.

Verify:

```bash
ls -la ~/codebase/main
```

Verify that Git recognizes it:

```bash
git -C ~/codebase/main status
```

You should see the repository's Git status.

---

## 3. Download the bootstrap script

Download:

```text
setup-dev-cli.sh
```

For example, if the browser saves it to `~/Downloads`:

```bash
ls -l ~/Downloads/setup-dev-cli.sh
```

If the file was downloaded somewhere else, use that path instead.

---

## 4. Make the script executable

Run:

```bash
chmod +x ~/Downloads/setup-dev-cli.sh
```

Verify:

```bash
ls -l ~/Downloads/setup-dev-cli.sh
```

The permissions should contain `x`, for example:

```text
-rwxr-xr-x
```

---

## 5. Run the bootstrap script

Run:

```bash
~/Downloads/setup-dev-cli.sh
```

The script will:

1. Back up an existing `~/.dev-cli` installation, if one exists.
2. Create the CLI directory structure.
3. Create the configuration.
4. Create the `dev` entrypoint.
5. Create `doctor`, `new`, `list`, and `clean`.
6. Create shared Git/UI libraries.
7. Add the CLI to your shell `PATH`.
8. Make the scripts executable.

You should see:

```text
==> Installing dev CLI
...
==> Installation complete
```

---

## 6. Reload your shell

The script adds:

```bash
export PATH="$HOME/.dev-cli/bin:$PATH"
```

to `~/.zshrc`.

Reload it:

```bash
source ~/.zshrc
```

Or simply close and reopen WezTerm.

---

## 7. Verify the `dev` command

Run:

```bash
which dev
```

Expected:

```text
/Users/<your-user>/.dev-cli/bin/dev
```

Then:

```bash
dev
```

You should see the available commands.

---

## 8. Run the health check

Run:

```bash
dev doctor
```

This verifies the CLI environment.

Expected checks include:

```text
▶ Checking codebase
✔ /Users/<your-user>/codebase

▶ Checking main worktree
✔ main

▶ Checking git
✔ Git

▶ Checking fzf
✔ fzf

▶ Checking WezTerm
✔ WezTerm

▶ Checking IntelliJ
✔ IntelliJ

▶ Checking Cursor
✔ Cursor

Everything looks good 🚀
```

Some checks can be disabled in:

```bash
~/.dev-cli/config/config.sh
```

---

# 9. Configuration

Open:

```bash
cursor ~/.dev-cli/config/config.sh
```

The current configuration looks like:

```bash
CODEBASE_ROOT="$HOME/codebase"
MAIN_WORKTREE="main"
DEFAULT_BRANCH="main"

OPEN_WEZTERM=true
```

The `dev new` command does not open an IDE automatically. IDEs can be opened separately when needed.

---

# 10. Test `dev list`

Run:

```bash
dev list
```

You should see your existing worktrees.

For example:

```text
/Users/<your-user>/codebase/main
/Users/<your-user>/codebase/feature-payment-api
```

---

# 11. Test creating a worktree

From any directory, run:

```bash
dev new test-branch
```

The default base branch is `main`.

The expected result is:

```text
~/codebase/
├── main
└── test-branch
```

Verify:

```bash
dev list
```

And:

```bash
git -C ~/codebase/test-branch branch --show-current
```

Expected:

```text
test-branch
```

---

# 12. Test branching from another feature

If you have an existing branch:

```text
feature/cart
```

run:

```bash
dev new feature/cart feature/payment-api
```

This creates:

```text
main
└── feature/cart
    └── feature/payment-api
```

The CLI updates `feature/cart` first and then creates the new worktree from it.

---

# 13. Test remote branch detection

If:

```text
origin/feature/payment-api
```

already exists, run:

```bash
dev new feature/payment-api
```

The CLI should detect the remote branch and create a local tracking branch instead of creating a brand-new branch.

---

# 14. Test cleanup

Create a temporary worktree:

```bash
dev new test-clean
```

Then:

```bash
dev clean
```

Select `test-clean` in the `fzf` picker.

The CLI will:

- remove the worktree
- optionally delete the local branch
- prune stale worktree metadata

Verify:

```bash
dev list
```

---

# 15. Useful commands

```bash
# Health check
dev doctor

# New branch from main
dev new feature/payment-api

# New branch from another branch
dev new feature/cart feature/payment-api

# List worktrees
dev list

# Interactive cleanup
dev clean
```

---

# 16. Updating the CLI later

The bootstrap script is safe to rerun.

Before replacing the existing installation, it creates a backup under:

```text
~/.dev-cli-backups/
```

You can see backups with:

```bash
ls -lah ~/.dev-cli-backups
```

To reinstall/update from the bootstrap script:

```bash
chmod +x ~/Downloads/setup-dev-cli.sh
~/Downloads/setup-dev-cli.sh
source ~/.zshrc
dev doctor
```

---

# 17. Troubleshooting

## `dev: command not found`

Check:

```bash
grep dev-cli ~/.zshrc
```

You should have:

```bash
export PATH="$HOME/.dev-cli/bin:$PATH"
```

Reload:

```bash
source ~/.zshrc
```

Then:

```bash
which dev
```

---

## `dev doctor` says main worktree is missing

Check:

```bash
ls -la ~/codebase/main
```

Then:

```bash
git -C ~/codebase/main status
```

The CLI expects the main repository worktree at:

```text
~/codebase/main
```

---

## IntelliJ is not detected

Check:

```bash
which idea
```

If `idea` is unavailable, create the IntelliJ command-line launcher from:

```text
IntelliJ IDEA
→ Tools
→ Create Command-line Launcher
```

---

## WezTerm is not detected

Check:

```bash
which wezterm
wezterm cli --help
```

If WezTerm is installed but the command isn't available, verify that the WezTerm application is installed in `/Applications` and that its CLI is on your `PATH`.

---

# 18. Final verification

After installation, run these four commands:

```bash
which dev
dev doctor
dev list
dev clean
```

If all four work, the developer CLI is installed and ready.
