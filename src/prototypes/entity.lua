-- -------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ENTITIES
-- We copy the vanilla definitions instead of creating our own, so many vanilla changes will be immediately reflected in the mod.

local util = require("prototypes.util")

-- INFINITY ACCUMULATOR
do
  local accumulator_types = {"primary-input", "primary-output", "secondary-input", "secondary-output", "tertiary"}
  local base_entity = table.deepcopy(data.raw["electric-energy-interface"]["electric-energy-interface"])
  base_entity.minable.result = "ee-infinity-accumulator"
  base_entity.localised_description = {"entity-description.infinity-accumulator"}
  local accumulator_icons = util.recursive_tint{(base_entity.icons[1])}
  util.recursive_tint(base_entity)

  for _, t in pairs(accumulator_types) do
    local entity = table.deepcopy(base_entity)
    entity.name = "ee-infinity-accumulator-"..t
    entity.localised_name = {"entity-name.ee-infinity-accumulator"}
    entity.localised_description = {"entity-description.ee-infinity-accumulator"}
    entity.icons = accumulator_icons
    entity.map_color = util.infinity_tint
    entity.friendly_map_color = util.infinity_tint
    entity.energy_source = {type="electric", usage_priority=t, buffer_capacity="500GJ"}
    entity.subgroup = "ee-electricity"
    entity.order = "a"
    entity.minable.result = "ee-infinity-accumulator"
    entity.placeable_by = {item="ee-infinity-accumulator", count=1}
    data:extend{entity}
  end
end

-- INFINITY BEACON
local infinity_beacon = table.deepcopy(data.raw["beacon"]["beacon"])
infinity_beacon.name = "ee-infinity-beacon"
infinity_beacon.icons = {(util.extract_icon_info(infinity_beacon))}
infinity_beacon.map_color = util.infinity_tint
infinity_beacon.friendly_map_color = util.infinity_tint
infinity_beacon.minable.result = "ee-infinity-beacon"
infinity_beacon.energy_source = {type="void"}
infinity_beacon.allowed_effects = {"consumption", "speed", "productivity", "pollution"}
infinity_beacon.supply_area_distance = 64
infinity_beacon.module_specification = {module_slots=12}
util.recursive_tint(infinity_beacon)
data:extend{infinity_beacon}

