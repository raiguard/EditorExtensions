local event = require("__flib__.event")
local table = require("__flib__.table")

local constants = {}

-- AGGREGATE_CHEST

constants.aggregate_chest_names = {
  ["ee-aggregate-chest"] = "ee-aggregate-chest",
  ["ee-aggregate-chest-passive-provider"] = "ee-aggregate-chest-passive-provider",
}

-- CHEAT MODE

constants.cheat_mode = {}

constants.cheat_mode.equipment_to_add = {
  { name = "ee-infinity-fusion-reactor-equipment", position = { 0, 0 } },
  { name = "ee-super-personal-roboport-equipment", position = { 1, 0 } },
  { name = "ee-super-exoskeleton-equipment", position = { 2, 0 } },
  { name = "ee-super-exoskeleton-equipment", position = { 3, 0 } },
  { name = "ee-super-energy-shield-equipment", position = { 4, 0 } },
  { name = "ee-super-night-vision-equipment", position = { 5, 0 } },
  { name = "ee-super-battery-equipment", position = { 6, 0 } },
  { name = "belt-immunity-equipment", position = { 7, 0 } },
}

constants.cheat_mode.items_to_add = {
  { name = "ee-infinity-accumulator", count = 50 },
  { name = "ee-infinity-chest", count = 50 },
  { name = "ee-super-construction-robot", count = 100 },
  { name = "ee-super-inserter", count = 50 },
  { name = "ee-infinity-loader", count = 50 },
  { name = "ee-infinity-pipe", count = 50 },
  { name = "ee-super-substation", count = 50 },
}

constants.cheat_mode.items_to_remove = {
  { name = "express-loader", count = 50 },
  { name = "stack-inserter", count = 50 },
  { name = "substation", count = 50 },
  { name = "construction-robot", count = 100 },
  { name = "electric-energy-interface", count = 1 },
  { name = "infinity-chest", count = 20 },
  { name = "infinity-pipe", count = 10 },
}

constants.cheat_mode.modifiers = {
  character_build_distance_bonus = 1000000,
  character_mining_speed_modifier = 2,
  character_reach_distance_bonus = 1000000,
  character_resource_reach_distance_bonus = 1000000,
}

-- CURSOR ENHANCEMENTS

constants.cursor_enhancements_interface_version = 1

constants.cursor_enhancements_overrides = {
  -- chests
  ["ee-infinity-chest"] = "ee-infinity-chest-active-provider",
  ["ee-infinity-chest-active-provider"] = "ee-infinity-chest-passive-provider",
  ["ee-infinity-chest-passive-provider"] = "ee-infinity-chest-storage",
  ["ee-infinity-chest-storage"] = "ee-infinity-chest-buffer",
  ["ee-infinity-chest-buffer"] = "ee-infinity-chest-requester",
  ["ee-infinity-chest-requester"] = "ee-aggregate-chest",
  ["ee-aggregate-chest"] = "ee-aggregate-chest-passive-provider",
  -- electricity
  ["ee-super-electric-pole"] = "ee-super-substation",
  ["ee-super-substation"] = "ee-infinity-accumulator",
  -- trains
  ["ee-super-locomotive"] = "ee-infinity-cargo-wagon",
  ["ee-infinity-cargo-wagon"] = "ee-infinity-fluid-wagon",
}

-- DEBUG WORLD

constants.debug_world = {
  size = { height = 50, width = 50 },
}

constants.debug_world_ready_event = event.generate_id()
constants.debug_world_player_ready_event = event.generate_id()

-- INFINITY ACCUMULATOR

constants.ia = {}

constants.ia.entity_names = {
  ["ee-infinity-accumulator-primary-input"] = true,
  ["ee-infinity-accumulator-primary-output"] = true,
  ["ee-infinity-accumulator-secondary-input"] = true,
  ["ee-infinity-accumulator-secondary-output"] = true,
  ["ee-infinity-accumulator-tertiary-buffer"] = true,
  ["ee-infinity-accumulator-tertiary-input"] = true,
  ["ee-infinity-accumulator-tertiary-output"] = true,
}

constants.ia.index_to_mode = { "output", "input", "buffer" }
constants.ia.index_to_priority = { "primary", "secondary", "tertiary" }

constants.ia.localised_modes = { { "ee-gui.output" }, { "ee-gui.input" }, { "ee-gui.buffer" } }
constants.ia.localised_priorities = { { "ee-gui.primary" }, { "ee-gui.secondary" }, { "ee-gui.tertiary" } }
constants.ia.localised_si_suffixes_joule = {}
constants.ia.localised_si_suffixes_watt = {}

constants.ia.mode_to_index = { output = 1, input = 2, buffer = 3 }

constants.ia.power_prefixes = { "kilo", "mega", "giga", "tera", "peta", "exa", "zetta", "yotta" }
constants.ia.power_suffixes_by_mode = { output = "watt", input = "watt", buffer = "joule" }

