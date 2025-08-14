#!/usr/bin/env bash
set -euo pipefail

# ––– CONFIG –––
GITHUB_RAW="https://raw.githubusercontent.com/melounvitek/archne/main/config"
# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# privilege helper
((EUID != 0)) && SUDO=sudo || SUDO=

echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed less vim

fetch_or_copy() {
  sub=$1
  file=$2
  src="./config/$sub/$file"
  dst="$HOME/.config/$sub/$file"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    curl -fsSL "$GITHUB_RAW/$sub/$file" -o "$dst"
  fi
  echo " → $sub/$file"
}

echo
echo "Setting up configs…"
fetch_or_copy hypr archne.conf

HYPR_CFG="$HOME/.config/hypr/hyprland.conf"
LINE='source = ~/.config/hypr/archne.conf'

if ! grep -Fxq "$LINE" "$HYPR_CFG" 2>/dev/null; then
  echo "$LINE" >> "$HYPR_CFG"
fi

git config --global --replace-all core.pager "less -F -X"
git config --global core.editor "vim"

# ─ Zsh + Oh My Zsh ───────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Installing zsh…"
  $SUDO pacman -S --needed zsh
  echo "Installing Oh My Zsh…"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "Changing default shell to zsh…"
  chsh -s "$(command -v zsh)"
fi

# ─ Add custom aliases if not already present ─
ZSHRC="$HOME/.zshrc"
grep -qxF 'alias de="docker exec -it"' "$ZSHRC" || echo 'alias de="docker exec -it"' >>"$ZSHRC"
grep -qxF 'alias be="bundle exec"' "$ZSHRC" || echo 'alias be="bundle exec"' >>"$ZSHRC"
grep -qxF 'alias open="xdg-open"' "$ZSHRC" || echo 'alias open="xdg-open"' >>"$ZSHRC"
echo "Added aliases to $ZSHRC"

NVIM_CFG="$HOME/.config/nvim/lua/config"
mkdir -p "$NVIM_CFG"
cp config/nvim/lua/config/options.lua $NVIM_CFG

echo "Installing syncthing…"
$SUDO pacman -S --needed syncthing
echo "Enabling Syncthing (user service)…"
systemctl --user enable --now syncthing.service