-- INFINITY AND TESSERACT CHESTS
do
  local infinity_chest_picture = {
    layers = {
      {
        filename = "__EditorExtensions__/graphics/entity/infinity-chest/infinity-chest.png",
        priority = "extra-high",
        width = 34,
        height = 42,
        shift = util.by_pixel(0, -3),
        hr_version =
        {
          filename = "__EditorExtensions__/graphics/entity/infinity-chest/hr-infinity-chest.png",
          priority = "extra-high",
          width = 68,
          height = 84,
          shift = util.by_pixel(0, -3),
          scale = 0.5,
        }
      },
      {
        filename = "__EditorExtensions__/graphics/entity/infinity-chest/infinity-chest-shadow.png",
        priority = "extra-high",
        width = 58,
        height = 24,
        shift = util.by_pixel(12, 6),
        draw_as_shadow = true,
        hr_version =
        {
          filename = "__EditorExtensions__/graphics/entity/infinity-chest/hr-infinity-chest-shadow.png",
          priority = "extra-high",
          width = 116,
          height = 48,
          shift = util.by_pixel(12, 6),
          draw_as_shadow = true,
          scale = 0.5,
        }
      }
    }
  }

  local base_entity = table.deepcopy(data.raw["infinity-container"]["infinity-chest"])
  for _, t in pairs(util.infinity_chest_data) do
    local lm = t.lm
    local suffix = lm and "-"..lm or ""
    local chest = table.deepcopy(base_entity)
    chest.name = "ee-infinity-chest"..suffix
    chest.localised_description = util.chest_description(suffix)
    chest.icons = {table.deepcopy(util.infinity_chest_icon)}
    chest.map_color = util.infinity_tint
    chest.friendly_map_color = util.infinity_tint
    chest.picture = table.deepcopy(infinity_chest_picture)
    chest.order = t.o
    chest.subgroup = "ee-inventories"
    chest.erase_contents_when_mined = true
    chest.logistic_mode = lm
    chest.logistic_slots_count = t.s
    chest.minable.result = "ee-infinity-chest"..suffix
    chest.render_not_in_network_icon = true
    chest.inventory_size = 100
    chest.next_upgrade = nil
    chest.flags = {"player-creation"}
    util.recursive_tint(chest, t.t)
    data:extend{chest}
  end

  -- tesseract chests
  -- create the chests here to let other mods modify them. increase their inventory size in data-final-fixes
  local tesseract_chest_picture = {
    layers = {
      {
        filename = "__EditorExtensions__/graphics/entity/tesseract-chest/tesseract-chest.png",
        priority = "extra-high",
        width = 34,
        height = 42,
        shift = util.by_pixel(0, -3),
        hr_version =
        {
          filename = "__EditorExtensions__/graphics/entity/tesseract-chest/hr-tesseract-chest.png",
          priority = "extra-high",
          width = 68,
          height = 84,
          shift = util.by_pixel(0, -3),
          scale = 0.5,
        }
      },
      {
        filename = "__EditorExtensions__/graphics/entity/tesseract-chest/tesseract-chest-shadow.png",
        priority = "extra-high",
        width = 58,
        height = 24,
        shift = util.by_pixel(12, 6),
        draw_as_shadow = true,
        hr_version =
        {
          filename = "__EditorExtensions__/graphics/entity/tesseract-chest/hr-tesseract-chest-shadow.png",
          priority = "extra-high",
          width = 116,
          height = 48,
          shift = util.by_pixel(12, 6),
          draw_as_shadow = true,
          scale = 0.5,
        }
      }
    }
  }
  
  for _, t in pairs(util.tesseract_chest_data) do
    local lm = t.lm
    local suffix = lm and "-"..lm or ""
    local chest = table.deepcopy(data.raw["infinity-container"]["ee-infinity-chest"..suffix])
    chest.name = "ee-tesseract-chest"..suffix
    chest.localised_description = util.chest_description(suffix, true)
    chest.order = t.o
    chest.icons = {table.deepcopy(util.tesseract_chest_icon)}
    chest.picture = table.deepcopy(tesseract_chest_picture)
    chest.logistic_slots_count = 0
    chest.minable.result = "ee-tesseract-chest"..suffix
    chest.enable_inventory_bar = false
    chest.flags = {"player-creation", "hide-alt-info"}
    util.recursive_tint(chest, t.t)
    data:extend{chest}
  end
end

-- INFINITY COMBINATOR
local infinity_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
infinity_combinator.name = "ee-infinity-combinator"
infinity_combinator.icons = {util.extract_icon_info(infinity_combinator)}
infinity_combinator.map_color = util.infinity_tint
infinity_combinator.friendly_map_color = util.infinity_tint
infinity_combinator.allow_copy_paste = false
infinity_combinator.minable = {mining_time=0.5, result="ee-infinity-combinator"}
infinity_combinator.placeable_by = {item="ee-infinity-combinator", count=1}
util.recursive_tint(infinity_combinator, util.combinator_tint)
data:extend{infinity_combinator}

-- INFINITY HEAT PIPE
local infinity_heat_pipe = table.deepcopy(data.raw["heat-interface"]["heat-interface"])
infinity_heat_pipe.name = "ee-infinity-heat-pipe"
infinity_heat_pipe.localised_description = {"entity-description.ee-infinity-heat-pipe"}
infinity_heat_pipe.gui_mode = "all"
infinity_heat_pipe.icons = {util.extract_icon_info(data.raw["item"]["heat-pipe"])}
infinity_heat_pipe.map_color = util.infinity_tint
infinity_heat_pipe.friendly_map_color = util.infinity_tint
infinity_heat_pipe.picture = {
  filename = "__base__/graphics/entity/heat-pipe/heat-pipe-t-1.png",
  width = 32,
  height = 32,
  flags = {"no-crop"},
  hr_version = {
    filename = "__base__/graphics/entity/heat-pipe/hr-heat-pipe-t-1.png",
    width = 64,
    height = 64,
    scale = 0.5,
    flags = {"no-crop"}
  }
}
infinity_heat_pipe.minable = {mining_time=0.5, result="ee-infinity-heat-pipe"}
infinity_heat_pipe.placeable_by = {item="ee-infinity-heat-pipe", count=1}
util.recursive_tint(infinity_heat_pipe)
data:extend{infinity_heat_pipe}

