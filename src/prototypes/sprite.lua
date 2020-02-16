-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SPRITES

local sort_sprite = function(mode, direction)
  return {
    type = 'sprite',
    name = 'ee-sort-'..mode..'-'..direction,
    filename = '__EditorExtensions__/graphics/gui/sort-'..mode..'-'..direction..'.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  }
end

data:extend{
  {
    type = 'sprite',
    name = 'ee-logo',
    filename = '__EditorExtensions__/graphics/gui/crafting-group.png',
    size = 128,
    mipmap_count = 2,
    flags = {'icon'}
  },
  {
    type = 'sprite',
    name = 'ee-time',
    filename = '__EditorExtensions__/graphics/gui/time-alt.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  },
  {
    type = 'sprite',
    name = 'ee-sort',
    filename = '__EditorExtensions__/graphics/gui/sort.png',
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  },
  sort_sprite('alphabetical', 'ascending'),
  sort_sprite('alphabetical', 'descending'),
  sort_sprite('numerical', 'ascending'),
  sort_sprite('numerical', 'descending'),
  {
    type = 'sprite',
    name = 'ee-import-inventory-filters',
    filename = '__EditorExtensions__/graphics/gui/inventory-filters.png',
    y = 0,
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  },
  {
    type = 'sprite',
    name = 'ee-export-inventory-filters',
    filename = '__EditorExtensions__/graphics/gui/inventory-filters.png',
    y = 32,
    size = 32,
    mipmap_count = 2,
    flags = {'icon'}
  }
}