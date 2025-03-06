local flib_table = require("__flib__.table")
local meld = require("meld")
local sounds = require("__base__.prototypes.entity.sounds")

local constants = require("prototypes.constants")
local util = require("prototypes.util")

-- INFINITY ACCUMULATOR
do
  local base_entity = flib_table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
  -- buffer size for 500 GW
  base_entity.energy_source = {
    type = "electric",
    buffer_capacity = "8.333333333333333333333333333333333333333333333GJ",
  }
  base_entity.friendly_map_color = constants.infinity_tint
  base_entity.localised_description = { "entity-description.ee-infinity-accumulator" }
  base_entity.localised_name = { "entity-name.ee-infinity-accumulator" }
  base_entity.map_color = constants.infinity_tint
  base_entity.minable.result = "ee-infinity-accumulator"
  base_entity.order = "a"
  base_entity.placeable_by = { item = "ee-infinity-accumulator", count = 1 }
  base_entity.subgroup = "ee-electricity"
  util.recursive_tint(base_entity)

  for _, entity_data in ipairs(constants.infinity_accumulator_data) do
    local entity = flib_table.deepcopy(base_entity)
    entity.name = "ee-infinity-accumulator-" .. entity_data.name
    entity.energy_source.usage_priority = entity_data.priority
    entity.energy_source.render_no_power_icon = entity_data.render_no_power_icon
    data:extend({ entity })
  end
end

-- INFINITY AND AGGREGATE CHESTS
do
  local infinity_chest_picture = {
    layers = {
      {
        filename = "__EditorExtensions__/graphics/entity/infinity-chest/infinity-chest.png",
        priority = "extra-high",
        width = 68,
        height = 84,
        shift = util.by_pixel(0, -3),
        scale = 0.5,
      },
      {
        filename = "__EditorExtensions__/graphics/entity/infinity-chest/infinity-chest-shadow.png",
        priority = "extra-high",
        width = 116,
        height = 48,
        shift = util.by_pixel(12, 6),
        draw_as_shadow = true,
        scale = 0.5,
      },
    },
  }

  local base_entity = flib_table.deepcopy(data.raw["infinity-container"]["infinity-chest"])
  util.extract_icon_info(base_entity)
  for _, t in pairs(constants.infinity_chest_data) do
    local lm = t.lm
    local suffix = lm and "-" .. lm or ""
    local chest = flib_table.deepcopy(base_entity)
    chest.name = "ee-infinity-chest" .. suffix
    chest.localised_description = util.chest_description(lm or "")
    chest.icons = { flib_table.deepcopy(constants.infinity_chest_icon) }
    chest.map_color = constants.infinity_tint
    chest.friendly_map_color = constants.infinity_tint
    chest.picture = flib_table.deepcopy(infinity_chest_picture)
    chest.order = t.o
    chest.subgroup = "ee-inventories"
    chest.erase_contents_when_mined = true
    chest.logistic_mode = lm
    chest.max_logistic_slots = t.s
    chest.minable.result = "ee-infinity-chest" .. suffix
    chest.render_not_in_network_icon = true
    chest.inventory_size = 100
    chest.next_upgrade = nil
    chest.flags = { "player-creation" }
    chest.gui_mode = "all"
    util.recursive_tint(chest, t.t)
    data:extend({ chest })
  end

  -- aggregate chests
  -- create the chests here to let other mods modify them. increase their inventory size in data-final-fixes
  local aggregate_chest_picture = {
    layers = {
      {
        filename = "__EditorExtensions__/graphics/entity/aggregate-chest/aggregate-chest.png",
        priority = "extra-high",
        width = 68,
        height = 84,
        shift = util.by_pixel(0, -3),
        scale = 0.5,
      },
      {
        filename = "__EditorExtensions__/graphics/entity/aggregate-chest/aggregate-chest-shadow.png",
        priority = "extra-high",
        width = 116,
        height = 48,
        shift = util.by_pixel(12, 6),
        draw_as_shadow = true,
        scale = 0.5,
      },
    },
  }

  local aggregate_chest_mode = settings.startup["ee-allow-changing-aggregate-chest-filters"].value and "all" or "none"

  for _, t in pairs(constants.aggregate_chest_data) do
    local lm = t.lm
    local suffix = lm and "-" .. lm or ""
    local chest = flib_table.deepcopy(data.raw["infinity-container"]["ee-infinity-chest" .. suffix])
    chest.name = "ee-aggregate-chest" .. suffix
    chest.localised_description = util.chest_description(lm or "", true)
    chest.order = t.o
    chest.icons = { flib_table.deepcopy(constants.aggregate_chest_icon) }
    chest.picture = flib_table.deepcopy(aggregate_chest_picture)
    chest.minable.result = "ee-aggregate-chest" .. suffix
    chest.flags = { "player-creation", "hide-alt-info" }
    chest.gui_mode = aggregate_chest_mode
    util.recursive_tint(chest, t.t)
    data:extend({ chest })
  end
