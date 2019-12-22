-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ITEMS
-- We mostly copy the vanilla definitions instead of creating our own, so many vanilla changes will be immediately reflected in the mod.

-- INFINITY ACCUMULATOR
data:extend{
  {
    type = 'item',
    name = 'infinity-accumulator',
    stack_size = 50,
    icons = recursive_tint{extract_icon_info(data.raw['accumulator']['accumulator'])},
    place_result = 'infinity-accumulator-primary-output',
    subgroup = 'ee-electricity',
    order = 'a',
    flags = {'hidden'}
  }
}

-- INFINITY BEACON
local infinity_beacon = table.deepcopy(data.raw['item']['beacon'])
infinity_beacon.name = 'infinity-beacon'
infinity_beacon.icons = recursive_tint{extract_icon_info(infinity_beacon)}
infinity_beacon.place_result = 'infinity-beacon'
infinity_beacon.subgroup='ee-modules'
infinity_beacon.order = 'aa'
infinity_beacon.flags = {'hidden'}
data:extend{infinity_beacon}

-- INFINITY AND TESSERACT CHESTS
do
  -- modify existing infinity-chest item
  local ic_item = data.raw['item']['infinity-chest']
  ic_item.subgroup = 'ee-inventories'
  ic_item.order = 'aa'
  ic_item.stack_size = 50
  ic_item.flags = {'hidden'}

  -- create logistic chest items
  ic_item = table.deepcopy(data.raw['item']['infinity-chest'])
  for lm,d in pairs(infinity_chest_data) do
    local chest = table.deepcopy(ic_item)
    chest.name = 'infinity-chest-' .. lm
    chest.localised_description = {'', {'entity-description.infinity-chest'}, '\n', {'entity-description.logistic-chest-'..lm}}
    chest.icons = {{icon=chest.icon, icon_size=chest.icon_size, icon_mipmaps=chest.icon_mipmaps, tint=d.t}}
    chest.place_result = 'infinity-chest-' .. lm
    chest.order = d.o
    data:extend{chest}
  end

  local base_comp_chest = data.raw['container']['compilatron-chest']

  -- create tesseract chest items
  for lm,d in pairs(tesseract_chest_data) do
    local suffix = lm == '' and lm or '-'..lm
    local chest = table.deepcopy(ic_item)
    chest.name = 'tesseract-chest'..suffix
    chest.localised_description = {'', {'entity-description.tesseract-chest'}, lm ~= '' and {'', '\n', {'entity-description.logistic-chest-'..lm}} or '',
                  '\n[color=255,57,48]', {'entity-description.tesseract-chest-warning'}, '[/color]'}
    chest.icons = {{icon=base_comp_chest.icon, icon_size=base_comp_chest.icon_size, icon_mipmaps=base_comp_chest.icon_mipmaps, tint=d.t}}
    chest.place_result = 'tesseract-chest'..suffix
    chest.order = d.o
    data:extend{chest}
  end
end

-- INFINITY CONSTANT COMBINATOR
data:extend{
  {
    type = 'item',
    name = 'infinity-combinator',
    stack_size = 50,
    icons = recursive_tint({extract_icon_info(data.raw['constant-combinator']['constant-combinator'])}, combinator_tint),
    place_result = 'infinity-combinator',
    subgroup = 'ee-electricity',
    order = 'z',
    flags = {'hidden'}
  }
}

-- INFINITY FUSION REACTOR
data:extend{
  {
    type = 'item',
    name = 'infinity-fusion-reactor-equipment',
    icon_size = 32,
    icons = recursive_tint{extract_icon_info(data.raw['item']['fusion-reactor-equipment'])},
    subgroup = 'ee-equipment',
    order = 'aa',
    placed_as_equipment_result = 'infinity-fusion-reactor-equipment',
    stack_size = 50,
    flags = {'hidden'}
  }
}

