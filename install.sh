#!/usr/bin/env bash
set -euo pipefail

# ––– CONFIG –––
GITHUB_RAW="https://raw.githubusercontent.com/melounvitek/archne/master/config"
# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# privilege helper
((EUID != 0)) && SUDO=sudo || SUDO=

echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed \
  hyprland kitty dolphin wofi waybar hyprpaper \
  grim slurp wl-clipboard brightnessctl playerctl \
  swaylock xdg-desktop-portal-hyprland \
  network-manager-applet firefox

install_dir() { mkdir -p "$HOME/.config/$1"; }

fetch_or_copy() {
  sub=$1
  file=$2
  src="./config/$sub/$file"
  dst="$HOME/.config/$sub/$file"
  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else curl -fsSL "$GITHUB_RAW/$sub/$file" -o "$dst"; fi
  echo " → $sub/$file"
}

echo
echo "Setting up configs…"
install_dir hypr
fetch_or_copy hypr hyprland.conf

install_dir waybar
fetch_or_copy waybar config.jsonc
fetch_or_copy waybar style.css

echo
# ─ Optional: Mise ───────────────────────────────────────
read -rp "Install Mise and configure Ruby build opts? (y/n) " yn
if [[ $yn =~ ^[Yy] ]]; then
  echo "Installing mise…"
  $SUDO pacman -S --needed mise
  echo "Configuring mise…"
  mise settings set ruby.ruby_build_opts "CC=gcc-14 CXX=g++-14"
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

echo
echo "All finished! 🎉"
