-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ITEMS
-- We mostly copy the vanilla definitions instead of creating our own, so many vanilla changes will be immediately reflected in the mod.

local util = require("prototypes.util")

-- INFINITY ACCUMULATOR
data:extend{
  {
    type = "item",
    name = "ee-infinity-accumulator",
    stack_size = 50,
    icons = util.recursive_tint{util.extract_icon_info(data.raw["accumulator"]["accumulator"])},
    place_result = "ee-infinity-accumulator-primary-output",
    subgroup = "ee-electricity",
    order = "a"
  }
}

-- INFINITY BEACON
local infinity_beacon = table.deepcopy(data.raw["item"]["beacon"])
infinity_beacon.name = "ee-infinity-beacon"
infinity_beacon.icons = util.recursive_tint{util.extract_icon_info(infinity_beacon)}
infinity_beacon.place_result = "ee-infinity-beacon"
infinity_beacon.subgroup="ee-modules"
infinity_beacon.order = "aa"
data:extend{infinity_beacon}

-- INFINITY AND TESSERACT CHESTS
do
  -- create infinity chest items
  local ic_item = table.deepcopy(data.raw["item"]["infinity-chest"])
  for _,t in pairs(util.infinity_chest_data) do
    local lm = t.lm
    local suffix = lm and "-"..lm or ""
    local chest = table.deepcopy(ic_item)
    chest.name = "ee-infinity-chest"..suffix
    chest.localised_description = util.chest_description(suffix)
    chest.icons = {table.deepcopy(util.infinity_chest_icon)}
    chest.icons[1].tint = t.t
    chest.stack_size = 50
    chest.place_result = "ee-infinity-chest"..suffix
    chest.subgroup = "ee-inventories"
    chest.order = t.o
    chest.flags = {}
    data:extend{chest}
  end

  -- create tesseract chest items
  for _,t in pairs(util.tesseract_chest_data) do
    local lm = t.lm
    local suffix = lm and "-"..lm or ""
    local chest = table.deepcopy(ic_item)
    chest.name = "ee-tesseract-chest"..suffix
    chest.localised_description = util.chest_description(suffix, true)
    chest.icons = {table.deepcopy(util.tesseract_chest_icon)}
    chest.icons[1].tint = t.t
    chest.stack_size = 50
    chest.place_result = "ee-tesseract-chest"..suffix
    chest.subgroup = "ee-inventories"
    chest.order = t.o
    chest.flags = {}
    data:extend{chest}
  end
end

-- INFINITY CONSTANT COMBINATOR
data:extend{
  {
    type = "item",
    name = "ee-infinity-combinator",
    stack_size = 50,
    icons = util.recursive_tint({util.extract_icon_info(data.raw["constant-combinator"]["constant-combinator"])}, util.combinator_tint),
    place_result = "ee-infinity-combinator",
    subgroup = "ee-electricity",
    order = "z"
  }
}

-- INFINITY EXOSKELETON
data:extend{
  {
    type = "item",
    name = "ee-infinity-exoskeleton-equipment",
    icon_size = 32,
    icons = util.recursive_tint{util.extract_icon_info(data.raw["item"]["exoskeleton-equipment"])},
    subgroup = "ee-equipment",
    order = "ac",
    placed_as_equipment_result = "ee-infinity-exoskeleton-equipment",
    stack_size = 50
  }
}

-- INFINITY FUSION REACTOR
data:extend{
  {
    type = "item",
    name = "ee-infinity-fusion-reactor-equipment",
    icon_size = 32,
    icons = util.recursive_tint{util.extract_icon_info(data.raw["item"]["fusion-reactor-equipment"])},
    subgroup = "ee-equipment",
    order = "aa",
    placed_as_equipment_result = "ee-infinity-fusion-reactor-equipment",
    stack_size = 50
  }
}

