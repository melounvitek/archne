local root = arg[1] or "."
package.path = root .. "/test/?.lua;" .. package.path

local helper = require("hypr_config_test_helper")
local archne = helper.load_config(root .. "/config/hypr/archne.lua")
local config = archne.configs[1]

helper.assert_equal(config.general.no_focus_fallback, true, "focus fallback")
helper.assert_equal(config.input.touchpad.natural_scroll, true, "natural scrolling")
helper.assert_equal(config.input.kb_layout, nil, "keyboard layout")
helper.assert_equal(archne.local_override_loaded, true, "local overrides")

for _, keys in ipairs({
  "SUPER + W",
  "SUPER + SHIFT + E",
  "SUPER + G",
  "SUPER + LEFT",
  "SUPER + RIGHT",
  "SUPER + UP",
  "SUPER + DOWN",
}) do
  helper.assert_equal(archne.unbound[keys], true, "unbind " .. keys)
end

helper.assert_equal(archne.bindings["SUPER + Q"].dispatcher.action, "close", "close shortcut")
helper.assert_equal(archne.bindings["CTRL + F1"].dispatcher.options.workspace, "1", "first workspace shortcut")
helper.assert_equal(archne.bindings["CTRL + F12"].dispatcher.options.workspace, "12", "last workspace shortcut")
helper.assert_equal(archne.bindings["CTRL + SHIFT + F12"].dispatcher.options.follow, false, "silent workspace move")
helper.assert_equal(archne.bindings["SUPER + SHIFT + E"].dispatcher.launch, "nautilus", "file manager shortcut")
helper.assert_equal(archne.bindings["SUPER + page_up"].dispatcher, "omarchy-brightness-display +5%", "brightness up")
helper.assert_equal(archne.bindings["SUPER + page_down"].dispatcher, "omarchy-brightness-display 5%-", "brightness down")
helper.assert_equal(archne.bindings["SUPER + SHIFT + F4"].dispatcher, "omarchy-capture-screenshot", "screenshot shortcut")
helper.assert_equal(archne.bindings["SUPER + G"].dispatcher, "~/.config/hypr/scripts/toggle-workspace-group", "group shortcut")
helper.assert_equal(archne.bindings["SUPER + LEFT"].dispatcher, "~/.config/hypr/scripts/group-aware-focus l", "group-aware focus")

print("Archne Hyprland configuration tests passed")