constants.ia.priority_to_index = { primary = 1, secondary = 2, tertiary = 3 }

constants.ia.si_suffixes_joule = { "kJ", "MJ", "GJ", "TJ", "PJ", "EJ", "ZJ", "YJ" }
constants.ia.si_suffixes_watt = { "kW", "MW", "GW", "TW", "PW", "EW", "ZW", "YW" }

for i, v in pairs(constants.ia.power_prefixes) do
  constants.ia.localised_si_suffixes_watt[i] = { "", { "si-prefix-symbol-" .. v }, { "si-unit-symbol-watt" } }
  constants.ia.localised_si_suffixes_joule[i] = { "", { "si-prefix-symbol-" .. v }, { "si-unit-symbol-joule" } }
end

-- INFINITY LOADER

-- 60 items/second / 60 ticks/second / 8 items/tile = X tiles/tick
constants.belt_speed_for_60_per_second = 60 / 60 / 8

-- pattern -> replacement
-- iterate through all of these to result in the belt type
constants.belt_type_patterns = {
  -- editor extensions :D
  ["ee%-infinity%-loader%-loader%-?"] = "",
  ["ee%-linked%-belt%-?"] = "",
  -- better belts: https://mods.factorio.com/mod/BetterBelts
  ["%-v%d$"] = "",
  -- beltlayer: https://mods.factorio.com/mod/beltlayer
  ["layer%-connector"] = "",
  -- ultimate belts: https://mods.factorio.com/mod/UltimateBelts
  ["ultimate%-belt"] = "original-ultimate",
  -- krastorio legacy: https://mods.factorio.com/mod/Krastorio
  ["%-?kr%-01"] = "",
  ["%-?kr%-02"] = "fast",
  ["%-?kr%-03"] = "express",
  ["%-?kr%-04"] = "k",
  -- krastorio 2: https://mods.factorio.com/mod/Krastorio2
  ["^kr%-loader$"] = "",
  -- replicating belts: https://mods.factorio.com/mod/replicating-belts
  ["replicating%-?"] = "",
  -- subterranean: https://mods.factorio.com/mod/Subterranean
  ["subterranean"] = "",
  -- factorioextended plus transport: https://mods.factorio.com/mod/FactorioExtended-Plus-Transport
  ["%-to%-ground"] = "",
  -- miniloader: https://mods.factorio.com/mod/miniloader
  ["chute"] = "",
  ["space%-mini"] = "se-space", -- miniloader + space exploration
  ["%-?filter%-miniloader"] = "",
  ["%-?miniloader"] = "",
  -- vanilla
  ["%-?belt"] = "",
  ["%-?transport"] = "",
  ["%-?underground"] = "",
  ["%-?splitter"] = "",
  ["%-?loader"] = "",
  ["%-?1x1"] = "",
  ["%-?linked"] = "",
}

-- INFINITY PIPE

constants.ip_crafter_snapping_types = {
  ["assembling-machine"] = true,
  ["furnace"] = true,
  ["rocket-silo"] = true,
}

constants.infinity_pipe_modes = {
  "at-least",
  "at-most",
  "exactly",
  "add",
  "remove",
}

-- INFINITY WAGON

constants.infinity_wagon_names = {
  ["ee-infinity-cargo-wagon"] = true,
  ["ee-infinity-fluid-wagon"] = true,
}

-- OTHER

constants.editor_gui_width = 474

-- SETTINGS

constants.setting_names = {
  ["ee-infinity-pipe-crafter-snapping"] = "infinity_pipe_crafter_snapping",
  ["ee-default-infinity-filters"] = "default_infinity_filters",
  ["ee-inventory-sync"] = "inventory_sync_enabled",
  ["ee-testing-lab"] = "testing_lab",
  ["ee-start-in-editor"] = "start_in_editor",
}

-- SUPER PUMP

constants.sp_slider_to_temperature = {
  [0] = 0,
  [1] = 100,
  [2] = 200,
  [3] = 300,
  [4] = 400,
  [5] = 500,
  [6] = 600,
  [7] = 700,
  [8] = 800,
  [9] = 900,
  [10] = 1000,
  [11] = 2000,
  [12] = 3000,
  [13] = 4000,
  [14] = 5000,
  [15] = 6000,
  [16] = 7000,
  [17] = 8000,
  [18] = 9000,
  [19] = 10000,
  [20] = 15000,
  [21] = 20000,
  [22] = 25000,
  [23] = 30000,
}

constants.sp_temperature_to_slider = table.invert(constants.sp_slider_to_temperature)

-- TEST SURFACE

constants.empty_map_gen_settings = {
  default_enable_all_autoplace_controls = false,
  property_expression_names = { cliffiness = 0 },
  autoplace_settings = {
    tile = { settings = { ["out-of-map"] = { frequency = "normal", size = "normal", richness = "normal" } } },
  },
  starting_area = "none",
}

constants.testing_lab_setting = {
  off = 1,
  personal = 2,
  shared = 3,
}

return constants
