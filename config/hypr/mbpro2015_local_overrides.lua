-- Omarchy's default XF86 keyboard brightness bindings replace macbook-lighter-kbd.
local workspace_keys = {
  "XF86MonBrightnessDown",
  "XF86MonBrightnessUp",
  "XF86LaunchA",
  "XF86LaunchB",
  "XF86KbdBrightnessDown",
}

for workspace, key in ipairs(workspace_keys) do
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind(
    "SUPER + SHIFT + " .. key,
    "Move window silently to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace), follow = false })
  )
end

o.bind("SUPER + F12", "Screenshot", "omarchy-capture-screenshot")
