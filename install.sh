#!/usr/bin/env bash
set -e

# If not root, use sudo
if [[ $EUID -ne 0 ]]; then
  SUDO='sudo'
else
  SUDO=''
fi

echo "Updating package database and installing required packages..."
$SUDO pacman -Syu --needed \
  hyprland \
  kitty \
  dolphin \
  wofi \
  waybar \
  hyprpaper \
  grim \
  slurp \
  wl-clipboard \
  brightnessctl \
  playerctl \
  swaylock \
  xdg-desktop-portal-hyprland \
  network-manager-applet

echo "Creating Hyprland config directory..."
CONFIG_DIR="$HOME/.config/hypr"
mkdir -p "$CONFIG_DIR"

echo "Copying hyprland.conf to $CONFIG_DIR..."
cp config/hypr/hyprland.conf "$CONFIG_DIR/hyprland.conf"

echo "Done! Your config is installed at $CONFIG_DIR/hyprland.conf"