end

local infinity_heat_pipe = flib_table.deepcopy(data.raw["heat-interface"]["heat-interface"])
util.extract_icon_info(infinity_heat_pipe)
infinity_heat_pipe.name = "ee-infinity-heat-pipe"
infinity_heat_pipe.localised_description = { "entity-description.ee-infinity-heat-pipe" }
infinity_heat_pipe.gui_mode = "all"
infinity_heat_pipe.icons = util.extract_icon_info(data.raw["item"]["heat-pipe"], true)
infinity_heat_pipe.map_color = constants.infinity_tint
infinity_heat_pipe.friendly_map_color = constants.infinity_tint
infinity_heat_pipe.picture = {
  filename = "__base__/graphics/entity/heat-pipe/heat-pipe-t-1.png",
  width = 64,
  height = 64,
  scale = 0.5,
  flags = { "no-crop" },
}
infinity_heat_pipe.minable = { mining_time = 0.5, result = "ee-infinity-heat-pipe" }
infinity_heat_pipe.placeable_by = { item = "ee-infinity-heat-pipe", count = 1 }
util.recursive_tint(infinity_heat_pipe)
data:extend({ infinity_heat_pipe })

local super_inserter = flib_table.deepcopy(data.raw["inserter"]["bulk-inserter"])
super_inserter.name = "ee-super-inserter"
super_inserter.icons = util.extract_icon_info(super_inserter)
super_inserter.hidden_in_factoriopedia = true
super_inserter.map_color = constants.infinity_tint
super_inserter.friendly_map_color = constants.infinity_tint
super_inserter.placeable_by = { item = "ee-super-inserter", count = 1 }
super_inserter.minable.result = "ee-super-inserter"
super_inserter.energy_source = { type = "void" }
-- super_inserter.stack = true
super_inserter.extension_speed = 1
super_inserter.rotation_speed = 0.5
util.recursive_tint(super_inserter)
data:extend({ super_inserter })

