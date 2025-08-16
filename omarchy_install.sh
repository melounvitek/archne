#!/usr/bin/env bash
set -euo pipefail

GITHUB_REPO="https://raw.githubusercontent.com/melounvitek/archne/main/"

((EUID != 0)) && SUDO=sudo || SUDO=

echo
echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed less vim zsh syncthing htop tree
$SUDO yay -S --needed google-chrome

fetch_or_copy() {
  src_file=$1
  dst="$HOME/.$src_file"
  if [[ -f "$src_file" ]]; then
    cp "$src_file" "$dst"
  else
    curl -fsSL "$GITHUB_REPO/$src_file" -o "$dst"
  fi
  echo " → $src_file"
}

echo
echo "Copying configs…"
fetch_or_copy config/hypr/archne.conf
fetch_or_copy config/nvim/lua/config/options.lua

echo
echo "Copying web applications…"
fetch_or_copy local/share/applications/Calendar.desktop
fetch_or_copy local/share/applications/icons/Calendar.png

fetch_or_copy local/share/applications/Freelo.desktop
fetch_or_copy local/share/applications/icons/Freelo.png

fetch_or_copy local/share/applications/Gmail.desktop
fetch_or_copy local/share/applications/icons/Gmail.png

fetch_or_copy local/share/applications/Messenger.desktop
fetch_or_copy local/share/applications/icons/Messenger.png
echo

echo "Source Archne in Hyprland config…"
HYPR_CFG="$HOME/.config/hypr/hyprland.conf"
LINE='source = ~/.config/hypr/archne.conf'

if ! grep -Fxq "$LINE" "$HYPR_CFG" 2>/dev/null; then
  echo "$LINE" >> "$HYPR_CFG"
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo
  echo "Installing Oh My Zsh…"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Adding custom aliases…"
ZSHRC="$HOME/.zshrc"
grep -qxF 'alias de="docker exec -it"' "$ZSHRC" || echo 'alias de="docker exec -it"' >>"$ZSHRC"
grep -qxF 'alias be="bundle exec"' "$ZSHRC" || echo 'alias be="bundle exec"' >>"$ZSHRC"
grep -qxF 'alias open="xdg-open"' "$ZSHRC" || echo 'alias open="xdg-open"' >>"$ZSHRC"


echo "Ensuring Mise is activated in $ZSHRC…"
grep -qxF 'eval "$(mise activate zsh)"' "$ZSHRC" || echo 'eval "$(mise activate zsh)"' >>"$ZSHRC"
echo

echo "Changing default shell to zsh…"
$SUDO chsh -s "$(command -v zsh)" $(whoami)
echo

echo "Adding some Git configuration…"
git config --global --replace-all core.pager "less -F -X"
git config --global core.editor "vim"
echo

echo "Enabling Syncthing (user service)…"
systemctl --user enable --now syncthing.service
echo

echo "Preparing Walker patch to open Chromium webapps in Chrome…"
mkdir -p ~/bin && ln -sf /usr/bin/google-chrome-stable ~/bin/chromium
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/walker/config.toml"
grep -q 'PATH=$HOME/bin:$PATH' "$cfg" || sed -i '/launch_prefix/s|uwsm|PATH=$HOME/bin:$PATH uwsm|' "$cfg"
