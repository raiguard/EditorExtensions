local constants = require("__EditorExtensions__/prototypes/constants")
local util = require("__EditorExtensions__/prototypes/util")

-- infinity accumulator
data:extend({
  {
    type = "item",
    name = "ee-infinity-accumulator",
    localised_description = { "entity-description.ee-infinity-accumulator" },
    stack_size = 50,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["accumulator"]["accumulator"], true)),
    place_result = "ee-infinity-accumulator-primary-output",
    subgroup = "ee-electricity",
    order = "a",
  },
})

local infinity_cargo_wagon = table.deepcopy(data.raw["item-with-entity-data"]["cargo-wagon"])
infinity_cargo_wagon.name = "ee-infinity-cargo-wagon"
infinity_cargo_wagon.icons = util.recursive_tint(util.extract_icon_info(infinity_cargo_wagon))
infinity_cargo_wagon.place_result = "ee-infinity-cargo-wagon"
infinity_cargo_wagon.subgroup = "ee-trains"
infinity_cargo_wagon.order = "ba"
infinity_cargo_wagon.stack_size = 50
data:extend({ infinity_cargo_wagon })

-- infinity and aggregate chests
do
  local ic_item = table.deepcopy(data.raw["item"]["infinity-chest"])
  util.extract_icon_info(ic_item)
  for _, t in pairs(constants.infinity_chest_data) do
    local lm = t.lm
    local suffix = lm and "-" .. lm or ""
    local chest = table.deepcopy(ic_item)
    chest.name = "ee-infinity-chest" .. suffix
    chest.localised_description = util.chest_description(suffix)
    chest.icons = { table.deepcopy(constants.infinity_chest_icon) }
    chest.icons[1].tint = t.t
    chest.stack_size = 50
    chest.place_result = "ee-infinity-chest" .. suffix
    chest.subgroup = "ee-inventories"
    chest.order = t.o
    chest.flags = {}
    data:extend({ chest })
  end

  for _, t in pairs(constants.aggregate_chest_data) do
    local lm = t.lm
    local suffix = lm and "-" .. lm or ""
    local chest = table.deepcopy(ic_item)
    chest.name = "ee-aggregate-chest" .. suffix
    chest.localised_description = util.chest_description(suffix, true)
    chest.icons = { table.deepcopy(constants.aggregate_chest_icon) }
    chest.icons[1].tint = t.t
    chest.stack_size = 50
    chest.place_result = "ee-aggregate-chest" .. suffix
    chest.subgroup = "ee-inventories"
    chest.order = t.o
    chest.flags = {}
    data:extend({ chest })
  end
end

local infinity_fluid_wagon = table.deepcopy(data.raw["item-with-entity-data"]["fluid-wagon"])
infinity_fluid_wagon.name = "ee-infinity-fluid-wagon"
infinity_fluid_wagon.icons = util.recursive_tint(util.extract_icon_info(infinity_fluid_wagon))
infinity_fluid_wagon.place_result = "ee-infinity-fluid-wagon"
infinity_fluid_wagon.subgroup = "ee-trains"
infinity_fluid_wagon.order = "bb"
infinity_fluid_wagon.stack_size = 50
data:extend({ infinity_fluid_wagon })

-- infinity fusion reactor
data:extend({
  {
    type = "item",
    name = "ee-infinity-fusion-reactor-equipment",
    icon_size = 32,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["fusion-reactor-equipment"], true)),
    subgroup = "ee-equipment",
    order = "aa",
    placed_as_equipment_result = "ee-infinity-fusion-reactor-equipment",
    stack_size = 50,
  },
})

local infinity_heat_pipe = table.deepcopy(data.raw["item"]["heat-interface"])
util.extract_icon_info(infinity_heat_pipe)
infinity_heat_pipe.name = "ee-infinity-heat-pipe"
infinity_heat_pipe.localised_description = { "entity-description.ee-infinity-heat-pipe" }
infinity_heat_pipe.subgroup = "ee-misc"
infinity_heat_pipe.order = "ca"
infinity_heat_pipe.stack_size = 50
infinity_heat_pipe.flags = {}
infinity_heat_pipe.icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["heat-pipe"], true))
infinity_heat_pipe.place_result = "ee-infinity-heat-pipe"
data:extend({ infinity_heat_pipe })

