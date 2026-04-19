# Troubleshooting Guide

This guide provides solutions to common issues you may encounter while working through the Software Factory Intensive curriculum.

## General Issues

### Scrolling in a `tmux` session acts as mousekey input on the prompt history.

`tmux` (and other full-screen terminal apps like `vim` and `less`) uses the terminal's *alternate screen buffer*. By default, macOS Terminal treats scroll-wheel events inside alternate-screen apps as arrow-key input and forwards them to the running program — which is what makes scrolling inside a `tmux` session feel like it's walking through your shell's prompt history instead of moving the view. Enabling the **Scroll alternate screen** preference inverts the behavior so the scroll wheel scrolls the terminal view, and Fn/Shift+scroll sends input to the alternate-screen app.

![macOS Terminal Settings → Profiles → Keyboard pane with a red box highlighting the "Scroll alternate screen" checkbox](images/troubleshooting/macos-terminal-scroll-alternate-screen.png)

**Fix (macOS Terminal):**

1. Open **Terminal** (macOS built-in).
2. Open **Terminal → Settings…** (or press **⌘,**).
3. Select the **Profiles** tab.
4. In the left sidebar, pick your profile (usually the highlighted/default one).
5. In the right pane, select the **Keyboard** sub-tab.
6. Near the bottom, check the **Scroll alternate screen** checkbox (highlighted in red above).
7. Close Settings. The change applies immediately in new `tmux` sessions; detach and reattach an existing session if it doesn't pick up the new behavior.
