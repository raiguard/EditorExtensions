local constants = {}

-- AGGREGATE_CHEST

constants.aggregate_chest_names = {
  ["ee-aggregate-chest"] = "ee-aggregate-chest",
  ["ee-aggregate-chest-passive-provider"] = "ee-aggregate-chest-passive-provider"
}

-- CHEAT MODE

constants.cheat_mode = {}

constants.cheat_mode.equipment_to_add = {
  {name="ee-infinity-fusion-reactor-equipment", position={0,0}},
  {name="ee-super-personal-roboport-equipment", position={1,0}},
  {name="ee-super-exoskeleton-equipment", position={2,0}},
  {name="ee-super-exoskeleton-equipment", position={3,0}},
  {name="ee-super-energy-shield-equipment", position={4,0}},
  {name="ee-super-night-vision-equipment", position={5,0}},
  {name="belt-immunity-equipment", position={6,0}}
}

constants.cheat_mode.items_to_add = {
  {name="ee-infinity-accumulator", count=50},
  {name="ee-infinity-chest", count=50},
  {name="ee-super-construction-robot", count=100},
  {name="ee-super-inserter", count=50},
  {name="ee-infinity-pipe", count=50},
  {name="ee-super-substation", count=50}
}

constants.cheat_mode.items_to_remove = {
  {name="express-loader", count=50},
  {name="stack-inserter", count=50},
  {name="substation", count=50},
  {name="construction-robot", count=100},
  {name="electric-energy-interface", count=1},
  {name="infinity-chest", count=20},
  {name="infinity-pipe", count=10}
}

constants.cheat_mode.modifiers = {
  character_build_distance_bonus = 1000000,
  character_mining_speed_modifier = 2,
  character_reach_distance_bonus = 1000000,
  character_resource_reach_distance_bonus = 1000000
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
  ["ee-aggregate-chest"] = "ee-aggregate-chest-passive-provider",
  -- electric poles
  ["ee-super-electric-pole"] = "ee-super-substation",
  -- trains
  ["ee-super-locomotive"] = "ee-infinity-cargo-wagon",
  ["ee-infinity-cargo-wagon"] = "ee-infinity-fluid-wagon"
}

-- INFINITY ACCUMULATOR

constants.ia = {}

constants.ia.entity_names = {
  ["ee-infinity-accumulator-primary-output"] = true,
  ["ee-infinity-accumulator-primary-input"] = true,
  ["ee-infinity-accumulator-secondary-output"] = true,
  ["ee-infinity-accumulator-secondary-input"] = true,
  ["ee-infinity-accumulator-tertiary"] = true
}

constants.ia.index_to_mode = {"output", "input", "buffer"}
constants.ia.index_to_priority = {"primary", "secondary"}

constants.ia.localised_modes = {{"ee-gui.output"}, {"ee-gui.input"}, {"ee-gui.buffer"}}
constants.ia.localised_priorities = {{"ee-gui.primary"}, {"ee-gui.secondary"}}
constants.ia.localised_si_suffixes_joule = {}
constants.ia.localised_si_suffixes_watt = {}

constants.ia.mode_to_index = {output=1, input=2, buffer=3}

constants.ia.power_prefixes = {"kilo", "mega", "giga", "tera", "peta", "exa", "zetta", "yotta"}
constants.ia.power_suffixes_by_mode = {output="watt", input="watt", buffer="joule"}

constants.ia.priority_to_index = {primary=1, secondary=2, tertiary=1}

constants.ia.si_suffixes_joule = {"kJ", "MJ", "GJ", "TJ", "PJ", "EJ", "ZJ", "YJ"}
constants.ia.si_suffixes_watt = {"kW", "MW", "GW", "TW", "PW", "EW", "ZW", "YW"}

for i, v in pairs(constants.ia.power_prefixes) do
  constants.ia.localised_si_suffixes_watt[i] = {"", {"si-prefix-symbol-"..v}, {"si-unit-symbol-watt"}}
  constants.ia.localised_si_suffixes_joule[i] = {"", {"si-prefix-symbol-"..v}, {"si-unit-symbol-joule"}}
end

-- INFINITY LOADER

-- 60 items/second / 60 ticks/second / 8 items/tile = X tiles/tick
constants.belt_speed_for_60_per_second = 60 / 60 / 8

-- pattern -> replacement
-- iterate through all of these to result in the belt type
constants.belt_type_patterns = {
  -- editor extensions :D
  ["ee%-infinity%-loader%-loader%-?"] = "",
  -- beltlayer: https://mods.factorio.com/mod/beltlayer
  ["layer%-connector"] = "",
  -- ultimate belts: https://mods.factorio.com/mod/UltimateBelts
  ["ultimate%-belt"] = "original-ultimate",
  -- krastorio legacy: https://mods.factorio.com/mod/Krastorio
  ["%-?kr%-01"] = "",
  ["%-?kr%-02"] = "fast",
  ["%-?kr%-03"] = "express",
  ["%-?kr%-04"] = "k",
  -- replicating belts: https://mods.factorio.com/mod/replicating-belts
  ["replicating%-?"] = "",
  -- subterranean: https://mods.factorio.com/mod/Subterranean
  ["subterranean"] = "",
  -- factorioextended plus transport: https://mods.factorio.com/mod/FactorioExtended-Plus-Transport
  ["%-to%-ground"] = "",
  -- vanilla
  ["%-?belt"] = "",
  ["%-?transport"] = "",
  ["%-?underground"] = "",
  ["%-?splitter"] = "",
  ["%-?loader"] = ""
}

-- INFINITY PIPE

constants.pipe_snapping_types = {
  ["infinity-pipe"] = true,
  ["offshore-pump"] = true,
  ["pipe-to-ground"] = true,
  ["pipe"] = true,
  ["pump"] = true,
  ["storage-tank"] = true
}

-- INFINITY WAGON

constants.infinity_wagon_names = {
  ["ee-infinity-cargo-wagon"] = true,
  ["ee-infinity-fluid-wagon"] = true
}

return constants