data:extend({
  util.copy_prototype(data.raw["linked-belt"]["linked-belt"], {
    name = "ee-linked-belt",
    icons = "CONVERT",
    minable = { mining_time = 0.1, result = "ee-linked-belt" },
    belt_animation_set = flib_table.deepcopy(data.raw["transport-belt"]["express-transport-belt"].belt_animation_set),
  }, constants.linked_belt_tint),
  util.copy_prototype(data.raw["pipe"]["pipe"], {
    name = "ee-linked-pipe",
    icons = "CONVERT",
    minable = { mining_time = 0.1, result = "ee-linked-belt" },
    hidden = true,
  }, constants.linked_belt_tint),
  util.recursive_tint({
    type = "loader-1x1",
    name = "ee-infinity-loader",
    icons = { { icon = "__base__/graphics/icons/linked-belt.png", icon_size = 64 } },
    hidden_in_factoriopedia = true,
    map_color = constants.infinity_tint,
    friendly_map_color = constants.infinity_tint,
    flags = { "player-creation" },
    minable = { mining_time = 0.1, result = "ee-infinity-loader" },
    collision_box = { { -0.3, -0.3 }, { 0.3, 0.3 } },
    selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
    animation_speed_coefficient = 32,
    belt_animation_set = flib_table.deepcopy(data.raw["transport-belt"]["fast-transport-belt"].belt_animation_set),
    speed = 0.03125, -- Temporary, will be overwritten in data-final-fixes
    container_distance = 0,
    filter_count = 2,
    per_lane_filters = true,
    max_belt_stack_size = feature_flags.space_travel and 255 or nil,
    adjustable_belt_stack_size = feature_flags.space_travel,
    structure = meld(
      table.deepcopy(data.raw["linked-belt"]["linked-belt"].structure),
      { direction_in_side_loading = meld.delete(), direction_out_side_loading = meld.delete() }
    ),
    open_sound = sounds.machine_open,
    close_sound = sounds.machine_close,
    additional_pastable_entities = { "constant-combinator" },
    se_allow_in_space = mods["space-exploration"] and true or nil,
  }),
  {
    type = "infinity-container",
    name = "ee-infinity-loader-chest",
    erase_contents_when_mined = true,
    inventory_size = 10, -- Five for each belt lane
    flags = { "hide-alt-info", "player-creation" },
    hidden = true,
    selectable_in_game = false,
    picture = util.empty_sprite(),
    collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
  },
  util.copy_prototype(data.raw["constant-combinator"]["constant-combinator"], {
    name = "ee-infinity-loader-dummy-combinator",
    localised_description = { "entity-description.ee-infinity-loader" },
    icon = "__base__/graphics/icons/linked-belt.png",
    hidden = true,
    minable = { mining_time = 0.1 },
    placeable_by = { item = "ee-infinity-loader", count = 1 },
    flags = { "not-upgradable", "player-creation" },
    sprites = data.raw["constant-combinator"]["constant-combinator"].sprites,
  }, { r = 0.8, g = 0.8, b = 0.8 }),
})

-- Infinity pipe

local infinity_pipe = flib_table.deepcopy(data.raw["infinity-pipe"]["infinity-pipe"])
infinity_pipe.name = "ee-infinity-pipe"
infinity_pipe.map_color = constants.infinity_tint
infinity_pipe.friendly_map_color = constants.infinity_tint
infinity_pipe.gui_mode = "all"
infinity_pipe.icons = util.extract_icon_info(infinity_pipe)
infinity_pipe.minable = { mining_time = 0.5, result = "ee-infinity-pipe" }
infinity_pipe.placeable_by = { item = "ee-infinity-pipe", count = 1 }
infinity_pipe.additional_pastable_entities = { "constant-combinator" }
util.recursive_tint(infinity_pipe)
data:extend({ infinity_pipe })

-- Modify constant combinator to be pasteable to infinity pipes and infinity loaders
--- @type data.EntityID[]
local pastable =
  flib_table.get_or_insert(data.raw["constant-combinator"]["constant-combinator"], "additional_pastable_entities", {})
table.insert(pastable, "ee-infinity-pipe")
table.insert(pastable, "ee-infinity-loader")

