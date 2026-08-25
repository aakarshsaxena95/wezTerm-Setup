# WezTerm macOS Shortcuts

This document describes the keyboard shortcuts configured in the current WezTerm setup.

## Panes

| Shortcut | Action |
|---|---|
| `⌘D` | Split pane left/right |
| `⌘⇧D` | Split pane top/bottom |
| `⌘⇧W` | Close current pane |
| `⌘Enter` | Zoom / unzoom current pane |

## Pane Navigation

| Shortcut | Action |
|---|---|
| `⌥←` | Move to left pane |
| `⌥→` | Move to right pane |
| `⌥↑` | Move to upper pane |
| `⌥↓` | Move to lower pane |

## Pane Resizing

| Shortcut | Action |
|---|---|
| `⌥⇧←` | Resize pane left |
| `⌥⇧→` | Resize pane right |
| `⌥⇧↑` | Resize pane up |
| `⌥⇧↓` | Resize pane down |

## Tabs

| Shortcut | Action |
|---|---|
| `⌘T` | New tab |
| `⌘W` | Close current tab |
| `⌘1`–`⌘9` | Jump directly to tabs 1–9 |
| `⌘[` | Previous tab |
| `⌘]` | Next tab |

## Terminal

| Shortcut | Action |
|---|---|
| `⌘K` | Clear terminal viewport and scrollback |

## WezTerm Utilities

| Shortcut | Action |
|---|---|
| `⌘P` | Open Command Palette |
| `⌘L` | Open Launcher / workspace launcher |

## Design Philosophy

The setup intentionally uses native macOS `⌘` shortcuts for frequent actions and `⌥` shortcuts for pane navigation/resizing. A tmux-style leader key is not used for everyday operations.

### Quick reference

```text
PANES
⌘D          Split left/right
⌘⇧D         Split top/bottom
⌘⇧W         Close pane
⌘Enter      Zoom pane

NAVIGATION
⌥←→↑↓       Move between panes
⌥⇧←→↑↓      Resize panes

TABS
⌘T          New tab
⌘W          Close tab
⌘1–9        Jump to tab
⌘[ / ⌘]     Previous / next tab

TERMINAL
⌘K          Clear terminal

UTILITIES
⌘P          Command Palette
⌘L          Launcher
```

> Note: This document describes the shortcut configuration, not the separate `dev` CLI commands.