-- INFINITY INSERTER
local infinity_inserter = table.deepcopy(data.raw["inserter"]["filter-inserter"])
infinity_inserter.name = "ee-infinity-inserter"
infinity_inserter.icons = {util.extract_icon_info(infinity_inserter)}
infinity_inserter.map_color = util.infinity_tint
infinity_inserter.friendly_map_color = util.infinity_tint
infinity_inserter.placeable_by = {item="ee-infinity-inserter", count=1}
infinity_inserter.minable.result = "ee-infinity-inserter"
infinity_inserter.energy_source = {type="void"}
infinity_inserter.energy_usage = "1W"
infinity_inserter.stack = true
infinity_inserter.filter_count = 5
infinity_inserter.extension_speed = 1
infinity_inserter.rotation_speed = 0.5
util.recursive_tint(infinity_inserter)
data:extend{infinity_inserter}

-- INFINITY LAB
local infinity_lab = table.deepcopy(data.raw["lab"]["lab"])
infinity_lab.name = "ee-infinity-lab"
infinity_lab.icons = {util.extract_icon_info(infinity_lab)}
infinity_lab.map_color = util.infinity_tint
infinity_lab.friendly_map_color = util.infinity_tint
infinity_lab.minable.result = "ee-infinity-lab"
infinity_lab.energy_source = {type="void"}
infinity_lab.energy_usage = "1W"
infinity_lab.researching_speed = 100
infinity_lab.module_specification = {module_slots=12}
util.recursive_tint(infinity_lab)
data:extend{infinity_lab}