-- infinity wagons
do
  local cargo_wagon = flib_table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])
  cargo_wagon.name = "ee-infinity-cargo-wagon"
  cargo_wagon.localised_description = {
    "",
    { "entity-description.ee-infinity-cargo-wagon" },
    "\n[color=255,57,48]",
    { "entity-description.ee-performance-warning" },
    "[/color]",
  }
  cargo_wagon.icons = util.extract_icon_info(cargo_wagon)
  cargo_wagon.hidden_in_factoriopedia = true
  cargo_wagon.inventory_size = 100
  cargo_wagon.max_speed = 10
  cargo_wagon.minable.result = "ee-infinity-cargo-wagon"
  cargo_wagon.minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-cargo-wagon-minimap.png",
    flags = { "icon" },
    scale = 0.5,
    size = { 20, 40 },
  }
  cargo_wagon.selected_minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-cargo-wagon-minimap-selected.png",
    flags = { "icon" },
    scale = 0.5,
    size = { 20, 40 },
  }
  util.recursive_tint(cargo_wagon)

  local fluid_wagon = flib_table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])
  fluid_wagon.name = "ee-infinity-fluid-wagon"
  fluid_wagon.localised_description = {
    "",
    { "entity-description.ee-infinity-fluid-wagon" },
    "\n[color=255,57,48]",
    { "entity-description.ee-performance-warning" },
    "[/color]",
  }
  fluid_wagon.icons = util.extract_icon_info(fluid_wagon)
  fluid_wagon.hidden_in_factoriopedia = true
  fluid_wagon.max_speed = 10
  fluid_wagon.minable.result = "ee-infinity-fluid-wagon"
  fluid_wagon.minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-fluid-wagon-minimap.png",
    flags = { "icon" },
    scale = 0.5,
    size = { 20, 40 },
  }
  fluid_wagon.selected_minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-fluid-wagon-minimap-selected.png",
    flags = { "icon" },
    scale = 0.5,
    size = { 20, 40 },
  }
  fluid_wagon.additional_pastable_entities = { "ee-infinity-fluid-wagon" }
  util.recursive_tint(fluid_wagon)

  -- non-interactable chest and pipe
  local infinity_wagon_chest = flib_table.deepcopy(data.raw["infinity-container"]["ee-infinity-chest"])
  infinity_wagon_chest.name = "ee-infinity-wagon-chest"
  infinity_wagon_chest.icons = util.recursive_tint(util.extract_icon_info(infinity_wagon_chest))
  infinity_wagon_chest.subgroup = nil
  infinity_wagon_chest.picture = util.empty_sprite()
  -- infinity_wagon_chest.collision_mask = { "layer-15" }
  infinity_wagon_chest.selection_box = nil
  infinity_wagon_chest.selectable_in_game = false
  infinity_wagon_chest.flags = { "hide-alt-info" }
  infinity_wagon_chest.hidden = true

  local infinity_wagon_pipe = flib_table.deepcopy(data.raw["infinity-pipe"]["infinity-pipe"])
  infinity_wagon_pipe.name = "ee-infinity-wagon-pipe"
  infinity_wagon_pipe.icons = util.recursive_tint({ infinity_wagon_pipe.icons[1] })
  -- infinity_wagon_pipe.collision_mask = { "layer-15" }
  infinity_wagon_pipe.selection_box = nil
  infinity_wagon_pipe.selectable_in_game = false
  infinity_wagon_pipe.order = "a"
  infinity_wagon_pipe.flags = { "hide-alt-info" }
  infinity_wagon_pipe.hidden = true
  infinity_wagon_pipe.gui_mode = "all"

  for k in pairs(infinity_wagon_pipe.pictures) do
    infinity_wagon_pipe.pictures[k] = util.empty_sprite()
  end

  data:extend({ cargo_wagon, fluid_wagon, infinity_wagon_chest, infinity_wagon_pipe })
end

local linked_chest = flib_table.deepcopy(data.raw["linked-container"]["linked-chest"])
linked_chest.name = "ee-linked-chest"
linked_chest.icons = {
  { icon = "__EditorExtensions__/graphics/item/linked-chest.png", icon_size = 64 },
}
linked_chest.icon = nil
linked_chest.icon_size = nil
linked_chest.minable.result = "ee-linked-chest"
linked_chest.inventory_size = 100
linked_chest.gui_mode = "all"
linked_chest.picture = {
  layers = {
    {
      filename = "__EditorExtensions__/graphics/entity/linked-chest/linked-chest.png",
      priority = "extra-high",
      width = 68,
      height = 84,
      shift = util.by_pixel(0, -3),
      scale = 0.5,
    },
    {
      filename = "__EditorExtensions__/graphics/entity/linked-chest/linked-chest-shadow.png",
      priority = "extra-high",
      width = 116,
      height = 48,
      shift = util.by_pixel(12, 6),
      draw_as_shadow = true,
      scale = 0.5,
    },
  },
}
util.recursive_tint(linked_chest, constants.infinity_chest_data[1].t)
data:extend({ linked_chest })

