local event = require("__flib__.event")
local gui = require("__flib__.gui-beta")
local migration = require("__flib__.migration")

local constants = require("scripts.constants")
local cheat_mode = require("scripts.cheat-mode")
local compatibility = require("scripts.compatibility")
local global_data = require("scripts.global-data")
local inventory = require("scripts.inventory")
local migrations = require("scripts.migrations")
local on_tick = require("scripts.on-tick")
local player_data = require("scripts.player-data")
local util = require("scripts.util")

local aggregate_chest = require("scripts.entity.aggregate-chest")
local infinity_accumulator = require("scripts.entity.infinity-accumulator")
local infinity_loader = require("scripts.entity.infinity-loader")
local infinity_pipe = require("scripts.entity.infinity-pipe")
local infinity_wagon = require("scripts.entity.infinity-wagon")
local super_inserter = require("scripts.entity.super-inserter")
local super_pump = require("scripts.entity.super-pump")

-- -----------------------------------------------------------------------------
-- COMMANDS

commands.add_command(
  "cheatmode",
  {"command-help.cheatmode"},
  function(e)
    local parameter = e.parameter
    local player = game.get_player(e.player_index)
    if not parameter then
      util.freeze_time_on_all_surfaces(player)
      cheat_mode.enable(player)
    elseif parameter == "all" then
      util.freeze_time_on_all_surfaces(player)
      cheat_mode.enable(player, true)
    elseif parameter == "off" then
      if player.cheat_mode then
        cheat_mode.disable(player, global.players[e.player_index])
      else
        player.print{"ee-message.cheat-mode-already-disabled"}
      end
    end
  end
)

-- -----------------------------------------------------------------------------
-- EVENT HANDLERS
-- `on_tick` event handler is kept and registered in `scripts.on-tick`
-- picker dollies handler is kept in `scripts.entity.infinity-loader` and is registered in `scripts.compatibility`
-- all other event handlers are here

-- BOOTSTRAP

event.on_init(function()
  global_data.init()
  for i, player in pairs(game.players) do
    player_data.init(i)
    -- enable recipes for cheat mode
    if player.cheat_mode then
      cheat_mode.enable_recipes(player)
    end
  end

  compatibility.add_cursor_enhancements_overrides()
  compatibility.register_picker_dollies()

  aggregate_chest.update_data()
  on_tick.register()
end)

event.on_load(function()
  compatibility.register_picker_dollies()

  on_tick.register()
end)

event.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    compatibility.add_cursor_enhancements_overrides()

    aggregate_chest.update_data()
    aggregate_chest.update_all_filters()
    infinity_loader.check_loaders()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
      if player.cheat_mode then
        cheat_mode.enable_recipes(player)
      end
    end
  elseif e.mod_changes["InfinityMode"] then -- if coming from infinity mode, fix infinity loaders
    infinity_loader.check_loaders()
  end
end)

-- CHEAT MODE

event.on_player_cheat_mode_enabled(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]

  -- if the scenario enabled it, the player hasn't been initialized yet
  if not player_table then return end

  -- space exploration - if they are in god mode, they are in the satellite view, so don't unlock recipes
  if compatibility.check_for_space_exploration() and player.controller_type == defines.controllers.god then
    return
  end

  cheat_mode.enable_recipes(player)
end)

-- ENTITY

event.register(
  {
    defines.events.on_built_entity,
    defines.events.on_entity_cloned,
    defines.events.on_robot_built_entity,
    defines.events.script_raised_built,
    defines.events.script_raised_revive,
  },
  function(e)
    local entity = e.entity or e.created_entity or e.destination
    local entity_name = entity.name

    -- aggregate chest
    if constants.aggregate_chest_names[entity_name] then
      aggregate_chest.set_filters(entity)
    -- infinity loader
    elseif entity_name == "entity-ghost" and entity.ghost_name == "ee-infinity-loader-logic-combinator" then
      infinity_loader.build_from_ghost(entity)
    elseif
      entity_name == "ee-infinity-loader-dummy-combinator"
      or entity_name == "ee-infinity-loader-logic-combinator"
    then
      infinity_loader.build(entity)
    elseif entity.type == "transport-belt" then
      -- snap neighbors
      infinity_loader.snap_tile_neighbors(entity)
    elseif entity.type == "underground-belt" then
      -- snap neighbors of both sides
      infinity_loader.snap_tile_neighbors(entity)
      if entity.neighbours then
        infinity_loader.snap_tile_neighbors(entity.neighbours)
      end
    elseif entity.type == "splitter" or entity.type == "loader" or entity.type == "loader-1x1" then
      -- snap belt neighbors
      infinity_loader.snap_belt_neighbors(entity)
    -- infinity wagon
    elseif constants.infinity_wagon_names[entity_name] then
      infinity_wagon.build(entity, e.tags)
      on_tick.register()
    -- super pump
    elseif entity_name == "ee-super-pump" then
      super_pump.setup(entity, e.tags)
    -- only snap manually built entities
    elseif e.name == defines.events.on_built_entity then
      if entity_name == "ee-super-inserter" then
        super_inserter.snap(entity)
      elseif entity_name == "ee-infinity-pipe" then
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
    elseif constants.infinity_wagon_names[entity.name] then
      infinity_wagon.destroy(entity)
    elseif constants.ia.entity_names[entity.name] then
      infinity_accumulator.close_open_guis(entity)
    end
  end
)

