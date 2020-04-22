-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

local sort_sprite = function(name, y)
  return {
    type = "sprite",
    name = "ee-sort-"..name,
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
    name = "ee-logo",
    filename = "__EditorExtensions__/graphics/gui/crafting-group.png",
    size = 128,
    mipmap_count = 2,
    flags = {"icon"}
  },
  {
    type = "sprite",
    name = "ee-time",
    filename = "__EditorExtensions__/graphics/gui/infinity-combinator.png",
    y = 0,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  },
  {
    type = "sprite",
    name = "ee-sort",
    filename = "__EditorExtensions__/graphics/gui/infinity-combinator.png",
    y = 32,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  },
  sort_sprite("alphabetical-ascending", 64),
  sort_sprite("alphabetical-descending", 96),
  sort_sprite("numerical-ascending", 128),
  sort_sprite("numerical-descending", 160),
  {
    type = "sprite",
    name = "ee-import-inventory-filters",
    filename = "__EditorExtensions__/graphics/gui/inventory-filters.png",
    y = 0,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  },
  {
    type = "sprite",
    name = "ee-export-inventory-filters",
    filename = "__EditorExtensions__/graphics/gui/inventory-filters.png",
    y = 32,
    size = 32,
    mipmap_count = 2,
    flags = {"icon"}
  }
}