-- infinity loader
data:extend({
  {
    type = "item",
    name = "ee-infinity-loader",
    localised_name = { "entity-name.ee-infinity-loader" },
    localised_description = { "entity-description.ee-infinity-loader" },
    icons = util.recursive_tint({
      { icon = "__base__/graphics/icons/linked-belt.png", icon_size = 64, icon_mipmaps = 4 },
    }),
    stack_size = 50,
    subgroup = "ee-misc",
    order = "aa",
    place_result = "ee-infinity-loader",
  },
})

local infinity_pipe = table.deepcopy(data.raw["item"]["infinity-pipe"])
infinity_pipe.name = "ee-infinity-pipe"
infinity_pipe.icons = util.recursive_tint({ infinity_pipe.icons[1] })
infinity_pipe.subgroup = "ee-misc"
infinity_pipe.order = "ba"
infinity_pipe.stack_size = 50
infinity_pipe.place_result = "ee-infinity-pipe-100"
infinity_pipe.flags = {}
data:extend({ infinity_pipe })

local linked_belt = table.deepcopy(data.raw["item"]["linked-belt"])
linked_belt.name = "ee-linked-belt"
linked_belt.localised_description = { "item-description.ee-linked-belt" }
linked_belt.icons = util.extract_icon_info(linked_belt)
linked_belt.subgroup = "ee-misc"
linked_belt.order = "ab"
linked_belt.stack_size = 50
linked_belt.flags = {}
linked_belt.place_result = "ee-linked-belt"
util.recursive_tint(linked_belt, constants.linked_belt_tint)
data:extend({ linked_belt })

local linked_chest = table.deepcopy(data.raw["item"]["linked-chest"])
linked_chest.name = "ee-linked-chest"
linked_chest.icons = {
  { icon = "__EditorExtensions__/graphics/item/linked-chest.png", icon_size = 64, icon_mipmaps = 4 },
}
linked_chest.subgroup = "ee-inventories"
linked_chest.order = "c"
linked_chest.stack_size = 50
linked_chest.place_result = "ee-linked-chest"
linked_chest.flags = {}
util.recursive_tint(linked_chest, constants.infinity_chest_data[1].t)
data:extend({ linked_chest })

local super_beacon = table.deepcopy(data.raw["item"]["beacon"])
super_beacon.name = "ee-super-beacon"
super_beacon.icons = util.recursive_tint(util.extract_icon_info(super_beacon))
super_beacon.place_result = "ee-super-beacon"
super_beacon.subgroup = "ee-modules"
super_beacon.order = "aa"
data:extend({ super_beacon })

local super_construction_robot = table.deepcopy(data.raw["item"]["construction-robot"])
super_construction_robot.name = "ee-super-construction-robot"
super_construction_robot.icons = util.recursive_tint(util.extract_icon_info(super_construction_robot))
super_construction_robot.place_result = "ee-super-construction-robot"
super_construction_robot.subgroup = "ee-robots"
super_construction_robot.order = "ba"
super_construction_robot.stack_size = 100
data:extend({ super_construction_robot })

local super_electric_pole = table.deepcopy(data.raw["item"]["big-electric-pole"])
super_electric_pole.name = "ee-super-electric-pole"
super_electric_pole.icons = util.recursive_tint(util.extract_icon_info(super_electric_pole))
super_electric_pole.place_result = "ee-super-electric-pole"
super_electric_pole.subgroup = "ee-electricity"
super_electric_pole.order = "ba"
data:extend({ super_electric_pole })

-- super energy shield
data:extend({
  {
    type = "item",
    name = "ee-super-energy-shield-equipment",
    icon_size = 32,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["energy-shield-equipment"], true)),
    subgroup = "ee-equipment",
    order = "ad",
    placed_as_equipment_result = "ee-super-energy-shield-equipment",
    stack_size = 50,
  },
})

-- super exoskeleton
data:extend({
  {
    type = "item",
    name = "ee-super-exoskeleton-equipment",
    icon_size = 32,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["exoskeleton-equipment"], true)),
    subgroup = "ee-equipment",
    order = "ac",
    placed_as_equipment_result = "ee-super-exoskeleton-equipment",
    stack_size = 50,
  },
})

local super_fuel = table.deepcopy(data.raw["item"]["nuclear-fuel"])
util.extract_icon_info(super_fuel)
super_fuel.name = "ee-super-fuel"
super_fuel.icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["rocket-fuel"], true))
super_fuel.stack_size = 100
super_fuel.fuel_value = "1000YJ"
super_fuel.subgroup = "ee-trains"
super_fuel.order = "c"
data:extend({ super_fuel })

