#!/usr/bin/env bash
set -euo pipefail

GITHUB_REPO="https://raw.githubusercontent.com/melounvitek/archne/main/"

((EUID != 0)) && SUDO=sudo || SUDO=

echo
echo "Updating & installing core packages…"
$SUDO pacman -Syu --needed --noconfirm less vim zsh syncthing htop tree transmission-gtk zoxide rsync
yay -S --needed --noconfirm ookla-speedtest-bin

if ! command -v pi &>/dev/null; then
  echo "Installing Pi…"
  omarchy mise install npm:@earendil-works/pi-coding-agent pi
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
LEGACY_LOCAL_OVERRIDES="$HOME/.config/hypr/local_overrides.conf"
LOCAL_OVERRIDES="$HOME/.config/hypr/local_overrides.lua"
if [[ -s "$LEGACY_LOCAL_OVERRIDES" && ! -s "$LOCAL_OVERRIDES" ]]; then
  echo "Existing local_overrides.conf must be converted to Lua: $LOCAL_OVERRIDES"
fi
touch "$LOCAL_OVERRIDES"
fetch_or_copy config/hypr/archne.lua
fetch_or_copy config/hypr/scripts/group-aware-focus
fetch_or_copy config/hypr/scripts/toggle-workspace-group
chmod +x "$HOME/.config/hypr/scripts/group-aware-focus" "$HOME/.config/hypr/scripts/toggle-workspace-group"
fetch_or_copy config/nvim/lua/config/options.lua
fetch_or_copy config/nvim/lua/plugins/ruby.lua
fetch_or_copy local/share/archne/agents-remaining.patch
echo "Ensuring opencode-synced plugin…"
OPENCODE_CFG="$HOME/.config/opencode/opencode.json"
if [[ -f "$OPENCODE_CFG" ]]; then
  jq '.plugin = ((.plugin // []) + ["opencode-synced"] | unique)' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
fi

echo "Showing remaining weekly model usage…"
AGENTS_PLUGIN="$HOME/.config/omarchy/plugins/${USER:-$(id -un)}.agents"
AGENTS_PATCH="$HOME/.local/share/archne/agents-remaining.patch"

if [[ ! -d "$AGENTS_PLUGIN" ]]; then
  omarchy plugin clone omarchy.agents
fi

if git -C "$AGENTS_PLUGIN" apply --reverse --check "$AGENTS_PATCH" &>/dev/null; then
  :
elif git -C "$AGENTS_PLUGIN" apply --check "$AGENTS_PATCH"; then
  git -C "$AGENTS_PLUGIN" apply "$AGENTS_PATCH"
else
  echo "Unable to customize the current Omarchy agents plugin." >&2
  exit 1
fi

omarchy bar set "$(basename "$AGENTS_PLUGIN")" refreshIntervalSec 300 --json
omarchy restart shell

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

echo "Loading Archne in Hyprland config…"
HYPR_CFG="$HOME/.config/hypr/hyprland.lua"
LINE='require("hypr.archne")'

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
grep -qxF 'alias da="docker attach"' "$ZSHRC" || echo 'alias da="docker attach"' >>"$ZSHRC"
grep -qxF 'alias dce="docker compose exec"' "$ZSHRC" || echo 'alias dce="docker compose exec"' >>"$ZSHRC"
grep -qxF 'alias be="bundle exec"' "$ZSHRC" || echo 'alias be="bundle exec"' >>"$ZSHRC"
grep -qxF 'alias open="xdg-open"' "$ZSHRC" || echo 'alias open="xdg-open"' >>"$ZSHRC"


echo "Ensuring Mise is activated in $ZSHRC…"
grep -qxF 'eval "$(mise activate zsh)"' "$ZSHRC" || echo 'eval "$(mise activate zsh)"' >>"$ZSHRC"
echo

zsh_path="$(command -v zsh)"
current_shell="$(getent passwd "$(whoami)" | cut -d: -f7)"

if [[ "$current_shell" == "$zsh_path" ]]; then
  echo "Default shell is already zsh."
else
  echo "Changing default shell to zsh…"
  $SUDO chsh -s "$zsh_path" "$(whoami)"
fi
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
omarchy install chromium google account
echo

echo "For Ruby LSP support, install Solargraph for each Ruby version you use:"
echo "  mise x ruby@<version> -- gem install solargraph --no-document"
echo