-- INFINITY LOADER
-- Create everything except the actual loaders here. We create those in data-updates so they can get every belt type.
do
  local loader_icon = util.recursive_tint{{icon="__EditorExtensions__/graphics/item/infinity-loader.png", icon_size=64, icon_mipmaps=4}}
  local loader_base = table.deepcopy(data.raw["underground-belt"]["underground-belt"])
  loader_base.icons = loader_icon

  local base_loader_path = "__base__/graphics/entity/underground-belt/"

  data:extend{
    -- infinity chest
    {
      type = "infinity-container",
      name = "ee-infinity-loader-chest",
      icons = loader_icon,
      erase_contents_when_mined = true,
      inventory_size = 10,
      flags = {"hide-alt-info"},
      picture = util.empty_sheet,
      collision_box = {{-0.05,-0.05},{0.05,0.05}}
    },
    -- logic combinator (what you actually interact with)
    {
      type = "constant-combinator",
      name = "ee-infinity-loader-logic-combinator",
      icons = loader_icon,
      localised_name = {"entity-name.ee-infinity-loader"},
      localised_description = {"entity-description.ee-infinity-loader"},
      map_color = util.infinity_tint,
      friendly_map_color = util.infinity_tint,
      order = "a",
      collision_box = loader_base.collision_box,
      selection_box = loader_base.selection_box,
      fast_replaceable_group = "transport-belt",
      placeable_by = {item="ee-infinity-loader", count=1},
      minable = {result="ee-infinity-loader", mining_time=0.1},
      flags = {"player-creation", "hidden"},
      item_slot_count = 2,
      sprites = util.empty_sheet,
      activity_led_sprites = util.empty_sheet,
      activity_led_light_offsets = {{0,0}, {0,0}, {0,0}, {0,0}},
      circuit_wire_connection_points = util.empty_circuit_wire_connection_points
    }
  }

  -- create spritesheet for dummy combinator
  local sprite_files = {
    {base_loader_path.."underground-belt-structure-back-patch.png", base_loader_path.."hr-underground-belt-structure-back-patch.png"},
    {"__EditorExtensions__/graphics/entity/infinity-loader/infinity-loader.png", "__EditorExtensions__/graphics/entity/infinity-loader/hr-infinity-loader.png"},
    {base_loader_path.."underground-belt-structure-front-patch.png", base_loader_path.."hr-underground-belt-structure-front-patch.png"},
  }
  local sprite_x = {south=96*0, west=96*1, north=96*2, east=96*3}
  local sprites = {}
  for k, x in pairs(sprite_x) do
    sprites[k] = {}
    sprites[k].layers = {}
    for i, t in pairs(sprite_files) do
      sprites[k].layers[i] = util.recursive_tint{
        filename = t[1],
        x = x,
        width = 96,
        height = 96,
        hr_version = {
          filename = t[2],
          x = x * 2,
          width = 192,
          height = 192,
          scale = 0.5
        }
      }
    end
  end

  -- dummy combinator (for placement and blueprints)
  local dummy_combinator = table.deepcopy(data.raw["constant-combinator"]["ee-infinity-loader-logic-combinator"])
  dummy_combinator.name = "ee-infinity-loader-dummy-combinator"
  dummy_combinator.localised_description = {"entity-description.ee-infinity-loader"}
  dummy_combinator.minable = nil
  dummy_combinator.flags = {"player-creation"}
  dummy_combinator.icons = loader_base.icons
  dummy_combinator.sprites = sprites
  data:extend{dummy_combinator}

  -- inserter
  data:extend{
    {
      type = "inserter",
      name = "ee-infinity-loader-inserter",
      icons = loader_icon,
      stack = true,
      collision_box = {{-0.1,-0.1}, {0.1,0.1}},
      -- selection_box = {{-0.1,-0.1}, {0.1,0.1}},
      -- selection_priority = 99,
      selectable_in_game = false,
      allow_custom_vectors = true,
      energy_source = {type="void"},
      extension_speed = 1,
      rotation_speed = 0.5,
      energy_per_movement = "0.00001J",
      energy_per_extension = "0.00001J",
      pickup_position = {0, -0.2},
      insert_position = {0, 0.2},
      filter_count = 1,
      draw_held_item = false,
      platform_picture = util.empty_sheet,
      hand_base_picture = util.empty_sheet,
      hand_open_picture = util.empty_sheet,
      hand_closed_picture = util.empty_sheet,
      -- hand_base_picture = filter_inserter.hand_base_picture,
      -- hand_open_picture = filter_inserter.hand_open_picture,
      -- hand_closed_picture = filter_inserter.hand_closed_picture,
      draw_inserter_arrow = false,
      flags = {"hide-alt-info", "hidden"}
    }
  }
end

-- INFINITY LOCOMOTIVE
local infinity_locomotive = table.deepcopy(data.raw["locomotive"]["locomotive"])
infinity_locomotive.name = "ee-infinity-locomotive"
infinity_locomotive.icons = {util.extract_icon_info(infinity_locomotive)}
infinity_locomotive.map_color = util.infinity_tint
infinity_locomotive.friendly_map_color = util.infinity_tint
infinity_locomotive.max_power = "10MW"
infinity_locomotive.energy_source = {type="void"}
infinity_locomotive.max_speed = 10
infinity_locomotive.reversing_power_modifier = 1
infinity_locomotive.braking_force = 100
infinity_locomotive.minable.result = "ee-infinity-locomotive"
infinity_locomotive.allow_manual_color = false
infinity_locomotive.color = {r=0, g=0, b=0, a=0.5}
util.recursive_tint(infinity_locomotive)
data:extend{infinity_locomotive}

-- INFINITY PIPE
local infinity_pipe = table.deepcopy(data.raw["infinity-pipe"]["infinity-pipe"])
infinity_pipe.name = "ee-infinity-pipe"
infinity_pipe.localised_description = {"entity-description.ee-infinity-pipe"}
infinity_pipe.map_color = util.infinity_tint
infinity_pipe.friendly_map_color = util.infinity_tint
infinity_pipe.gui_mode = "all"
infinity_pipe.icons = infinity_pipe.icons
infinity_pipe.minable = {mining_time=0.5, result="ee-infinity-pipe"}
infinity_pipe.placeable_by = {item="ee-infinity-pipe", count=1}
util.recursive_tint(infinity_pipe)
data:extend{infinity_pipe}

