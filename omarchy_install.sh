#!/usr/bin/env bash
set -euo pipefail

GITHUB_REPO="https://raw.githubusercontent.com/melounvitek/archne/main/"

((EUID != 0)) && SUDO=sudo || SUDO=

echo
echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed --noconfirm less vim zsh syncthing htop tree transmission-gtk zoxide bitwarden rsync
yay -S --needed --noconfirm ookla-speedtest-bin

if ! command -v pi &>/dev/null; then
  echo "Installing Pi…"
  omarchy-npm-install @earendil-works/pi-coding-agent pi
fi

fetch_or_copy() {
  src_file=$1
  dst="$HOME/.$src_file"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$src_file" ]]; then
    cp "$src_file" "$dst"
  else
    curl -fsSL "$GITHUB_REPO/$src_file" -o "$dst"
  fi
  echo " → $src_file"
}

echo
echo "Copying configs…"
touch ~/.config/hypr/local_overrides.conf
fetch_or_copy config/hypr/archne.conf
fetch_or_copy config/hypr/hyprsunset.conf
fetch_or_copy config/hypr/scripts/group-aware-focus
fetch_or_copy config/hypr/scripts/toggle-workspace-group
chmod +x "$HOME/.config/hypr/scripts/group-aware-focus" "$HOME/.config/hypr/scripts/toggle-workspace-group"
fetch_or_copy config/nvim/lua/config/options.lua
fetch_or_copy local/bin/waybar-codex-usage
chmod +x "$HOME/.local/bin/waybar-codex-usage"

echo "Configuring Codex usage in Waybar…"
python3 <<'PY'
import shutil
import time
from pathlib import Path

config_path = Path.home() / ".config/waybar/config.jsonc"
style_path = Path.home() / ".config/waybar/style.css"
timestamp = time.strftime("%Y%m%d%H%M%S")

config = config_path.read_text()
updated_config = config
if not any(line.strip().rstrip(",") == '"custom/codex-usage"' for line in config.splitlines()):
    marker = '    "battery"\n  ],'
    if marker not in updated_config:
        raise SystemExit("Could not find the end of Waybar's modules-right")
    updated_config = updated_config.replace(
        marker,
        '    "battery",\n    "custom/codex-usage"\n  ],',
        1,
    )

if '  "custom/codex-usage": {' not in updated_config:
    marker = '  "cpu": {'
    if marker not in updated_config:
        raise SystemExit("Could not find Waybar's cpu module configuration")
    module_config = '''  "custom/codex-usage": {
    "exec": "waybar-codex-usage",
    "return-type": "json",
    "interval": 60
  },

'''
    updated_config = updated_config.replace(marker, module_config + marker, 1)

style = style_path.read_text()
updated_style = style
if not any(line.strip() == "#custom-codex-usage {" for line in style.splitlines()):
    updated_style = style.rstrip() + '''

#custom-codex-usage {
  min-width: 12px;
  margin: 0 7.5px;
}

#custom-codex-usage.warning {
  color: #e0af68;
}

#custom-codex-usage.critical {
  color: #a55555;
}

#custom-codex-usage.unavailable {
  opacity: 0.5;
}
'''

for path, original, updated in (
    (config_path, config, updated_config),
    (style_path, style, updated_style),
):
    if updated != original:
        shutil.copy2(path, f"{path}.bak.{timestamp}")
        path.write_text(updated)
PY
omarchy restart waybar

echo "Ensuring opencode-synced plugin…"
OPENCODE_CFG="$HOME/.config/opencode/opencode.json"
if [[ -f "$OPENCODE_CFG" ]]; then
  jq '.plugin = ((.plugin // []) + ["opencode-synced"] | unique)' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
fi

echo
echo "Copying web applications…"
mkdir -p $HOME/.local/share/applications/icons/

fetch_or_copy local/share/applications/Calendar.desktop
fetch_or_copy local/share/applications/icons/Calendar.png

fetch_or_copy local/share/applications/Freelo.desktop
fetch_or_copy local/share/applications/icons/Freelo.png

fetch_or_copy local/share/applications/Gmail.desktop
fetch_or_copy local/share/applications/icons/Gmail.png

fetch_or_copy local/share/applications/Messenger.desktop
fetch_or_copy local/share/applications/icons/Messenger.png

fetch_or_copy local/share/applications/Syncthing.desktop
fetch_or_copy local/share/applications/icons/Syncthing.png

fetch_or_copy local/share/applications/Asana.desktop
fetch_or_copy local/share/applications/icons/Asana.png

fetch_or_copy local/share/applications/Netflix.desktop
fetch_or_copy local/share/applications/icons/Netflix.png
echo

echo "Source Archne in Hyprland config…"
HYPR_CFG="$HOME/.config/hypr/hyprland.conf"
LINE='source = ~/.config/hypr/archne.conf'

if ! grep -Fxq "$LINE" "$HYPR_CFG" 2>/dev/null; then
  echo "$LINE" >> "$HYPR_CFG"
fi

echo "Enabling automatic nightlight…"
HYPRSUNSET_AUTOSTART='exec-once = uwsm-app -- hyprsunset'
HYPR_AUTOSTART_CFG="$HOME/.config/hypr/autostart.conf"
touch "$HYPR_AUTOSTART_CFG"
grep -qxF "$HYPRSUNSET_AUTOSTART" "$HYPR_AUTOSTART_CFG" || echo "$HYPRSUNSET_AUTOSTART" >> "$HYPR_AUTOSTART_CFG"
omarchy-restart-hyprsunset

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo
  echo "Installing Oh My Zsh…"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Adding custom aliases…"
ZSHRC="$HOME/.zshrc"
grep -qxF 'alias de="docker exec -it"' "$ZSHRC" || echo 'alias de="docker exec -it"' >>"$ZSHRC"
grep -qxF 'alias da="docker attach"' "$ZSHRC" || echo 'alias da="docker attach"' >>"$ZSHRC"
grep -qxF 'alias dce="docker compose exec"' "$ZSHRC" || echo 'alias dce="docker compose exec"' >>"$ZSHRC"
grep -qxF 'alias be="bundle exec"' "$ZSHRC" || echo 'alias be="bundle exec"' >>"$ZSHRC"
grep -qxF 'alias open="xdg-open"' "$ZSHRC" || echo 'alias open="xdg-open"' >>"$ZSHRC"


echo "Ensuring Mise is activated in $ZSHRC…"
grep -qxF 'eval "$(mise activate zsh)"' "$ZSHRC" || echo 'eval "$(mise activate zsh)"' >>"$ZSHRC"
echo

echo "Changing default shell to zsh…"
$SUDO chsh -s "$(command -v zsh)" $(whoami)
echo

echo "Adding some Git configuration…"
git config --global --replace-all core.pager "less"
git config --global core.editor "nvim"
echo

echo "Enabling Syncthing (user service)…"
systemctl --user enable --now syncthing.service
echo

echo "Activating Zoxide…"
grep -qxF 'eval "$(zoxide init zsh)"' "$ZSHRC" || echo 'eval "$(zoxide init zsh)"' >>"$ZSHRC"
echo

echo "Enabling Google Account in Chromium…"
omarchy-install-chromium-google-account
echo
