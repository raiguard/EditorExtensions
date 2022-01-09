local graphics_setting = settings.startup["ee-lab-tile-graphics"].value

if graphics_setting == "all-light" then
  local tile = table.deepcopy(data.raw["tile"]["lab-dark-2"])
  tile.name = "lab-dark-1"
  data:extend({ tile })
elseif graphics_setting == "all-dark" then
  local tile = table.deepcopy(data.raw["tile"]["lab-dark-1"])
  tile.name = "lab-dark-2"
  data:extend({ tile })
elseif graphics_setting == "tutorial-grid" then
  local tile_1 = table.deepcopy(data.raw["tile"]["tutorial-grid"])
  tile_1.name = "lab-dark-1"
  local tile_2 = table.deepcopy(data.raw["tile"]["tutorial-grid"])
  tile_2.name = "lab-dark-2"
  data:extend({ tile_1, tile_2 })
elseif graphics_setting == "refined-concrete" then
  local tile_1 = table.deepcopy(data.raw["tile"]["refined-concrete"])
  tile_1.name = "lab-dark-1"
  local tile_2 = table.deepcopy(data.raw["tile"]["refined-concrete"])
  tile_2.name = "lab-dark-2"
  data:extend({ tile_1, tile_2 })
end
