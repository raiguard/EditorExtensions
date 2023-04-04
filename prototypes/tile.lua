--- @param source_name string
--- @param destination_name string
local function disguise_tile(source_name, destination_name)
  local tile = table.deepcopy(data.raw["tile"][source_name])
  tile.name = destination_name
  tile.variants = {
    main = tile.variants.main,
    material_background = tile.variants.material_background,
    empty_transitions = true,
  }
  tile.transitions = nil
  -- Don't use lab dark 2 map color because it's almost pure black
  if destination_name == "lab-dark-1" then
    tile.map_color = data.raw["tile"]["lab-dark-1"].map_color
    data.raw["tile"]["lab-dark-2"].map_color = tile.map_color
  end
  return tile
end

local graphics_setting = settings.startup["ee-lab-tile-graphics"].value

if graphics_setting == "all-light" then
  data:extend({ disguise_tile("lab-dark-2", "lab-dark-1") })
elseif graphics_setting == "all-dark" then
  data:extend({ disguise_tile("lab-dark-1", "lab-dark-2") })
elseif graphics_setting == "tutorial-grid" then
  data:extend({ disguise_tile("tutorial-grid", "lab-dark-1"), disguise_tile("tutorial-grid", "lab-dark-2") })
elseif graphics_setting == "refined-concrete" then
  data:extend({ disguise_tile("refined-concrete", "lab-dark-1"), disguise_tile("refined-concrete", "lab-dark-2") })
end
