local root = arg[1] or "."
package.path = root .. "/test/?.lua;" .. package.path

local helper = require("hypr_config_test_helper")
local mbpro = helper.load_config(root .. "/config/hypr/mbpro2015_local_overrides.lua")

helper.assert_equal(mbpro.bindings["SUPER + XF86MonBrightnessDown"].dispatcher.options.workspace, "1", "MacBook workspace shortcut")
helper.assert_equal(mbpro.bindings["SUPER + SHIFT + XF86KbdBrightnessDown"].dispatcher.options.follow, false, "MacBook silent workspace move")
helper.assert_equal(mbpro.bindings["SUPER + F12"].dispatcher, "omarchy-capture-screenshot", "MacBook screenshot shortcut")

print("MacBook Pro Hyprland configuration tests passed")