-- INFINITY ELECTRIC POLES
local infinity_electric_pole = table.deepcopy(data.raw['item']['big-electric-pole'])
infinity_electric_pole.name = 'infinity-electric-pole'
infinity_electric_pole.icons = recursive_tint{extract_icon_info(infinity_electric_pole)}
infinity_electric_pole.place_result = 'infinity-electric-pole'
infinity_electric_pole.subgroup = 'ee-electricity'
infinity_electric_pole.order = 'ba'
infinity_electric_pole.flags = {'hidden'}
local infinity_substation = table.deepcopy(data.raw['item']['substation'])
infinity_substation.name = 'infinity-substation'
infinity_substation.icons = recursive_tint{extract_icon_info(infinity_substation)}
infinity_substation.place_result = 'infinity-substation'
infinity_substation.subgroup = 'ee-electricity'
infinity_substation.order = 'bb'
infinity_substation.flags = {'hidden'}
data:extend{infinity_electric_pole, infinity_substation}

-- INFINITY FUEL
local infinity_fuel = table.deepcopy(data.raw['item']['nuclear-fuel'])
infinity_fuel.name = 'infinity-fuel'
infinity_fuel.icons = recursive_tint{extract_icon_info(infinity_fuel)}
infinity_fuel.stack_size = 100
infinity_fuel.fuel_value = '1000YJ'
infinity_fuel.subgroup = 'ee-trains'
infinity_fuel.order = 'c'
infinity_fuel.flags = {'hidden'}
data:extend{infinity_fuel}

-- INFINITY HEAT PIPE
local infinity_heat_pipe = data.raw['item']['heat-interface']
infinity_heat_pipe.subgroup = 'ee-misc'
infinity_heat_pipe.order = 'ca'
infinity_heat_pipe.stack_size = 50
infinity_heat_pipe.icons = recursive_tint{extract_icon_info(data.raw['item']['heat-pipe'])}
infinity_heat_pipe.flags = {'hidden'}

-- INFINITY INSERTER
local infinity_inserter = table.deepcopy(data.raw['item']['filter-inserter'])
infinity_inserter.name = 'infinity-inserter'
infinity_inserter.icons = recursive_tint{extract_icon_info(infinity_inserter)}
infinity_inserter.place_result = 'infinity-inserter'
infinity_inserter.subgroup = 'ee-misc'
infinity_inserter.order = 'ab'
infinity_inserter.flags = {'hidden'}
data:extend{infinity_inserter}

-- INFINITY LAB
local infinity_lab = table.deepcopy(data.raw['item']['lab'])
infinity_lab.name = 'infinity-lab'
infinity_lab.icons = recursive_tint{extract_icon_info(infinity_lab)}
infinity_lab.place_result = 'infinity-lab'
infinity_lab.subgroup = 'ee-misc'
infinity_lab.order = 'ea'
infinity_lab.flags = {'hidden'}
data:extend{infinity_lab}

-- INFINITY LOADER
data:extend{
  {
    type = 'item',
    name = 'infinity-loader',
    localised_name = {'entity-name.infinity-loader'},
    icons = recursive_tint{{icon='__EditorExtensions__/graphics/item/infinity-loader.png', icon_size=32, icon_mipmaps=0}},
    stack_size = 50,
    place_result = 'infinity-loader-dummy-combinator',
    subgroup = 'ee-misc',
    order = 'aa',
    flags = {'hidden'}
  }
}

-- INFINITY LOCOMOTIVE
local infinity_locomotive = table.deepcopy(data.raw['item-with-entity-data']['locomotive'])
infinity_locomotive.name = 'infinity-locomotive'
infinity_locomotive.icons = recursive_tint{extract_icon_info(infinity_locomotive)}
infinity_locomotive.place_result = 'infinity-locomotive'
infinity_locomotive.subgroup = 'ee-trains'
infinity_locomotive.order = 'aa'
infinity_locomotive.stack_size = 50
infinity_locomotive.flags = {'hidden'}
data:extend{infinity_locomotive}

-- INFINITY PERSONAL ROBOPORT
data:extend{
  {
    type = 'item',
    name = 'infinity-personal-roboport-equipment',
    icon_size = 32,
    icons = recursive_tint{extract_icon_info(data.raw['item']['personal-roboport-equipment'])},
    subgroup = 'ee-equipment',
    order = 'ab',
    placed_as_equipment_result = 'infinity-personal-roboport-equipment',
    stack_size = 50,
    flags = {'hidden'}
  }
}