-- INFINITY ELECTRIC POLES
local infinity_electric_pole = table.deepcopy(data.raw["item"]["big-electric-pole"])
infinity_electric_pole.name = "ee-infinity-electric-pole"
infinity_electric_pole.icons = util.recursive_tint{util.extract_icon_info(infinity_electric_pole)}
infinity_electric_pole.place_result = "ee-infinity-electric-pole"
infinity_electric_pole.subgroup = "ee-electricity"
infinity_electric_pole.order = "ba"
local infinity_substation = table.deepcopy(data.raw["item"]["substation"])
infinity_substation.name = "ee-infinity-substation"
infinity_substation.icons = util.recursive_tint{util.extract_icon_info(infinity_substation)}
infinity_substation.place_result = "ee-infinity-substation"
infinity_substation.subgroup = "ee-electricity"
infinity_substation.order = "bb"
data:extend{infinity_electric_pole, infinity_substation}

-- INFINITY FUEL
local infinity_fuel = table.deepcopy(data.raw["item"]["nuclear-fuel"])
infinity_fuel.name = "ee-infinity-fuel"
infinity_fuel.icons = util.recursive_tint{util.extract_icon_info(data.raw["item"]["rocket-fuel"])}
infinity_fuel.stack_size = 100
infinity_fuel.fuel_value = "1000YJ"
infinity_fuel.subgroup = "ee-trains"
infinity_fuel.order = "c"
data:extend{infinity_fuel}

-- INFINITY HEAT PIPE
local infinity_heat_pipe = table.deepcopy(data.raw["item"]["heat-interface"])
infinity_heat_pipe.name = "ee-infinity-heat-pipe"
infinity_heat_pipe.localised_description = {"entity-description.ee-infinity-heat-pipe"}
infinity_heat_pipe.subgroup = "ee-misc"
infinity_heat_pipe.order = "ca"
infinity_heat_pipe.stack_size = 50
infinity_heat_pipe.flags = {}
infinity_heat_pipe.icons = util.recursive_tint{util.extract_icon_info(data.raw["item"]["heat-pipe"])}
infinity_heat_pipe.place_result = "ee-infinity-heat-pipe"
data:extend{infinity_heat_pipe}

-- INFINITY INSERTER
local infinity_inserter = table.deepcopy(data.raw["item"]["filter-inserter"])
infinity_inserter.name = "ee-infinity-inserter"
infinity_inserter.icons = util.recursive_tint{util.extract_icon_info(infinity_inserter)}
infinity_inserter.place_result = "ee-infinity-inserter"
infinity_inserter.subgroup = "ee-misc"
infinity_inserter.order = "ab"
data:extend{infinity_inserter}

-- INFINITY LAB
local infinity_lab = table.deepcopy(data.raw["item"]["lab"])
infinity_lab.name = "ee-infinity-lab"
infinity_lab.icons = util.recursive_tint{util.extract_icon_info(infinity_lab)}
infinity_lab.place_result = "ee-infinity-lab"
infinity_lab.subgroup = "ee-misc"
infinity_lab.order = "ea"
data:extend{infinity_lab}

-- INFINITY LOADER
data:extend{
  {
    type = "item",
    name = "ee-infinity-loader",
    localised_name = {"entity-name.ee-infinity-loader"},
    icons = util.recursive_tint{{icon="__EditorExtensions__/graphics/item/infinity-loader.png", icon_size=64, icon_mipmaps=4}},
    stack_size = 50,
    place_result = "ee-infinity-loader-dummy-combinator",
    subgroup = "ee-misc",
    order = "aa"
  }
}

-- INFINITY LOCOMOTIVE
local infinity_locomotive = table.deepcopy(data.raw["item-with-entity-data"]["locomotive"])
infinity_locomotive.name = "ee-infinity-locomotive"
infinity_locomotive.icons = util.recursive_tint{util.extract_icon_info(infinity_locomotive)}
infinity_locomotive.place_result = "ee-infinity-locomotive"
infinity_locomotive.subgroup = "ee-trains"
infinity_locomotive.order = "aa"
infinity_locomotive.stack_size = 50
data:extend{infinity_locomotive}

-- INFINITY PERSONAL ROBOPORT
data:extend{
  {
    type = "item",
    name = "ee-infinity-personal-roboport-equipment",
    icon_size = 32,
    icons = util.recursive_tint{util.extract_icon_info(data.raw["item"]["personal-roboport-equipment"])},
    subgroup = "ee-equipment",
    order = "ab",
    placed_as_equipment_result = "ee-infinity-personal-roboport-equipment",
    stack_size = 50
  }
}

