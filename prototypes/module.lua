local table = require("__flib__/table")

local constants = require("__EditorExtensions__/prototypes/constants")

local module_template = {
  type = "module",
  subgroup = "ee-modules",
  stack_size = 50,
  art_style = "vanilla",
}

for _, module_data in pairs(constants.module_data) do
  local module = table.deep_copy(module_template)
  module.name = module_data.name
  module.order = module_data.order
  module.category = module_data.category
  module.tier = module_data.tier
  module.effect = module_data.effect
  module.icons = {
    {
      icon = "__EditorExtensions__/graphics/item/" .. module_data.icon_ref .. ".png",
      icon_size = 64,
      icon_mipmaps = 4,
      tint = module_data.tint,
    },
  }
  module.beacon_tint = {
    primary = module_data.tint,
    secondary = module_data.tint,
    tertiary = module_data.tint,
    quaternary = module_data.tint,
  }
  data:extend({ module })
end
