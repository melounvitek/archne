# AGENTS.md

## Project Overview

Archne is a personal Arch Linux desktop environment configurator (dotfiles repo).
It sets up a Hyprland-based Wayland desktop with Waybar, Kitty, Neovim, and various
utilities. The project is archived; the author now uses Omarchy with a thin overlay
(`omarchy_install.sh`).

**Languages:** Bash (primary), Hyprland conf, JSONC, CSS, Lua
**No build system, no package manager, no compiled code.**

## Repository Structure

```
install.sh                 # Full Arch Linux installer script
omarchy_install.sh         # Lightweight overlay installer for Omarchy
bin/
  create_webapp            # Creates .desktop webapp launchers with favicon fetch
  store_system_config      # Copies live system configs back into this repo
config/
  hypr/
    hyprland.conf          # Main Hyprland WM config (monitors, keybinds, animations)
    archne.conf            # Personal overrides (CZ keyboard, custom keybinds)
    mbpro2015_local_overrides.conf  # Machine-specific overrides
    scripts/
      smart-focus          # Intelligent window/group navigation script
  nvim/
    lua/config/options.lua # Neovim/LazyVim options
  waybar/
    config.jsonc           # Waybar panel modules config
    style.css              # Waybar CSS styling
local/
  share/applications/      # .desktop files and icons for web app shortcuts
```

## Build / Lint / Test Commands

There are **no build, lint, or test commands**. This project has no test suite,
no linter configuration, no CI/CD pipeline, and no compilation step.

The only executable commands are the installer scripts:

```bash
# Full Arch Linux setup (destructive - installs system packages)
bash install.sh

# Overlay on top of Omarchy
bash omarchy_install.sh
```

To validate shell scripts manually:

```bash
# Lint shell scripts with shellcheck (not configured, but recommended)
shellcheck install.sh omarchy_install.sh bin/create_webapp bin/store_system_config
shellcheck config/hypr/scripts/smart-focus
```

## Code Style Guidelines

### Shell Scripts

#### Shebang and Strict Mode
- Always use `#!/usr/bin/env bash`
- Always enable strict mode: `set -euo pipefail`

#### Indentation
- **2 spaces** for shell scripts
- **4 spaces** for Hyprland conf, JSONC, CSS, and Lua files

#### Variable Naming
- `UPPER_SNAKE_CASE` for constants and environment-like variables
  (`GITHUB_RAW`, `SUDO`, `ZSHRC`)
- `lower_snake_case` for local/working variables
  (`current_user`, `config`, `icon_path`)

#### Function Naming
- `lower_snake_case` without the `function` keyword:
  ```bash
  install_dir() {
    # ...
  }
  ```

#### Quoting
- Always double-quote variable expansions: `"$HOME/.config/$1"`
- Use curly braces for clarity when needed: `${scheme}`, `${fav_rel:-}`
- Use `${var:-}` for default values with `set -u`

#### Control Flow
- Use `[[ ... ]]` double brackets (bash-specific)
- Use `(( ... ))` for arithmetic tests
- Use `read -rp` for interactive prompts
- Use `command -v` to check if a command exists
- Use `mapfile -t` for reading arrays

#### Error Handling
- Rely on `set -euo pipefail` for fail-fast behavior
- Use `|| true` to suppress expected failures: `curl -sL "$url" || true`
- Use explicit exit codes: `exit 1` for errors, `exit 0` for success

#### Comments
- Use decorated section headers for major sections:
  ```bash
  # --- CONFIG ---
  # - Zsh + Oh My Zsh -------
  ```
- Keep inline comments short and descriptive
- Add a script-level comment describing purpose at the top

#### Output to User
- Use `echo` with descriptive messages and ellipsis: `"Installing zsh..."`
- Use arrow prefix for file operations: `echo " -> $sub/$file"`

### Hyprland Configuration

- 4-space indentation inside blocks
- Section headers use decorated blocks:
  ```
  ################
  ### MONITORS ###
  ################
  ```
- Variables use `$camelCase`: `$terminal`, `$fileManager`, `$mainMod`
- Use `source` directive for modular config splitting
- Place keybinding comments above the bind line

### Waybar / JSONC

- 4-space indentation
- Double quotes for all keys and string values
- Trailing commas are acceptable (JSONC)
- Use `//` comments for section headers with decorated separators:
  ```jsonc
  // -------------------------------------------------------------------------
  // Global configuration
  // -------------------------------------------------------------------------
  ```

### CSS (Waybar Styling)

- 4-space indentation
- Block comment headers with decorated separators:
  ```css
  /* ---------------------------------------------------------------------------
   * Section Name
   * ------------------------------------------------------------------------- */
  ```
- One property per line
- Use hex colors (`#323232`) or `rgb()` function
- Selectors use kebab-case IDs: `#custom-spotify`

### Lua (Neovim Config)

- Standard Lua `--` comment style
- Use `vim.g.` for global options and `vim.o.` for editor options

### Desktop Entry Files

- Follow freedesktop `.desktop` specification
- PascalCase filenames matching app names: `Calendar.desktop`
- Include: `Version`, `Name`, `Comment`, `Exec`, `Terminal`, `Type`, `Icon`

## File & Directory Naming

| Type              | Convention           | Example                    |
|-------------------|----------------------|----------------------------|
| Executable scripts| kebab-case, no ext   | `smart-focus`, `create_webapp` |
| Installer scripts | snake_case.sh        | `install.sh`               |
| Config directories| lowercase            | `hypr`, `nvim`, `waybar`   |
| Desktop files     | PascalCase.desktop   | `Gmail.desktop`            |
| Icon assets       | PascalCase.png       | `Gmail.png`                |

## Git Commit Messages

- Short, single-line messages
- Capitalize the first word
- Use imperative mood: "Fix", "Add", "Remove", "Use", "Install"
- No conventional commit prefixes (no `feat:`, `fix:`, `chore:`)
- No issue references or PR numbers
- Examples: `"Fix screenshot"`, `"Add Netflix webapp"`, `"Remove some custom styling"`