-- INFINITY POWER POLES
do
  local infinity_power_pole = table.deepcopy(data.raw["electric-pole"]["big-electric-pole"])
  infinity_power_pole.name = "ee-infinity-electric-pole"
  infinity_power_pole.icons = {util.extract_icon_info(infinity_power_pole)}
  infinity_power_pole.map_color = util.infinity_tint
  infinity_power_pole.friendly_map_color = util.infinity_tint
  infinity_power_pole.subgroup = "ee-electricity"
  infinity_power_pole.order = "ba"
  infinity_power_pole.minable.result = "ee-infinity-electric-pole"
  infinity_power_pole.maximum_wire_distance = 64
  util.recursive_tint(infinity_power_pole)

  local infinity_substation = table.deepcopy(data.raw["electric-pole"]["substation"])
  infinity_substation.name = "ee-infinity-substation"
  infinity_substation.icons = {util.extract_icon_info(infinity_substation)}
  infinity_substation.map_color = util.infinity_tint
  infinity_substation.friendly_map_color = util.infinity_tint
  infinity_substation.subgroup = "ee-electricity"
  infinity_substation.order = "bb"
  infinity_substation.minable.result = "ee-infinity-substation"
  infinity_substation.maximum_wire_distance = 64
  infinity_substation.supply_area_distance = 64
  util.recursive_tint(infinity_substation)

  data:extend{infinity_power_pole, infinity_substation}
end

-- INFINITY PUMP
local infinity_pump = table.deepcopy(data.raw["pump"]["pump"])
infinity_pump.name = "ee-infinity-pump"
infinity_pump.icons = {util.extract_icon_info(infinity_pump)}
infinity_pump.map_color = util.infinity_tint
infinity_pump.friendly_map_color = util.infinity_tint
infinity_pump.placeable_by = {item="ee-infinity-pump", count=1}
infinity_pump.minable = {result="ee-infinity-pump", mining_time=0.1}
infinity_pump.energy_source = {type="void"}
infinity_pump.energy_usage = "1W"
infinity_pump.pumping_speed = 1000
util.recursive_tint(infinity_pump)
data:extend{infinity_pump}

-- INFINITY RADAR
local infinity_radar = table.deepcopy(data.raw["radar"]["radar"])
infinity_radar.name = "ee-infinity-radar"
infinity_radar.icons = {util.extract_icon_info(infinity_radar)}
infinity_radar.map_color = util.infinity_tint
infinity_radar.friendly_map_color = util.infinity_tint
infinity_radar.minable.result = "ee-infinity-radar"
infinity_radar.energy_source = {type="void"}
infinity_radar.max_distance_of_sector_revealed = 20
infinity_radar.max_distance_of_nearby_sector_revealed = 20
util.recursive_tint(infinity_radar)
data:extend{infinity_radar}

-- INFINITY ROBOPORT
local infinity_roboport = table.deepcopy(data.raw["roboport"]["roboport"])
infinity_roboport.name = "ee-infinity-roboport"
infinity_roboport.icons = {util.extract_icon_info(infinity_roboport)}
infinity_roboport.map_color = util.infinity_tint
infinity_roboport.friendly_map_color = util.infinity_tint
infinity_roboport.logistics_radius = 200
infinity_roboport.construction_radius = 400
infinity_roboport.energy_source = {type="void"}
infinity_roboport.charging_energy = "1000YW"
infinity_roboport.charging_distance = 0
infinity_roboport.charging_station_count = 100
infinity_roboport.charging_threshold_distance = 0
infinity_roboport.minable.result = "ee-infinity-roboport"
util.recursive_tint(infinity_roboport)
data:extend{infinity_roboport}

