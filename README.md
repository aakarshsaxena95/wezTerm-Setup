# WezTerm and Developer CLI Setup

This repository provides a macOS setup for two complementary tools:

- **WezTerm shortcuts:** a ready-to-use `~/.wezterm.lua` configuration with a macOS-native keyboard workflow.
- **`dev` CLI:** a Git-worktree helper for creating, opening, listing, checking, and safely removing development worktrees.

The scripts are designed for a codebase layout such as:

```text
~/codebase/
├── main/                  # the primary Git worktree
├── feature-payment-api/   # created by `dev new feature/payment-api`
└── bugfix-checkout/
```

## Contents

| File | Purpose |
| --- | --- |
| `setup-wezterm-shortcuts.sh` | Writes the complete WezTerm configuration and shortcuts. |
| `WEZTERM_SHORTCUTS.md` | Shortcut reference. |
| `setup-dev-cli.sh` | Installs the `dev` CLI in `~/.dev-cli`. |
| `DEV_CLI_BOOTSTRAP_SETUP.md` | Step-by-step bootstrap notes. |
| `DEV_CLI_SETUP.md` | Detailed design and manual-install reference for the CLI. |

## Before you begin

This setup targets **macOS** and assumes `zsh`. Install WezTerm, Git, and the CLI dependencies first:

```bash
brew install wezterm git fzf jq
```

The `dev` CLI can also integrate with these optional tools:

- [Cursor](https://www.cursor.com/) through its `cursor` shell command
- IntelliJ IDEA through its `idea` command-line launcher
- WezTerm, to open a new development tab and an agent pane

The default CLI configuration enables all three integrations. If you do not use Cursor or IntelliJ, disable the corresponding setting after installation before running `dev doctor` or `dev new`.

## 1. Set up WezTerm shortcuts

From this repository, make the script executable and run it:

```bash
chmod +x setup-wezterm-shortcuts.sh
./setup-wezterm-shortcuts.sh
```

The script writes a complete configuration to `~/.wezterm.lua`. If that file already exists, it first creates a timestamped backup alongside it, for example `~/.wezterm.lua.backup.20260825-143000`.

Restart WezTerm, or reload its configuration with `⌘⇧R`.

### What the WezTerm setup provides

It applies the Catppuccin Mocha theme, JetBrains Mono Nerd Font fallbacks, a compact padded window, high-refresh WebGPU rendering, 20,000 scrollback lines, and a `zsh` login shell. The window starts at 170 columns by 45 rows.

| Area | Shortcut | Action |
| --- | --- | --- |
| Panes | `⌘D` / `⌘⇧D` | Split left/right or top/bottom |
| Panes | `⌘⇧W` | Close the current pane without a confirmation prompt |
| Panes | `⌘Enter` | Zoom or restore the current pane |
| Panes | `⌥←` `⌥→` `⌥↑` `⌥↓` | Move among panes |
| Panes | `⌥⇧←` `⌥⇧→` `⌥⇧↑` `⌥⇧↓` | Resize a pane in five-cell increments |
| Tabs | `⌘T`, `⌘W` | Create or close a tab |
| Tabs | `⌘1`–`⌘9` | Switch to tabs 1–9 |
| Tabs | `⌘[` / `⌘]` | Previous / next tab |
| Terminal | `⌘K` | Clear the viewport and scrollback |
| Utilities | `⌘P` / `⌘L` | Open the Command Palette / Launcher |

For the standalone shortcut cheat sheet, see [WEZTERM_SHORTCUTS.md](/Users/as901h/personal/wezTerm-Setup/WEZTERM_SHORTCUTS.md).

> **Important:** the script replaces—not merges with—your `~/.wezterm.lua`. Keep the generated backup or merge any personal customizations back into the new file.

## 2. Prepare your Git worktree layout

Create or move your primary repository to `~/codebase/main`. The directory name and base branch can be changed later in the CLI configuration.

```bash
mkdir -p ~/codebase
git clone <repository-url> ~/codebase/main
git -C ~/codebase/main status
```

The clone must have an `origin` remote when you want the CLI to fetch and update remote branches.

## 3. Install the `dev` CLI

Run the bootstrap script from this repository:

```bash
chmod +x setup-dev-cli.sh
./setup-dev-cli.sh
source ~/.zshrc
```

The installer:

1. Backs up an existing `~/.dev-cli` directory to `~/.dev-cli-backups/`.
2. Installs the executable, commands, libraries, and configuration under `~/.dev-cli/`.
3. Adds `~/.dev-cli/bin` to `PATH` in `~/.zshrc` if it is not already present.

Verify the installation:

```bash
which dev
dev doctor
```

### Configure optional integrations

Edit `~/.dev-cli/config/config.sh` to match your machine:

```bash
CODEBASE_ROOT="$HOME/codebase"
MAIN_WORKTREE="main"
DEFAULT_BRANCH="main"

OPEN_CURSOR=true
OPEN_INTELLIJ=true
OPEN_WEZTERM=true
```

Set an integration to `false` if its command is unavailable, for example:

```bash
OPEN_CURSOR=false
OPEN_INTELLIJ=false
```

Re-running `setup-dev-cli.sh` creates a backup but then writes the default configuration again. Save any configuration changes you want to keep, or reapply them after reinstallation.

## Using `dev`

Run `dev` with no arguments to display the available commands.

| Command | What it does |
| --- | --- |
| `dev doctor` | Checks the codebase, main worktree, Git, `fzf`, and every enabled integration. |
| `dev list` | Displays Git's registered worktrees. |
| `dev new <branch>` | Creates or opens a worktree from `DEFAULT_BRANCH` (normally `main`). |
| `dev new <base-branch> <branch>` | Creates a worktree from another branch; useful for stacked work. |
| `dev clean` | Interactively selects a non-main worktree to remove, with prompts for dirty worktrees and branch deletion. |

### Create a worktree

```bash
dev new feature/payment-api
```

This updates the base branch from `origin`, then creates or reuses the requested branch. A slash in a branch name becomes a hyphen in the directory name:

```text
Branch:    feature/payment-api
Directory: ~/codebase/feature-payment-api
```

If the branch already exists locally, the CLI adds it as a worktree. If it exists only on `origin`, it creates a tracking branch. Otherwise, it creates a new branch from the base branch.

For work that builds on an unmerged feature:

```bash
dev new feature/cart feature/payment-api
```

### Editor and WezTerm behavior

After a successful `dev new`, enabled integrations act as follows:

- Cursor opens the new worktree.
- IntelliJ opens the worktree in a new window.
- When the command is run inside WezTerm, it opens a new WezTerm tab in the worktree, splits off a 45% right-hand pane, and runs `agent --approve-mcps` there.

The WezTerm integration needs the `agent` command to be installed and available in `PATH`. When `dev new` is invoked outside WezTerm, worktree creation still succeeds; the terminal tab step is skipped with a message.

### Clean up a worktree

```bash
dev clean
```

Choose a worktree in the `fzf` picker. The CLI warns if it contains uncommitted changes and separately asks whether to delete its local branch. It never presents the main worktree as an option.

## Troubleshooting

| Symptom | Resolution |
| --- | --- |
| `dev: command not found` | Run `source ~/.zshrc`, then check `echo "$PATH"` includes `~/.dev-cli/bin`. |
| `dev doctor` reports Cursor or IntelliJ missing | Install/configure that launcher, or set `OPEN_CURSOR=false` or `OPEN_INTELLIJ=false` in `~/.dev-cli/config/config.sh`. |
| Main worktree missing | Confirm `CODEBASE_ROOT` and `MAIN_WORKTREE` point to a valid Git checkout. |
| Base branch cannot be updated | Check the repository's `origin` remote and your network access; the CLI fetches from `origin`. |
| No WezTerm tab opens | Run `dev new` from a WezTerm pane and confirm `OPEN_WEZTERM=true` plus `wezterm` and `agent` are on `PATH`. |
| Existing WezTerm tweaks disappeared | Restore or copy pieces from the timestamped `~/.wezterm.lua.backup.*` created by the shortcut script. |

## Further reference

- [WezTerm shortcut reference](/Users/as901h/personal/wezTerm-Setup/WEZTERM_SHORTCUTS.md)
- [Developer CLI bootstrap guide](/Users/as901h/personal/wezTerm-Setup/DEV_CLI_BOOTSTRAP_SETUP.md)
- [Developer CLI implementation and manual setup guide](/Users/as901h/personal/wezTerm-Setup/DEV_CLI_SETUP.md)
