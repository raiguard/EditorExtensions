data:extend({
  {
    type = "shortcut",
    name = "ee-toggle-map-editor",
    icon = "__EditorExtensions__/graphics/shortcut-bar/map-editor-x32.png",
    disabled_icon = "__EditorExtensions__/graphics/shortcut-bar/map-editor-x32-white.png",
    small_icon = "__EditorExtensions__/graphics/shortcut-bar/map-editor-x24.png",
    disabled_small_icon = "__EditorExtensions__/graphics/shortcut-bar/map-editor-x24-white.png",
    order = "c[toggles]-m[map-editor]",
    action = "lua",
    associated_control_input = "ee-toggle-map-editor",
    toggleable = true,
  },
})