event.on_player_rotated_entity(function(e)
  local entity = e.entity
  if entity.name == "ee-infinity-loader-logic-combinator" then
    infinity_loader.rotate(entity, e.previous_direction)
  elseif entity.type == "transport-belt" then
    -- snap neighbors
    infinity_loader.snap_tile_neighbors(entity)
  elseif entity.type == "underground-belt" then
    -- snap neighbors of both sides
    infinity_loader.snap_tile_neighbors(entity)
    if entity.neighbours then
      infinity_loader.snap_tile_neighbors(entity.neighbours)
    end
  elseif entity.type == "splitter" or entity.type == "loader" or entity.type == "loader-1x1" then
    -- snap belt neighbors
    infinity_loader.snap_belt_neighbors(entity)
  end
end)

event.register({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, function(e)
  -- event filter removes the need for a check here
  infinity_wagon.clear_inventory(e.entity)
end)

event.on_cancelled_deconstruction(function(e)
  -- event filter removes the need for a check here
  infinity_wagon.reset(e.entity)
end)

event.register("ee-open-gui", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  infinity_wagon.check_and_open(player, selected)
end)

event.on_entity_settings_pasted(function(e)
  local source = e.source
  local destination = e.destination
  local source_name = source.name
  local destination_name = destination.name

  if
    constants.ia.entity_names[source_name]
    and constants.ia.entity_names[destination_name]
    and source_name ~= destination_name
  then
    infinity_accumulator.paste_settings(source, destination)
  elseif destination_name == "ee-infinity-loader-logic-combinator" then
    infinity_loader.paste_settings(source, destination)
  elseif
    source_name == "ee-infinity-cargo-wagon" and destination_name == "ee-infinity-cargo-wagon"
    or source_name == "ee-infinity-fluid-wagon" and destination_name == "ee-infinity-fluid-wagon"
  then
    infinity_wagon.paste_settings(source, destination)
  elseif source_name == "ee-super-pump" and destination_name == "ee-super-pump" then
    super_pump.paste_settings(source, destination)
  elseif source_name == "constant-combinator" and destination_name == "ee-infinity-pipe" then
    local control = source.get_or_create_control_behavior()
    for _, signal in pairs(control.parameters) do
      if signal.signal.type == "fluid" then
        destination.set_infinity_pipe_filter{name = signal.signal.name}
      end
    end
  elseif source_name == "ee-infinity-pipe" and destination_name == "constant-combinator" then
    local filter = source.get_infinity_pipe_filter()
    if filter then
      local control = destination.get_or_create_control_behavior()
      control.parameters = {parameters = {{signal = {type = "fluid", name = filter.name}, count = 1, index = 1}}}
    end
  end
end)

-- GUI

gui.hook_gui_events()

event.on_gui_opened(function(e)
  if not gui.dispatch(e) then
    local entity = e.entity
    if entity then
      local entity_name = entity.name
      if constants.ia.entity_names[entity_name] then
        infinity_accumulator.open(e.player_index, entity)
      elseif entity_name == "ee-infinity-loader-logic-combinator" then
        infinity_loader.open(e.player_index, entity)
      elseif entity_name == "ee-super-pump" then
        super_pump.open(e.player_index, entity)
      elseif entity_name == "ee-infinity-cargo-wagon" then
        infinity_wagon.open(e.player_index, entity)
      end
    end
  end
end)

event.on_gui_closed(function(e)
  if not gui.dispatch(e) then
    if e.gui_type and e.gui_type == 3 then
      inventory.close_string_gui(e.player_index)
    end
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

  local player = game.get_player(e.player_index)

  if player.cheat_mode then
    cheat_mode.enable_recipes(player)
    cheat_mode.enable(player, compatibility.check_for_testing_scenario())
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

  -- get blueprint
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end

  -- get blueprint entities and mapping
  local entities = bp.get_blueprint_entities()
  if not entities then return end
  local mapping = e.mapping.get()

  -- iterate each entity
  for i = 1, #entities do
    local entity = entities[i]
    local entity_name = entity.name
    if entity_name == "ee-infinity-loader-logic-combinator" then
      entities[i] = infinity_loader.setup_blueprint(entity)
    elseif entity_name == "ee-infinity-cargo-wagon" then
      entities[i] = infinity_wagon.setup_cargo_blueprint(entity, mapping[entity.entity_number])
    elseif entity_name == "ee-infinity-fluid-wagon" then
      entities[i] = infinity_wagon.setup_fluid_blueprint(entity, mapping[entity.entity_number])
    elseif entity_name == "ee-super-pump" then
      entities[i] = super_pump.setup_blueprint(entity, mapping[entity.entity_number])
    end
  end

  -- set entities
  bp.set_blueprint_entities(entities)
end)

event.on_pre_player_toggled_map_editor(function(e)
  local player_table = global.players[e.player_index]
  if not player_table then return end
  if player_table.settings.inventory_sync_enabled then
    inventory.create_sync_inventories(player_table, game.get_player(e.player_index))
  end
end)

event.on_player_toggled_map_editor(function(e)
  local player_table = global.players[e.player_index]
  if not player_table then return end

  -- the first time someone toggles the map editor, unpause the current tick
  if global.flags.map_editor_toggled == false then
    global.flags.map_editor_toggled = true
    if settings.global["ee-prevent-initial-pause"].value then
      game.tick_paused = false
    end
  end

  local player = game.get_player(e.player_index)
  local to_state = player.controller_type == defines.controllers.editor

  -- update shortcut toggled state
  player.set_shortcut_toggled("ee-toggle-map-editor", to_state)

  -- apply default infinity filters if this is their first time in the editor
  if to_state and not player_table.flags.map_editor_toggled then
    player_table.flags.map_editor_toggled = true
    local default_filters = player_table.settings.default_infinity_filters
    if default_filters ~= "" then
      inventory.import_filters(player, default_filters)
    end
  end

  -- close infinity filters GUIs if they're open
  if not to_state then
    inventory.close_string_gui(e.player_index)
  end

  -- finish inventory sync
  if player_table.settings.inventory_sync_enabled and player_table.sync_data then
    inventory.get_from_sync_inventories(player_table, player)
  end

  -- update character cheats if necessary
  if
    player.controller_type == defines.controllers.character
    and player_table.flags.update_character_cheats_when_possible
  then
    -- negate flag
    player_table.flags.update_character_cheats_when_possible = false
    -- enable or disable cheats
    cheat_mode.update_character_cheats(player)
  end

  -- push or unpush GUIs
  if to_state then
    player.gui.top.style.left_margin = constants.editor_gui_width
    player.gui.left.style.left_margin = constants.editor_gui_width
  else
    player.gui.top.style.left_margin = 0
    player.gui.left.style.left_margin = 0
  end
end)

-- SETTINGS

event.on_runtime_mod_setting_changed(function(e)
  if e.setting == "ee-aggregate-include-hidden" then
    aggregate_chest.update_data()
    aggregate_chest.update_all_filters()
  elseif game.mod_setting_prototypes[e.setting].mod == "EditorExtensions" and e.setting_type == "runtime-per-user" then
    local player = game.get_player(e.player_index)
    local player_table = global.players[e.player_index]
    player_data.update_settings(player, player_table)
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT FILTERS

event.set_filters(
  {
    defines.events.on_built_entity,
    defines.events.on_entity_cloned,
    defines.events.on_robot_built_entity
  },
  {
    {filter = "name", name = "ee-aggregate-chest-passive-provider"},
    {filter = "name", name = "ee-aggregate-chest"},
    {filter = "name", name = "ee-infinity-cargo-wagon"},
    {filter = "name", name = "ee-infinity-fluid-wagon"},
    {filter = "name", name = "ee-infinity-loader-dummy-combinator"},
    {filter = "name", name = "ee-infinity-loader-logic-combinator"},
    {filter = "name", name = "ee-infinity-pipe"},
    {filter = "name", name = "ee-super-inserter"},
    {filter = "name", name = "ee-super-pump"},
    {filter = "type", type = "transport-belt"},
    {filter = "type", type = "underground-belt"},
    {filter = "type", type = "splitter"},
    {filter = "type", type = "loader"},
    {filter = "ghost"},
    {filter = "ghost_name", name = "ee-infinity-loader-logic-combinator"},
    {filter = "ghost_name", name = "ee-super-pump"}
  }
)

event.set_filters({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, {
  {filter = "name", name = "ee-infinity-accumulator-primary-output"},
  {filter = "name", name = "ee-infinity-accumulator-primary-input"},
  {filter = "name", name = "ee-infinity-accumulator-secondary-output"},
  {filter = "name", name = "ee-infinity-accumulator-secondary-input"},
  {filter = "name", name = "ee-infinity-accumulator-tertiary-buffer"},
  {filter = "name", name = "ee-infinity-accumulator-tertiary-input"},
  {filter = "name", name = "ee-infinity-accumulator-tertiary-output"},
  {filter = "name", name = "ee-infinity-loader-dummy-combinator"},
  {filter = "name", name = "ee-infinity-loader-logic-combinator"},
  {filter = "name", name = "ee-infinity-cargo-wagon"},
  {filter = "name", name = "ee-infinity-fluid-wagon"},
})

event.set_filters({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, {
  {filter = "name", name = "ee-infinity-cargo-wagon"}
})

event.set_filters(defines.events.on_cancelled_deconstruction, {
  {filter = "name", name = "ee-infinity-cargo-wagon"}
})
