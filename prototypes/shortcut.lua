local function shortcut_sprite(suffix, size)
  return {
    filename = "__EditorExtensions__/graphics/shortcut-bar/map-editor-" .. suffix,
    priority = "extra-high-no-scale",
    size = size,
    scale = 1,
    mipmap_count = 2,
    flags = { "icon" },
  }
end

data:extend({
  {
    type = "shortcut",
    name = "ee-toggle-map-editor",
    order = "c[toggles]-m[map-editor]",
    icon = shortcut_sprite("x32.png", 32),
    disabled_icon = shortcut_sprite("x32-white.png", 32),
    small_icon = shortcut_sprite("x24.png", 24),
    disabled_small_icon = shortcut_sprite("x24-white.png", 24),
    action = "lua",
    associated_control_input = "ee-toggle-map-editor",
    toggleable = true,
  },
})
