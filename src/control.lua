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
local shared = require("scripts.shared")
local util = require("scripts.util")

local aggregate_chest = require("scripts.entity.aggregate-chest")
local infinity_accumulator = require("scripts.entity.infinity-accumulator")
local infinity_loader = require("scripts.entity.infinity-loader")
local infinity_pipe = require("scripts.entity.infinity-pipe")
local infinity_wagon = require("scripts.entity.infinity-wagon")
local linked_belt = require("scripts.entity.linked-belt")
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
    global_data.read_fastest_belt_type()

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

-- CUSTOM INPUT

event.register("ee-toggle-map-editor", function(e)
  local player = game.get_player(e.player_index)
  if player.admin then
    player.toggle_map_editor()
  else
    player.print{"ee-message.map-editor-denied"}
  end
end)

event.register("ee-open-gui", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  if player.selected then
    if infinity_wagon.check_is_wagon(selected) then
      if player.can_reach_entity(selected) then
        infinity_wagon.open(player, selected)
      else
        util.error_text(player, {"cant-reach"}, selected.position)
      end
    elseif
      linked_belt.check_is_linked_belt(selected)
      and not (player.cursor_stack and player.cursor_stack.valid_for_read)
    then
      local player_table = global.players[e.player_index]
      if player_table.flags.connecting_linked_belts then
        linked_belt.finish_connection(player, player_table, selected)
      else
        linked_belt.start_connection(player, player_table, selected)
      end
    end
  end
end)

event.register("ee-paste-entity-settings", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  if selected and linked_belt.check_is_linked_belt(selected) then
    local player_table = global.players[e.player_index]
    if player_table.flags.connecting_linked_belts then
      linked_belt.finish_connection(player, player_table, selected, true)
    else
      linked_belt.start_connection(player, player_table, selected, true)
    end
  end
end)

event.register("ee-copy-entity-settings", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  if selected and linked_belt.check_is_linked_belt(selected) and selected.linked_belt_neighbour then
    local player_table = global.players[e.player_index]
    linked_belt.sever_connection(player, player_table, selected)
  end
end)

event.register("ee-fast-entity-transfer", function(e)
  local player = game.get_player(e.player_index)
  local selected = player.selected
  if selected and linked_belt.check_is_linked_belt(selected) then
    linked_belt.sync_belt_types(player, selected)
  end
end)

event.register("ee-clear-cursor", function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.connecting_linked_belts then
    local player = game.get_player(e.player_index)
    linked_belt.cancel_connection(player, player_table)
    player_table.last_cleared_cursor_tick = game.ticks_played
  end
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
    -- transport belt connectables
    elseif
      entity.type == "transport-belt"
      or entity.type == "underground-belt"
      or entity.type == "splitter"
      or entity.type == "loader"
      or entity.type == "loader-1x1"
    then
      -- generic other snapping
      shared.snap_belt_neighbours(entity)
      if entity.type == "underground-belt" and entity.neighbours then
        shared.snap_belt_neighbours(entity.neighbours)
      end
    -- infinity wagon
    elseif constants.infinity_wagon_names[entity_name] then
      infinity_wagon.build(entity, e.tags)
      on_tick.register()
    -- linked belt
    elseif linked_belt.check_is_linked_belt(entity) then
      linked_belt.snap(entity)
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
    elseif linked_belt.check_is_linked_belt(entity) then
      local players = global.linked_belt_sources[entity.unit_number]
      if players then
        for player_index in pairs(players) do
          local player = game.get_player(player_index)
          local player_table = global.players[player_index]
          linked_belt.cancel_connection(player, player_table)
        end
      end
    end
  end
)

