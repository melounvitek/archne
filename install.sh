#!/usr/bin/env bash
set -euo pipefail

# ––– CONFIGURE THESE –––
GITHUB_RAW="https://raw.githubusercontent.com/melounvitek/archne/master/config"
# ––––––––––––––––––––––

# privilege helper
if ((EUID != 0)); then SUDO=sudo; else SUDO=; fi

echo "Updating & installing packages…"
$SUDO pacman -Syu --needed \
  hyprland kitty dolphin wofi waybar hyprpaper \
  grim slurp wl-clipboard brightnessctl playerctl \
  swaylock xdg-desktop-portal-hyprland network-manager-applet

install_dir() {
  local target=$1
  shift
  mkdir -p "$HOME/.config/$target"
}

fetch_or_copy() {
  # args: subpath, target-filename
  local sub="$1"
  local file="$2"
  local src="./config/$sub/$file"
  local dst="$HOME/.config/$sub/$file"

  if [[ -f "$src" ]]; then
    cp "$src" "$dst"
  else
    curl -fsSL "$GITHUB_RAW/$sub/$file" -o "$dst"
  fi
  echo " → Installed $sub/$file"
}

echo "Setting up Hyprland config…"
install_dir hypr
fetch_or_copy hypr hyprland.conf

echo "Setting up Waybar config…"
install_dir waybar
fetch_or_copy waybar config.jsonc
fetch_or_copy waybar style.css

echo "All done!"
