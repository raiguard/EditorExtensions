local event = require("__flib__.event")
local gui = require("__flib__.gui")
local migration = require("__flib__.migration")

local cheat_mode = require("scripts.cheat-mode")
local global_data = require("scripts.global-data")
local inventory = require("scripts.inventory")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")

require("scripts.common-gui")

local aggregate_chest = require("scripts.entity.aggregate-chest")
local infinity_accumulator = require("scripts.entity.infinity-accumulator")
local infinity_loader = require("scripts.entity.infinity-loader")
local infinity_pipe = require("scripts.entity.infinity-pipe")
local infinity_wagon = require("scripts.entity.infinity-wagon")
local super_inserter = require("scripts.entity.super-inserter")

local string = string

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command("EditorExtensions", {"ee-message.command-help"}, function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if e.parameter == "toggle-inventory-sync" then
    inventory.toggle_sync(player, player_table, not player_table.flags.inventory_sync_enabled)
  elseif e.parameter == "disable-cheat-mode" and player.cheat_mode then
    cheat_mode.disable(player, player_table)
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- on_tick event handler is kept in scripts.on-tick

-- BOOTSTRAP

event.on_init(function()
  gui.init()

  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    event.register(remote.call("PickerDollies", "dolly_moved_entity_id"), infinity_loader.picker_dollies_move)
  end

  global_data.init()
  for i in pairs(game.players) do
    player_data.init(i)
  end

  on_tick.update()
  aggregate_chest.update_data()

  gui.build_lookup_tables()
end)

event.on_load(function()
  if remote.interfaces["PickerDollies"] and remote.interfaces["PickerDollies"]["dolly_moved_entity_id"] then
    event.register(remote.call("PickerDollies", "dolly_moved_entity_id"), infinity_loader.picker_dollies_move)
  end

  on_tick.update()

  gui.build_lookup_tables()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
      if player.cheat_mode then
        cheat_mode.enable_recipes(player)
      end
    end
    infinity_loader.check_loaders()
    aggregate_chest.update_data()
    aggregate_chest.update_all_filters()
  else -- post-init setup
    for i, player in pairs(game.players) do
      if player.cheat_mode then
        cheat_mode.enable_recipes(player)
        inventory.toggle_sync(player, global.players[i])
      end
    end
  end
end)

-- CHEAT MODE

event.on_player_cheat_mode_enabled(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  cheat_mode.enable_recipes(player)
  if player_table.settings.inventory_sync then
    inventory.toggle_sync(player, player_table)
  end
end)

event.on_player_cheat_mode_disabled(function(e)
  local player_table = global.players[e.player_index]
  if player_table.settings.inventory_sync then
    inventory.toggle_sync(game.get_player(e.player_index), player_table, false)
  end
end)

event.on_console_command(function(e)
  if e.command == "cheat" and e.parameters == "all" then
    local player = game.get_player(e.player_index)
    if player.cheat_mode then
      cheat_mode.set_loadout(player)
      game.print{"ee-message.time-frozen"}
    end
  end
end)

-- ENTITIES

event.register(
  {
    defines.events.on_built_entity,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive
  },
  function(e)
    local entity = e.entity or e.created_entity
    if infinity_loader.on_built(entity) then
      -- pass
    elseif infinity_wagon.wagon_names[entity.name] then
      infinity_wagon.build(entity, e.tags)
      on_tick.update()
    elseif string.sub(entity.name, 1, 18) == "ee-aggregate-chest" then
      aggregate_chest.set_filters(entity)
    -- only snap manually built entities
    elseif e.name == defines.events.on_built_entity then
      if entity.name == "ee-super-inserter" then
        super_inserter.snap(entity)
      elseif entity.name == "ee-infinity-pipe" then
        infinity_pipe.snap(entity, global.players[e.player_index].settings)
      end
    end
  end
)

event.register(
  {
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_entity_died,
    defines.events.script_raised_destroy
  },
  function(e)
    local entity = e.entity
    if entity.name == "ee-infinity-loader-logic-combinator" then
      infinity_loader.destroy(entity)
    elseif infinity_wagon.wagon_names[entity.name] then
      infinity_wagon.destroy(entity)
    elseif infinity_accumulator.check_name(entity) then
      infinity_accumulator.close_open_guis(entity)
    end
  end
)

event.on_player_rotated_entity(function(e)
  infinity_loader.on_rotated(e)
end)

event.register({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, function(e)
  -- event filter removes the need for a check here
  infinity_wagon.clear_inventory(e.entity)
end)

event.on_cancelled_deconstruction(function(e)
  -- event filter removes the need for a check here
  infinity_wagon.reset(e.entity)
end)

event.register("ee-mouse-leftclick", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  infinity_wagon.check_and_open(player, selected)
end)

event.on_entity_settings_pasted(function(e)
  if infinity_accumulator.check_name(e.source) and infinity_accumulator.check_name(e.destination) and e.source.name ~= e.destination.name then
    infinity_accumulator.paste_settings(e.source, e.destination)
  elseif e.destination.name == "ee-infinity-loader-logic-combinator" then
    infinity_loader.paste_settings(e.source, e.destination)
  elseif (e.source.name == "ee-infinity-cargo-wagon" and e.destination.name == "ee-infinity-cargo-wagon")
    or e.source.name == "ee-infinity-fluid-wagon" and e.destination.name == "ee-infinity-fluid-wagon"
  then
    infinity_wagon.paste_settings(e.source, e.destination)
  end
end)

-- GUI

gui.register_handlers()

event.on_gui_opened(function(e)
  if not gui.dispatch_handlers(e) then
    local entity = e.entity
    if entity then
      if infinity_accumulator.check_name(entity) then
        infinity_accumulator.open(e.player_index, entity)
      elseif entity.name == "ee-infinity-loader-logic-combinator" then
        infinity_loader.open(e.player_index, entity)
      elseif entity.name == "ee-infinity-cargo-wagon" then
        infinity_wagon.open(e.player_index, entity)
      end
    elseif e.gui_type and e.gui_type == 3 then
      local player = game.get_player(e.player_index)
      if player.controller_type == defines.controllers.editor then
        inventory.create_filters_buttons(player)
      end
    end
  end
end)

event.on_gui_closed(function(e)
  if not gui.dispatch_handlers(e) then
    inventory.on_gui_closed(e)
  end
end)

-- SHORTCUT

event.on_lua_shortcut(function(e)
  if e.prototype_name == "ee-toggle-map-editor" then
    game.get_player(e.player_index).toggle_map_editor()
  end
end)

event.register("ee-toggle-map-editor", function(e)
  local player = game.get_player(e.player_index)
  if player.admin then
    player.toggle_map_editor()
  else
    player.print{"ee-message.map-editor-denied"}
  end
end)

-- PLAYER

event.on_player_created(function(e)
  player_data.init(e.player_index)

  if global.flags.in_testing_scenario then
    cheat_mode.enable(game.get_player(e.player_index))
  end
end)

event.on_player_removed(function(e)
  global.players[e.player_index] = nil
end)

event.register({defines.events.on_player_promoted, defines.events.on_player_demoted}, function(e)
  local player = game.get_player(e.player_index)
  -- lock or unlock the shortcut depending on if they're an admin
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)
end)

event.on_player_setup_blueprint(function(e)
  local player = game.get_player(e.player_index)
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end
  local entities = bp.get_blueprint_entities()
  if not entities then return end
  local mapping = e.mapping.get()
  for i=1,#entities do
    local entity = entities[i]
    if entity.name == "ee-infinity-loader-logic-combinator" then
      entities[i] = infinity_loader.setup_blueprint(entity)
    elseif entity.name == "ee-infinity-cargo-wagon" then
      entities[i] = infinity_wagon.setup_cargo_blueprint(entity, mapping[entity.entity_number])
    elseif entity.name == "ee-infinity-fluid-wagon" then
      entities[i] = infinity_wagon.setup_fluid_blueprint(entity, mapping[entity.entity_number])
    end
  end
  bp.set_blueprint_entities(entities)
end)

event.on_pre_player_toggled_map_editor(function(e)
  inventory.on_pre_player_toggled_map_editor(e)
end)

event.on_player_toggled_map_editor(function(e)
  -- the first time someone toggles the map editor, unpause the current tick
  if global.flags.map_editor_toggled == false then
    global.flags.map_editor_toggled = true
    if settings.global["ee-prevent-initial-pause"].value then
      game.tick_paused = false
    end
  end

  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  local to_state = player.controller_type == defines.controllers.editor

  -- update shortcut toggled state
  player.set_shortcut_toggled("ee-toggle-map-editor", to_state)

  -- apply default inventory filters if this is their first time in the editor
  if to_state and not player_table.flags.map_editor_toggled then
    player_table.flags.map_editor_toggled = true
    local default_filters = player_table.settings.default_inventory_filters
    if default_filters ~= "" then
      inventory.import_inventory_filters(player, default_filters)
    end
  end

  inventory.on_player_toggled_map_editor(e)
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if e.setting == "ee-aggregate-include-hidden" then
    aggregate_chest.update_data()
    aggregate_chest.update_all_filters()
  elseif string.sub(e.setting, 1, 3) == "ee-" and e.setting_type == "runtime-per-user" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    data.update_player_settings(player, player_table)
    if e.setting == "ee-inventory-sync" then
      inventory.toggle_sync(player, player_table)
    end
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT FILTERS

event.set_filters({defines.events.on_built_entity, defines.events.on_robot_built_entity}, {
  {filter="name", name="ee-infinity-loader-dummy-combinator"},
  {filter="name", name="ee-infinity-loader-logic-combinator"},
  {filter="name", name="ee-infinity-cargo-wagon"},
  {filter="name", name="ee-infinity-fluid-wagon"},
  {filter="name", name="ee-aggregate-chest"},
  {filter="name", name="ee-aggregate-chest-passive-provider"},
  {filter="name", name="ee-super-inserter"},
  {filter="name", name="ee-infinity-pipe"},
  {filter="type", type="transport-belt"},
  {filter="type", type="underground-belt"},
  {filter="type", type="splitter"},
  {filter="type", type="loader"},
  {filter="ghost"},
  {filter="ghost_name", name="ee-infinity-loader-logic-combinator"}
})

event.set_filters({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, {
  {filter="name", name="ee-infinity-accumulator-primary-output"},
  {filter="name", name="ee-infinity-accumulator-primary-input"},
  {filter="name", name="ee-infinity-accumulator-secondary-output"},
  {filter="name", name="ee-infinity-accumulator-secondary-input"},
  {filter="name", name="ee-infinity-accumulator-tertiary"},
  {filter="name", name="ee-infinity-loader-dummy-combinator"},
  {filter="name", name="ee-infinity-loader-logic-combinator"},
  {filter="name", name="ee-infinity-cargo-wagon"},
  {filter="name", name="ee-infinity-fluid-wagon"},
})

event.set_filters({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, {
  {filter="name", name="ee-infinity-cargo-wagon"}
})

event.set_filters(defines.events.on_cancelled_deconstruction, {
  {filter="name", name="ee-infinity-cargo-wagon"}
})