local table = require("__flib__.table")

local constants = require("prototypes.constants")

local module_template = {
  type = "module",
  subgroup = "ee-modules",
  stack_size = 50,
  art_style = "vanilla"
}

for _, t in pairs(constants.module_data) do
  local module = table.deep_merge{t, module_template}
  module.icons = {
    {
      icon = "__EditorExtensions__/graphics/item/"..module.icon_ref..".png",
      icon_size = 64,
      icon_mipmaps = 4,
      tint = module.tint
    }
  }
  module.icon_ref = nil
  module.beacon_tint = {
    primary = module.tint,
    secondary = module.tint,
    tertiary = module.tint,
    quaternary = module.tint
  }
  data:extend{module}
end