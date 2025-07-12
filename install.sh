#!/usr/bin/env bash
set -euo pipefail

# ––– CONFIG –––
GITHUB_RAW="https://raw.githubusercontent.com/melounvitek/archne/main/config"
# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# privilege helper
((EUID != 0)) && SUDO=sudo || SUDO=

echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed \
  hyprland kitty dolphin wofi waybar hyprpaper \
  grim slurp wl-clipboard brightnessctl playerctl \
  swaylock xdg-desktop-portal-hyprland \
  network-manager-applet firefox pipewire-pulse \
  git base-devel zsh

install_dir() { mkdir -p "$HOME/.config/$1"; }

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
install_dir hypr
fetch_or_copy hypr hyprland.conf

install_dir waybar
fetch_or_copy waybar config.jsonc
fetch_or_copy waybar style.css

# ─ Zsh + Oh My Zsh ───────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Installing zsh…"
  $SUDO pacman -S --needed zsh
  echo "Installing Oh My Zsh…"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  echo "Changing default shell to zsh…"
  chsh -s "$(command -v zsh)"
fi

echo
# ─ Optional: Mise ───────────────────────────────────────
read -rp "Install Mise and configure Ruby build opts? (y/n) " yn
if [[ $yn =~ ^[Yy] ]]; then
  echo "Installing mise…"
  $SUDO pacman -S --needed mise gcc14
  echo "Configuring mise…"
  mise settings set ruby.ruby_build_opts "CC=gcc-14 CXX=g++-14"
  echo 'eval "$(mise activate zsh)"' >>~/.zshrc
else
  echo "Skipping Mise."
fi

# ─ Optional: Obsidian ──────────────────────────────────
read -rp "Install Obsidian and enable auto-start? (y/n) " yn
if [[ $yn =~ ^[Yy] ]]; then
  echo "Installing obsidian…"
  $SUDO pacman -S --needed obsidian
  echo "Enabling Obsidian auto-start…"
  mkdir -p "$HOME/.config/autostart"
  cat >"$HOME/.config/autostart/obsidian.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Obsidian
Exec=obsidian
X-GNOME-Autostart-enabled=true
EOF
else
  echo "Skipping Obsidian."
fi

# ─ Optional: Syncthing ─────────────────────────────────
read -rp "Install Syncthing and enable it? (y/n) " yn
if [[ $yn =~ ^[Yy] ]]; then
  echo "Installing syncthing…"
  $SUDO pacman -S --needed syncthing
  echo "Enabling Syncthing (user service)…"
  systemctl --user enable --now syncthing.service
else
  echo "Skipping Syncthing."
fi

# ─ Optional: Neovim + LazyVim ──────────────────────────
read -rp "Install Neovim with LazyVim? (y/n) " yn
if [[ $yn =~ ^[Yy] ]]; then
  echo "Installing neovim…"
  $SUDO pacman -S --needed neovim
  echo "Setting up LazyVim…"
  rm -rf "$HOME/.config/nvim"
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  echo "Finalizing LazyVim install…"
  nvim --headless +"Lazy! sync" +qa
else
  echo "Skipping Neovim + LazyVim."
fi

echo
echo "All finished! 🎉 Reboot the system"
