-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

local sort_sprite = function(name, y)
  return {
    type = "sprite",
    name = "ee_sort_"..name,
    filename = "__EditorExtensions__/graphics/gui/infinity-combinator.png",
    y = y,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  }
end

data:extend{
  {
    type = "sprite",
    name = "ee_logo",
    filename = "__EditorExtensions__/graphics/gui/crafting-group.png",
    size = 128,
    mipmap_count = 2,
    flags = {"icon"}
  },
  {
    type = "sprite",
    name = "ee_time",
    filename = "__EditorExtensions__/graphics/gui/infinity-combinator.png",
    y = 0,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  },
  {
    type = "sprite",
    name = "ee_sort",
    filename = "__EditorExtensions__/graphics/gui/infinity-combinator.png",
    y = 32,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  },
  sort_sprite("alphabetical_ascending", 64),
  sort_sprite("alphabetical_descending", 96),
  sort_sprite("numerical_ascending", 128),
  sort_sprite("numerical_descending", 160),
  {
    type = "sprite",
    name = "ee_import_inventory_filters",
    filename = "__EditorExtensions__/graphics/gui/inventory-filters.png",
    y = 0,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  },
  {
    type = "sprite",
    name = "ee_export_inventory_filters",
    filename = "__EditorExtensions__/graphics/gui/inventory-filters.png",
    y = 32,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  }
}