-- INFINITY ROBOTS
do
  local modifiers = {
    speed = 1,
    max_energy = "0kJ",
    energy_per_tick = "0kJ",
    energy_per_move = "0kJ",
    min_to_charge = 0,
    max_to_charge = 0,
    speed_multiplier_when_out_of_energy = 1
  }

  local construction_robot = table.deepcopy(data.raw["construction-robot"]["construction-robot"])
  construction_robot.name = "ee-infinity-construction-robot"
  construction_robot.icons = {util.extract_icon_info(construction_robot)}
  -- construction_robot.map_color = util.infinity_tint
  -- construction_robot.friendly_map_color = util.infinity_tint
  construction_robot.minable.result = "ee-infinity-construction-robot"
  for k, v in pairs(modifiers) do construction_robot[k] = v end
  util.recursive_tint(construction_robot)

  local logistic_robot = table.deepcopy(data.raw["logistic-robot"]["logistic-robot"])
  logistic_robot.name = "ee-infinity-logistic-robot"
  logistic_robot.icons = {util.extract_icon_info(logistic_robot)}
  -- logistic_robot.map_color = util.infinity_tint
  -- logistic_robot.friendly_map_color = util.infinity_tint
  logistic_robot.minable.result = "ee-infinity-logistic-robot"
  for k, v in pairs(modifiers) do logistic_robot[k] = v end
  util.recursive_tint(logistic_robot)

  data:extend{construction_robot, logistic_robot, infinity_roboport}
end

-- INFINITY WAGONS
do
  local cargo_wagon = table.deepcopy(data.raw["cargo-wagon"]["cargo-wagon"])
  cargo_wagon.name = "ee-infinity-cargo-wagon"
  cargo_wagon.icons = {util.extract_icon_info(cargo_wagon)}
  cargo_wagon.inventory_size = 100
  cargo_wagon.minable.result = "ee-infinity-cargo-wagon"
  cargo_wagon.minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-cargo-wagon-minimap.png",
    flags = {"icon"},
    scale = 0.5,
    size = {20,40}
  }
  cargo_wagon.selected_minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-cargo-wagon-minimap-selected.png",
    flags = {"icon"},
    scale = 0.5,
    size = {20,40}
  }
  util.recursive_tint(cargo_wagon)

  local fluid_wagon = table.deepcopy(data.raw["fluid-wagon"]["fluid-wagon"])
  fluid_wagon.name = "ee-infinity-fluid-wagon"
  fluid_wagon.icons = {util.extract_icon_info(fluid_wagon)}
  fluid_wagon.minable.result = "ee-infinity-fluid-wagon"
  fluid_wagon.minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-fluid-wagon-minimap.png",
    flags = {"icon"},
    scale = 0.5,
    size = {20,40}
  }
  fluid_wagon.selected_minimap_representation = {
    filename = "__EditorExtensions__/graphics/entity/infinity-fluid-wagon-minimap-selected.png",
    flags = {"icon"},
    scale = 0.5,
    size = {20,40}
  }
  util.recursive_tint(fluid_wagon)

  -- non-interactable chest and pipe
  local infinity_wagon_chest = table.deepcopy(data.raw["infinity-container"]["ee-infinity-chest"])
  infinity_wagon_chest.name = "ee-infinity-wagon-chest"
  infinity_wagon_chest.icons = util.recursive_tint{util.extract_icon_info(infinity_wagon_chest)}
  infinity_wagon_chest.subgroup = nil
  infinity_wagon_chest.picture = util.empty_sheet
  infinity_wagon_chest.collision_mask = {"layer-15"}
  infinity_wagon_chest.selection_box = nil
  infinity_wagon_chest.selectable_in_game = false
  infinity_wagon_chest.flags = {"hide-alt-info", "hidden"}

  local infinity_wagon_pipe = table.deepcopy(data.raw["infinity-pipe"]["infinity-pipe"])
  infinity_wagon_pipe.name = "ee-infinity-wagon-pipe"
  infinity_wagon_pipe.icons = util.recursive_tint{infinity_wagon_pipe.icons[1]}
  infinity_wagon_pipe.collision_mask = {"layer-15"}
  infinity_wagon_pipe.selection_box = nil
  infinity_wagon_pipe.selectable_in_game = false
  infinity_wagon_pipe.order = "a"
  infinity_wagon_pipe.flags = {"hide-alt-info", "hidden"}

  for k, t in pairs(infinity_wagon_pipe.pictures) do
    infinity_wagon_pipe.pictures[k] = util.empty_sheet
  end

  data:extend{cargo_wagon, fluid_wagon, infinity_wagon_chest, infinity_wagon_pipe}
end