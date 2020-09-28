local editor_controller = data.raw["editor-controller"].default
for name, setting in pairs(settings.startup) do
  if string.match(name, "ee%-controller") then
    editor_controller[string.gsub(name, "ee%-controller%-", "")] = setting.value
  end
end

local function shortcut_sprite(suffix, size)
  return {
    filename = "__EditorExtensions__/graphics/shortcut-bar/map-editor-"..suffix,
    priority = "extra-high-no-scale",
    size = size,
    scale = 1,
    mipmap_count = 2,
    flags = {"icon"}
  }
end

data:extend{
  {
    type = "shortcut",
    name = "ee-toggle-map-editor",
    icon = shortcut_sprite("x32.png", 32),
    disabled_icon = shortcut_sprite("x32-white.png", 32),
    small_icon = shortcut_sprite("x24.png", 24),
    disabled_small_icon = shortcut_sprite("x24-white.png", 24),
    action = "lua",
    associated_control_input = "ee-toggle-map-editor",
    toggleable = true
  },
  {
    type = "custom-input",
    name = "ee-toggle-map-editor",
    key_sequence = "CONTROL + E",
    action = "lua"
  },
  {
    type = "custom-input",
    name = "ee-mouse-leftclick",
    key_sequence = "",
    linked_game_control = "open-gui"
  }
}

require("prototypes.entity")
require("prototypes.equipment")
require("prototypes.fluid")
require("prototypes.item-group")
require("prototypes.item")
require("prototypes.module")
require("prototypes.recipe")
require("prototypes.recipe-category")
require("prototypes.sprite")
require("prototypes.style")