event.on_player_rotated_entity(function(e)
  local entity = e.entity
  if entity.name == "ee-infinity-loader-logic-combinator" then
    shared.snap_belt_neighbours(infinity_loader.rotate(entity, e.previous_direction))
  elseif
    entity.type == "transport-belt"
    or entity.type == "underground-belt"
    or entity.type == "splitter"
    or entity.type == "loader"
    or entity.type == "loader-1x1"
  then
    shared.snap_belt_neighbours(entity)
    if entity.type == "underground-belt" and entity.neighbours then
      shared.snap_belt_neighbours(entity.neighbours)
    end
  elseif linked_belt.check_is_linked_belt(entity) then
    linked_belt.handle_rotation(e)
    shared.snap_belt_neighbours(entity)
    local neighbour = entity.linked_belt_neighbour
    if neighbour and neighbour.type ~= "entity-ghost" then
      shared.snap_belt_neighbours(neighbour)
    end
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
  elseif source.type == "constant-combinator" and destination_name == "ee-infinity-loader-logic-combinator" then
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
      control.parameters = {{signal = {type = "fluid", name = filter.name}, count = 1, index = 1}}
    end
  end
end)

event.on_selected_entity_changed(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  linked_belt.render_connection(player, player_table)
end)

-- GUI

gui.hook_events(function(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "ia" then
      infinity_accumulator.handle_gui_action(e, msg)
    elseif msg.gui == "il" then
      infinity_loader.handle_gui_action(e, msg)
    elseif msg.gui == "sp" then
      super_pump.handle_gui_action(e, msg)
    elseif msg.gui == "inv_filters" then
      inventory.handle_gui_action(e, msg)
    end
  elseif e.name == defines.events.on_gui_opened then
    local entity = e.entity
    if entity then
      local entity_name = entity.name
      if constants.ia.entity_names[entity_name] then
        infinity_accumulator.open(e.player_index, entity)
      elseif entity_name == "ee-infinity-loader-logic-combinator" then
        infinity_loader.open(e.player_index, entity)
      elseif entity_name == "ee-super-pump" then
        super_pump.open(e.player_index, entity)
      elseif infinity_wagon.check_is_wagon(entity) then
        local player = game.get_player(e.player_index)
        infinity_wagon.open(player, entity)
      end
    end
  elseif e.name == defines.events.on_gui_closed then
    if e.gui_type and e.gui_type == defines.gui_type.controller then
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

event.on_player_cursor_stack_changed(function(e)
  local player = game.get_player(e.player_index)
  local player_table = global.players[e.player_index]
  if player_table.flags.connecting_linked_belts then
    linked_belt.cancel_connection(player, player_table)
  end
  local cursor_stack = player.cursor_stack
  if player_table.last_cleared_cursor_tick == game.ticks_played and (cursor_stack and cursor_stack.valid_for_read) then
    player.clear_cursor()
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
    {filter = "type", type = "loader-1x1"},
    {filter = "type", type = "linked-belt"},
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
  {filter = "type", type = "linked-belt"}
})

event.set_filters({defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction}, {
  {filter = "name", name = "ee-infinity-cargo-wagon"}
})

event.set_filters(defines.events.on_cancelled_deconstruction, {
  {filter = "name", name = "ee-infinity-cargo-wagon"}
})

-- -----------------------------------------------------------------------------
-- SHARED

function shared.snap_belt_neighbours(entity)
  local loaders = {}
  local linked_belts = {}

  local linked_belt_neighbour
  if entity.type == "linked-belt" then
    linked_belt_neighbour = entity.linked_belt_neighbour
    if linked_belt_neighbour then
      entity.disconnect_linked_belts()
    end
  end

  for _ = 1, entity.type == "transport-belt" and 4 or 2 do
    -- catalog belt neighbours for this rotation
    for _, neighbours in pairs(entity.belt_neighbours) do
      for _, neighbour in ipairs(neighbours) do
        if infinity_loader.check_is_loader(neighbour) then
          loaders[neighbour.unit_number or (#loaders + 1)] = neighbour
        elseif linked_belt.check_is_linked_belt(neighbour) then
          linked_belts[neighbour.unit_number or (#linked_belts + 1)] = neighbour
        end
      end
    end
    -- rotate or flip linked belt type
    if entity.type == "linked-belt" then
      entity.linked_belt_type = entity.linked_belt_type == "output" and "input" or "output"
    else
      entity.rotate()
    end
  end

  if linked_belt_neighbour then
    entity.connect_linked_belts(linked_belt_neighbour)
  end

  for _, loader in pairs(loaders) do
    infinity_loader.snap(loader, entity)
  end
  for _, belt in pairs(linked_belts) do
    linked_belt.snap(belt, entity)
  end
end
