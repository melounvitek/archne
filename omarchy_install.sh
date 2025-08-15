#!/usr/bin/env bash
set -euo pipefail

# ––– CONFIG –––
GITHUB_RAW="https://raw.githubusercontent.com/melounvitek/archne/main/config"
# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# privilege helper
((EUID != 0)) && SUDO=sudo || SUDO=

echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed less vim zsh syncthing htop
$SUDO yay -S --needed google-chrome

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
fetch_or_copy nvim/lua/config options.lua

HYPR_CFG="$HOME/.config/hypr/hyprland.conf"
LINE='source = ~/.config/hypr/archne.conf'

if ! grep -Fxq "$LINE" "$HYPR_CFG" 2>/dev/null; then
  echo "$LINE" >> "$HYPR_CFG"
fi

# ─ Zsh + Oh My Zsh ───────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Installing Oh My Zsh…"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ─ Add custom aliases if not already present ─
ZSHRC="$HOME/.zshrc"
grep -qxF 'alias de="docker exec -it"' "$ZSHRC" || echo 'alias de="docker exec -it"' >>"$ZSHRC"
grep -qxF 'alias be="bundle exec"' "$ZSHRC" || echo 'alias be="bundle exec"' >>"$ZSHRC"
grep -qxF 'alias open="xdg-open"' "$ZSHRC" || echo 'alias open="xdg-open"' >>"$ZSHRC"
echo "Added aliases to $ZSHRC"


grep -qxF 'eval "$(mise activate zsh)"' "$ZSHRC" || echo 'eval "$(mise activate zsh)"' >>"$ZSHRC"
echo "Mise activated in $ZSHRC"


echo "Changing default shell to zsh…"
$SUDO chsh -s "$(command -v zsh)" $(whoami)

git config --global --replace-all core.pager "less -F -X"
git config --global core.editor "vim"


if ! command -v syncthing >/dev/null 2>&1; then
  echo "Enabling Syncthing (user service)…"
  systemctl --user enable --now syncthing.service
else
  echo "Syncthing already installed, skipping."
fi
