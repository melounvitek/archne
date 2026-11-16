hl.config({
  general = {
    no_focus_fallback = true,
  },
  input = {
    touchpad = {
      natural_scroll = true,
    },
  },
})

hl.unbind("SUPER + W")

for workspace = 1, 12 do
  local key = "F" .. workspace
  o.bind("CTRL + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(
    "CTRL + SHIFT + " .. key,
    "Move window silently to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false })
  )
end

o.rebind("SUPER + SHIFT + E", "File manager", { launch = "nautilus" })

o.bind("SUPER + page_up", "Brightness up", "omarchy-brightness-display +5%", { locked = true, repeating = true })
o.bind("SUPER + page_down", "Brightness down", "omarchy-brightness-display 5%-", { locked = true, repeating = true })

o.bind("SUPER + SHIFT + F4", "Screenshot", "omarchy-capture-screenshot")

o.rebind("SUPER + G", "Toggle workspace group", "~/.config/hypr/scripts/toggle-workspace-group")

for _, direction in ipairs({
  { key = "LEFT", argument = "l", description = "Focus left or previous grouped window" },
  { key = "RIGHT", argument = "r", description = "Focus right or next grouped window" },
  { key = "UP", argument = "u", description = "Focus up or previous grouped window" },
  { key = "DOWN", argument = "d", description = "Focus down or next grouped window" },
}) do
  o.rebind("SUPER + " .. direction.key, direction.description, "~/.config/hypr/scripts/group-aware-focus " .. direction.argument)
end

require("hypr.local_overrides")