local super_beacon = flib_table.deepcopy(data.raw["beacon"]["beacon"])
super_beacon.name = "ee-super-beacon"
super_beacon.icons = util.extract_icon_info(super_beacon)
super_beacon.map_color = constants.infinity_tint
super_beacon.friendly_map_color = constants.infinity_tint
super_beacon.minable.result = "ee-super-beacon"
super_beacon.energy_source = { type = "void" }
super_beacon.allowed_effects = { "consumption", "speed", "productivity", "pollution" }
super_beacon.supply_area_distance = 64
super_beacon.module_slots = 10
util.recursive_tint(super_beacon, constants.infinity_tint)
-- undo the tint of the module slots, except for the base
if super_beacon.graphics_set.module_visualisations then
  for _, slot in ipairs(super_beacon.graphics_set.module_visualisations[1].slots) do
    for _, def in ipairs(slot) do
      if not def.has_empty_slot then
        util.recursive_tint(def, false)
      end
    end
  end
end
super_beacon.se_allow_in_space = mods["space-exploration"] and true or nil --- @diagnostic disable-line:inject-field
data:extend({ super_beacon })

local super_electric_pole = flib_table.deepcopy(data.raw["electric-pole"]["big-electric-pole"])
super_electric_pole.name = "ee-super-electric-pole"
super_electric_pole.icons = util.extract_icon_info(super_electric_pole)
super_electric_pole.hidden_in_factoriopedia = true
super_electric_pole.map_color = constants.infinity_tint
super_electric_pole.friendly_map_color = constants.infinity_tint
super_electric_pole.subgroup = "ee-electricity"
super_electric_pole.order = "ba"
super_electric_pole.minable.result = "ee-super-electric-pole"
super_electric_pole.maximum_wire_distance = 64
util.recursive_tint(super_electric_pole)
data:extend({ super_electric_pole })

local super_lab = flib_table.deepcopy(data.raw["lab"]["lab"])
super_lab.name = "ee-super-lab"
super_lab.icons = util.extract_icon_info(super_lab)
super_lab.hidden_in_factoriopedia = true
super_lab.map_color = constants.infinity_tint
super_lab.friendly_map_color = constants.infinity_tint
super_lab.minable.result = "ee-super-lab"
super_lab.energy_source = { type = "void" }
super_lab.energy_usage = "1W"
super_lab.researching_speed = 100
super_lab.module_slots = 10
util.recursive_tint(super_lab)
data:extend({ super_lab })

local super_locomotive = flib_table.deepcopy(data.raw["locomotive"]["locomotive"])
super_locomotive.name = "ee-super-locomotive"
super_locomotive.icons = util.extract_icon_info(super_locomotive)
super_locomotive.hidden_in_factoriopedia = true
super_locomotive.map_color = constants.infinity_tint
super_locomotive.friendly_map_color = constants.infinity_tint
super_locomotive.max_power = "10MW"
super_locomotive.energy_source = { type = "void" }
super_locomotive.max_speed = 10
super_locomotive.reversing_power_modifier = 1
super_locomotive.braking_force = 100
super_locomotive.minable.result = "ee-super-locomotive"
super_locomotive.allow_manual_color = false
super_locomotive.color = { r = 0, g = 0, b = 0, a = 0.5 }
util.recursive_tint(super_locomotive)
data:extend({ super_locomotive })

local super_substation = flib_table.deepcopy(data.raw["electric-pole"]["substation"])
super_substation.name = "ee-super-substation"
super_substation.icons = util.extract_icon_info(super_substation)
super_substation.hidden_in_factoriopedia = true
super_substation.map_color = constants.infinity_tint
super_substation.friendly_map_color = constants.infinity_tint
super_substation.subgroup = "ee-electricity"
super_substation.order = "bb"
super_substation.minable.result = "ee-super-substation"
super_substation.maximum_wire_distance = 64
super_substation.supply_area_distance = 64
util.recursive_tint(super_substation)
data:extend({ super_substation })

