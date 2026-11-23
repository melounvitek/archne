#!/usr/bin/env bash
set -euo pipefail

GITHUB_REPO="https://raw.githubusercontent.com/melounvitek/archne/main/"

((EUID != 0)) && SUDO=sudo || SUDO=

echo
echo "Updating Omarchy…"
omarchy update -y

echo "Installing core packages…"
omarchy pkg add vim zsh syncthing htop tree transmission-gtk rsync

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
touch "$HOME/.config/hypr/local_overrides.lua"
fetch_or_copy config/hypr/archne.lua
fetch_or_copy config/hypr/scripts/group-aware-focus
fetch_or_copy config/hypr/scripts/toggle-workspace-group
chmod +x "$HOME/.config/hypr/scripts/group-aware-focus" "$HOME/.config/hypr/scripts/toggle-workspace-group"
fetch_or_copy config/nvim/lua/config/options.lua
fetch_or_copy config/nvim/lua/plugins/ruby.lua
fetch_or_copy config/nvim/solargraph_mapping_patch.rb
echo "Ensuring opencode-synced plugin…"
OPENCODE_CFG="$HOME/.config/opencode/opencode.json"
if [[ -f "$OPENCODE_CFG" ]]; then
  jq '.plugin = ((.plugin // []) + ["opencode-synced"] | unique)' "$OPENCODE_CFG" > "$OPENCODE_CFG.tmp" && mv "$OPENCODE_CFG.tmp" "$OPENCODE_CFG"
fi

echo "Installing shell plugins…"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"

# Replace the old patched clone of the agents widget with the stock one
AGENTS_CLONE="$PLUGINS_DIR/${USER:-$(id -un)}.agents"
if [[ -d "$AGENTS_CLONE" ]]; then
  omarchy plugin remove "$(basename "$AGENTS_CLONE")" --yes
fi

# add_plugin <id> <git-url> [--enable [bar placement…]]
add_plugin() {
  local id=$1 url=$2
  shift 2
  if [[ -d "$PLUGINS_DIR/$id" ]]; then
    echo " → $id (already installed)"
    return
  fi
  if [[ ${1:-} == --enable ]]; then
    shift
    omarchy plugin add "$url" --enable --yes
    if (($# > 0)); then
      omarchy bar move "$id" "$@"
    fi
  else
    omarchy plugin add "$url" --yes
  fi
  echo " → $id"
}

add_plugin skoom.beszel https://github.com/skoom21/omarchy-beszel.git --enable --after omarchy.system-update
add_plugin spencerbull.cliproxyapi https://github.com/spencerbull/omarchy-cliproxyapi --enable --before omarchy.agents
add_plugin sunshine144.solar-nightlight https://github.com/sunshine144/solar-nightlight --enable

# Show real server names in the Beszel panel instead of "Server N"
omarchy bar set skoom.beszel maskSensitive Off

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

echo "To finish shell plugin setup:"
echo "  Beszel:      ~/.config/omarchy/plugins/skoom.beszel/setup"
echo "  CLIProxyAPI: click its bar icon and enter the server URL and management key"
echo

echo "For Ruby LSP support, install Solargraph for each Ruby version you use:"
echo "  mise x ruby@<version> -- gem install solargraph --no-document"
echo
