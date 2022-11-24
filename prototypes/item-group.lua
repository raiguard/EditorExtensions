local constants = require("__EditorExtensions__/prototypes/constants")

local function add_group(name, order)
  data:extend({
    {
      type = "item-subgroup",
      group = "ee-tools",
      name = name,
      order = order,
    },
  })
end

add_group("ee-inventories", "a")
add_group("ee-misc", "b")
add_group("ee-electricity", "c")
add_group("ee-trains", "d")
add_group("ee-robots", "e")
add_group("ee-modules", "f")
add_group("ee-equipment", "g")

data:extend({
  {
    type = "item-group",
    name = "ee-tools",
    order = "zzzzz",
    icons = {
      {
        icon = "__EditorExtensions__/graphics/gui/crafting-group.png",
        icon_size = 128,
        icon_mipmaps = 2,
        tint = constants.infinity_tint,
      },
    },
  },
})
