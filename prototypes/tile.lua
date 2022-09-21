local function generate_tile(source_name, destination_name)
  local tile = table.deepcopy(data.raw["tile"][source_name])
  tile.name = destination_name
  tile.variants = {
    main = tile.variants.main,
    material_background = tile.variants.material_background,
    empty_transitions = true,
  }
  tile.transitions = nil
  return tile
end

local graphics_setting = settings.startup["ee-lab-tile-graphics"].value

if graphics_setting == "all-light" then
  data:extend({ generate_tile("lab-dark-2", "lab-dark-1") })
elseif graphics_setting == "all-dark" then
  data:extend({ generate_tile("lab-dark-1", "lab-dark-2") })
elseif graphics_setting == "tutorial-grid" then
  data:extend({ generate_tile("tutorial-grid", "lab-dark-1"), generate_tile("tutorial-grid", "lab-dark-2") })
elseif graphics_setting == "refined-concrete" then
  data:extend({ generate_tile("refined-concrete", "lab-dark-1"), generate_tile("refined-concrete", "lab-dark-2") })
end