local super_inserter = table.deepcopy(data.raw["item"]["filter-inserter"])
super_inserter.name = "ee-super-inserter"
super_inserter.icons = util.recursive_tint(util.extract_icon_info(super_inserter))
super_inserter.place_result = "ee-super-inserter"
super_inserter.subgroup = "ee-misc"
super_inserter.order = "ac"
data:extend({ super_inserter })

local super_lab = table.deepcopy(data.raw["item"]["lab"])
super_lab.name = "ee-super-lab"
super_lab.icons = util.recursive_tint(util.extract_icon_info(super_lab))
super_lab.place_result = "ee-super-lab"
super_lab.subgroup = "ee-misc"
super_lab.order = "ea"
data:extend({ super_lab })

local super_locomotive = table.deepcopy(data.raw["item-with-entity-data"]["locomotive"])
super_locomotive.name = "ee-super-locomotive"
super_locomotive.icons = util.recursive_tint(util.extract_icon_info(super_locomotive))
super_locomotive.place_result = "ee-super-locomotive"
super_locomotive.subgroup = "ee-trains"
super_locomotive.order = "aa"
super_locomotive.stack_size = 50
data:extend({ super_locomotive })

local super_logistic_robot = table.deepcopy(data.raw["item"]["logistic-robot"])
super_logistic_robot.name = "ee-super-logistic-robot"
super_logistic_robot.icons = util.recursive_tint(util.extract_icon_info(super_logistic_robot))
super_logistic_robot.place_result = "ee-super-logistic-robot"
super_logistic_robot.subgroup = "ee-robots"
super_logistic_robot.order = "bb"
super_logistic_robot.stack_size = 100
data:extend({ super_logistic_robot })

-- super night vision
data:extend({
  {
    type = "item",
    name = "ee-super-night-vision-equipment",
    icon_size = 32,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["night-vision-equipment"], true)),
    subgroup = "ee-equipment",
    order = "ae",
    placed_as_equipment_result = "ee-super-night-vision-equipment",
    stack_size = 50,
  },
})

-- super personal battery
data:extend({
  {
    type = "item",
    name = "ee-super-battery-equipment",
    icon_size = 32,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["battery-equipment"], true)),
    subgroup = "ee-equipment",
    order = "af",
    placed_as_equipment_result = "ee-super-battery-equipment",
    stack_size = 50,
  },
})

-- super personal roboport
data:extend({
  {
    type = "item",
    name = "ee-super-personal-roboport-equipment",
    icon_size = 32,
    icons = util.recursive_tint(util.extract_icon_info(data.raw["item"]["personal-roboport-mk2-equipment"], true)),
    subgroup = "ee-equipment",
    order = "ab",
    placed_as_equipment_result = "ee-super-personal-roboport-equipment",
    stack_size = 50,
  },
})

local super_pump = table.deepcopy(data.raw["item"]["pump"])
super_pump.name = "ee-super-pump"
super_pump.icons = util.recursive_tint(util.extract_icon_info(super_pump))
super_pump.place_result = "ee-super-pump"
super_pump.subgroup = "ee-misc"
super_pump.order = "bb"
data:extend({ super_pump })

local super_radar = table.deepcopy(data.raw["item"]["radar"])
super_radar.name = "ee-super-radar"
super_radar.icons = util.recursive_tint(util.extract_icon_info(super_radar))
super_radar.place_result = "ee-super-radar"
super_radar.subgroup = "ee-misc"
super_radar.order = "da"
data:extend({ super_radar })

local super_roboport = table.deepcopy(data.raw["item"]["roboport"])
super_roboport.name = "ee-super-roboport"
super_roboport.icons = util.recursive_tint(util.extract_icon_info(super_roboport))
super_roboport.place_result = "ee-super-roboport"
super_roboport.subgroup = "ee-robots"
super_roboport.order = "a"
super_roboport.stack_size = 50
data:extend({ super_roboport })

local super_substation = table.deepcopy(data.raw["item"]["substation"])
super_substation.name = "ee-super-substation"
super_substation.icons = util.recursive_tint(util.extract_icon_info(super_substation))
super_substation.place_result = "ee-super-substation"
super_substation.subgroup = "ee-electricity"
super_substation.order = "bb"
data:extend({ super_substation })