local super_pump = flib_table.deepcopy(data.raw["pump"]["pump"])
super_pump.name = "ee-super-pump"
super_pump.icons = util.extract_icon_info(super_pump)
super_pump.hidden_in_factoriopedia = true
super_pump.map_color = constants.infinity_tint
super_pump.friendly_map_color = constants.infinity_tint
super_pump.placeable_by = { item = "ee-super-pump", count = 1 }
super_pump.minable = { result = "ee-super-pump", mining_time = 0.1 }
super_pump.energy_source = {
  type = "fluid",
  fluid_box = {
    pipe_connections = {},
    filter = "ee-super-pump-speed-fluid",
    volume = 100000000000,
  },
  fluid_usage_per_tick = 0.02,
}
super_pump.energy_usage = "720kW"
super_pump.pumping_speed = 10000
util.recursive_tint(super_pump)
data:extend({ super_pump })

local super_radar = flib_table.deepcopy(data.raw["radar"]["radar"])
super_radar.name = "ee-super-radar"
super_radar.icons = util.extract_icon_info(super_radar)
super_radar.hidden_in_factoriopedia = true
super_radar.map_color = constants.infinity_tint
super_radar.friendly_map_color = constants.infinity_tint
super_radar.minable.result = "ee-super-radar"
super_radar.energy_source = { type = "void" }
super_radar.max_distance_of_sector_revealed = 20
super_radar.max_distance_of_nearby_sector_revealed = 20
util.recursive_tint(super_radar)
data:extend({ super_radar })

local super_roboport = flib_table.deepcopy(data.raw["roboport"]["roboport"])
super_roboport.name = "ee-super-roboport"
super_roboport.icons = util.extract_icon_info(super_roboport)
super_roboport.hidden_in_factoriopedia = true
super_roboport.map_color = constants.infinity_tint
super_roboport.friendly_map_color = constants.infinity_tint
super_roboport.logistics_radius = 200
super_roboport.construction_radius = 400
super_roboport.robot_slots_count = 10
super_roboport.material_slots_count = 10
super_roboport.energy_source = { type = "void" }
super_roboport.charging_energy = "1000YW"
super_roboport.charging_distance = 0
super_roboport.charging_station_count = 100
super_roboport.charging_threshold_distance = 0
super_roboport.minable.result = "ee-super-roboport"
util.recursive_tint(super_roboport)
data:extend({ super_roboport })

-- super robots
do
  local modifiers = {
    energy_per_move = "0kJ",
    energy_per_tick = "0kJ",
    max_energy = "0kJ",
    max_payload_size = 1000,
    max_to_charge = 0,
    min_to_charge = 0,
    speed = 1000000,
    speed_multiplier_when_out_of_energy = 1,
  }

  local construction_robot = flib_table.deepcopy(data.raw["construction-robot"]["construction-robot"])
  construction_robot.name = "ee-super-construction-robot"
  construction_robot.icons = util.extract_icon_info(construction_robot)
  construction_robot.hidden_in_factoriopedia = true
  -- construction_robot.map_color = constants.infinity_tint
  -- construction_robot.friendly_map_color = constants.infinity_tint
  construction_robot.minable.result = "ee-super-construction-robot"
  for k, v in pairs(modifiers) do
    construction_robot[k] = v
  end
  util.recursive_tint(construction_robot)

  local logistic_robot = flib_table.deepcopy(data.raw["logistic-robot"]["logistic-robot"])
  logistic_robot.name = "ee-super-logistic-robot"
  logistic_robot.icons = util.extract_icon_info(logistic_robot)
  logistic_robot.hidden_in_factoriopedia = true
  -- logistic_robot.map_color = constants.infinity_tint
  -- logistic_robot.friendly_map_color = constants.infinity_tint
  logistic_robot.minable.result = "ee-super-logistic-robot"
  for k, v in pairs(modifiers) do
    logistic_robot[k] = v
  end
  util.recursive_tint(logistic_robot)

  data:extend({ construction_robot, logistic_robot })
end