-- INFINITY PIPE
local infinity_pipe = data.raw['item']['infinity-pipe']
infinity_pipe.icons = recursive_tint{infinity_pipe.icons[1]}
infinity_pipe.subgroup = 'ee-misc'
infinity_pipe.order = 'ba'
infinity_pipe.stack_size = 50
infinity_pipe.flags = {'hidden'}

-- INFINITY PUMP
local infinity_pump = table.deepcopy(data.raw['item']['pump'])
infinity_pump.name = 'infinity-pump'
infinity_pump.icons = recursive_tint{extract_icon_info(infinity_pump)}
infinity_pump.place_result = 'infinity-pump'
infinity_pump.subgroup = 'ee-misc'
infinity_pump.order = 'bb'
infinity_pump.flags = {'hidden'}
data:extend{infinity_pump}

-- INFINITY RADAR
local infinity_radar = table.deepcopy(data.raw['item']['radar'])
infinity_radar.name = 'infinity-radar'
infinity_radar.icons = recursive_tint{extract_icon_info(infinity_radar)}
infinity_radar.place_result = 'infinity-radar'
infinity_radar.subgroup = 'ee-misc'
infinity_radar.order = 'da'
infinity_radar.flags = {'hidden'}
data:extend{infinity_radar}

-- INFINITY ROBOPORT
local infinity_roboport = table.deepcopy(data.raw['item']['roboport'])
infinity_roboport.name = 'infinity-roboport'
infinity_roboport.icons = recursive_tint{extract_icon_info(infinity_roboport)}
infinity_roboport.place_result = 'infinity-roboport'
infinity_roboport.subgroup = 'ee-robots'
infinity_roboport.order = 'a'
infinity_roboport.stack_size = 50
infinity_roboport.flags = {'hidden'}
data:extend{infinity_roboport}

-- INFINITY ROBOTS
local infinity_construction_robot = table.deepcopy(data.raw['item']['construction-robot'])
infinity_construction_robot.name = 'infinity-construction-robot'
infinity_construction_robot.icons = recursive_tint{extract_icon_info(infinity_construction_robot)}
infinity_construction_robot.place_result = 'infinity-construction-robot'
infinity_construction_robot.subgroup = 'ee-robots'
infinity_construction_robot.order = 'ba'
infinity_construction_robot.stack_size = 100
infinity_construction_robot.flags = {'hidden'}
local infinity_logistic_robot = table.deepcopy(data.raw['item']['logistic-robot'])
infinity_logistic_robot.name = 'infinity-logistic-robot'
infinity_logistic_robot.icons = recursive_tint{extract_icon_info(infinity_logistic_robot)}
infinity_logistic_robot.place_result = 'infinity-logistic-robot'
infinity_logistic_robot.subgroup = 'ee-robots'
infinity_logistic_robot.order = 'bb'
infinity_logistic_robot.stack_size = 100
infinity_logistic_robot.flags = {'hidden'}
data:extend{infinity_construction_robot, infinity_logistic_robot}

-- INFINITY WAGONS
local infinity_cargo_wagon = table.deepcopy(data.raw['item-with-entity-data']['cargo-wagon'])
infinity_cargo_wagon.name = 'infinity-cargo-wagon'
infinity_cargo_wagon.icons = recursive_tint{extract_icon_info(infinity_cargo_wagon)}
infinity_cargo_wagon.place_result = 'infinity-cargo-wagon'
infinity_cargo_wagon.subgroup = 'ee-trains'
infinity_cargo_wagon.order = 'ba'
infinity_cargo_wagon.stack_size = 50
infinity_cargo_wagon.flags = {'hidden'}
local infinity_fluid_wagon = table.deepcopy(data.raw['item-with-entity-data']['fluid-wagon'])
infinity_fluid_wagon.name = 'infinity-fluid-wagon'
infinity_fluid_wagon.icons = recursive_tint{extract_icon_info(infinity_fluid_wagon)}
infinity_fluid_wagon.place_result = 'infinity-fluid-wagon'
infinity_fluid_wagon.subgroup = 'ee-trains'
infinity_fluid_wagon.order = 'bb'
infinity_fluid_wagon.stack_size = 50
infinity_fluid_wagon.flags = {'hidden'}
data:extend{infinity_cargo_wagon, infinity_fluid_wagon}