-- INFINITY PIPE
local infinity_pipe = table.deepcopy(data.raw["item"]["infinity-pipe"])
infinity_pipe.name = "ee-infinity-pipe"
infinity_pipe.icons = util.recursive_tint{infinity_pipe.icons[1]}
infinity_pipe.subgroup = "ee-misc"
infinity_pipe.order = "ba"
infinity_pipe.stack_size = 50
infinity_pipe.place_result = "ee-infinity-pipe"
data:extend{infinity_pipe}

-- INFINITY PUMP
local infinity_pump = table.deepcopy(data.raw["item"]["pump"])
infinity_pump.name = "ee-infinity-pump"
infinity_pump.icons = util.recursive_tint{util.extract_icon_info(infinity_pump)}
infinity_pump.place_result = "ee-infinity-pump"
infinity_pump.subgroup = "ee-misc"
infinity_pump.order = "bb"
data:extend{infinity_pump}

-- INFINITY RADAR
local infinity_radar = table.deepcopy(data.raw["item"]["radar"])
infinity_radar.name = "ee-infinity-radar"
infinity_radar.icons = util.recursive_tint{util.extract_icon_info(infinity_radar)}
infinity_radar.place_result = "ee-infinity-radar"
infinity_radar.subgroup = "ee-misc"
infinity_radar.order = "da"
data:extend{infinity_radar}

-- INFINITY ROBOPORT
local infinity_roboport = table.deepcopy(data.raw["item"]["roboport"])
infinity_roboport.name = "ee-infinity-roboport"
infinity_roboport.icons = util.recursive_tint{util.extract_icon_info(infinity_roboport)}
infinity_roboport.place_result = "ee-infinity-roboport"
infinity_roboport.subgroup = "ee-robots"
infinity_roboport.order = "a"
infinity_roboport.stack_size = 50
data:extend{infinity_roboport}

-- INFINITY ROBOTS
local infinity_construction_robot = table.deepcopy(data.raw["item"]["construction-robot"])
infinity_construction_robot.name = "ee-infinity-construction-robot"
infinity_construction_robot.icons = util.recursive_tint{util.extract_icon_info(infinity_construction_robot)}
infinity_construction_robot.place_result = "ee-infinity-construction-robot"
infinity_construction_robot.subgroup = "ee-robots"
infinity_construction_robot.order = "ba"
infinity_construction_robot.stack_size = 100
local infinity_logistic_robot = table.deepcopy(data.raw["item"]["logistic-robot"])
infinity_logistic_robot.name = "ee-infinity-logistic-robot"
infinity_logistic_robot.icons = util.recursive_tint{util.extract_icon_info(infinity_logistic_robot)}
infinity_logistic_robot.place_result = "ee-infinity-logistic-robot"
infinity_logistic_robot.subgroup = "ee-robots"
infinity_logistic_robot.order = "bb"
infinity_logistic_robot.stack_size = 100
data:extend{infinity_construction_robot, infinity_logistic_robot}

-- INFINITY WAGONS
local infinity_cargo_wagon = table.deepcopy(data.raw["item-with-entity-data"]["cargo-wagon"])
infinity_cargo_wagon.name = "ee-infinity-cargo-wagon"
infinity_cargo_wagon.icons = util.recursive_tint{util.extract_icon_info(infinity_cargo_wagon)}
infinity_cargo_wagon.place_result = "ee-infinity-cargo-wagon"
infinity_cargo_wagon.subgroup = "ee-trains"
infinity_cargo_wagon.order = "ba"
infinity_cargo_wagon.stack_size = 50
local infinity_fluid_wagon = table.deepcopy(data.raw["item-with-entity-data"]["fluid-wagon"])
infinity_fluid_wagon.name = "ee-infinity-fluid-wagon"
infinity_fluid_wagon.icons = util.recursive_tint{util.extract_icon_info(infinity_fluid_wagon)}
infinity_fluid_wagon.place_result = "ee-infinity-fluid-wagon"
infinity_fluid_wagon.subgroup = "ee-trains"
infinity_fluid_wagon.order = "bb"
infinity_fluid_wagon.stack_size = 50
data:extend{infinity_cargo_wagon, infinity_fluid_wagon}
