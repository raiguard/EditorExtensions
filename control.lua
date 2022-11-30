local gui = require("__flib__/gui")
local migration = require("__flib__/migration")

local cheat_mode = require("__EditorExtensions__/scripts/cheat-mode")
local compatibility = require("__EditorExtensions__/scripts/compatibility")
local constants = require("__EditorExtensions__/scripts/constants")
local debug_world = require("__EditorExtensions__/scripts/debug-world")
local global_data = require("__EditorExtensions__/scripts/global-data")
local inventory = require("__EditorExtensions__/scripts/inventory")
local migrations = require("__EditorExtensions__/scripts/migrations")
local player_data = require("__EditorExtensions__/scripts/player-data")
local testing_lab = require("__EditorExtensions__/scripts/testing-lab")
local util = require("__EditorExtensions__/scripts/util")

local aggregate_chest = require("__EditorExtensions__/scripts/entity/aggregate-chest")
local infinity_accumulator = require("__EditorExtensions__/scripts/entity/infinity-accumulator")
local infinity_loader = require("__EditorExtensions__/scripts/entity/infinity-loader")
local infinity_pipe = require("__EditorExtensions__/scripts/entity/infinity-pipe")
local infinity_wagon = require("__EditorExtensions__/scripts/entity/infinity-wagon")
local linked_belt = require("__EditorExtensions__/scripts/entity/linked-belt")
local super_inserter = require("__EditorExtensions__/scripts/entity/super-inserter")
local super_pump = require("__EditorExtensions__/scripts/entity/super-pump")

--- @param entity LuaEntity
local function snap_belt_neighbours(entity)
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

remote.add_interface("EditorExtensions", {
  --- An event that fires when the debug world has finished generating.
  debug_world_ready_event = function()
    return constants.debug_world_ready_event
  end,
  --- Get the force the player is actually on, ignoring the testing lab force.
  --- @param player LuaPlayer
  --- @return ForceIdentification
  get_player_proper_force = function(player)
    if not player or not player.valid then
      error("Did not pass a valid LuaPlayer")
    end
    if not global.players then
      return player.force
    end
    local player_table = global.players[player.index]
    if player_table and player_table.normal_state and player.controller_type == defines.controllers.editor then
      return player_table.normal_state.force
    else
      return player.force
    end
  end,
})

-- BOOTSTRAP

script.on_init(function()
  global_data.init()
  global_data.read_fastest_belt_type()

  compatibility.add_cursor_enhancements_overrides()
  compatibility.register_picker_dollies()

  aggregate_chest.update_data()

  infinity_loader.init()
  infinity_pipe.init()

  debug_world.init()

  for _, player in pairs(game.players) do
    player_data.init(player)
    -- enable recipes for cheat mode
    -- space exploration - do nothing if they are in the satellite view
    if player.cheat_mode and not compatibility.in_se_satellite_view(player) then
      cheat_mode.enable_recipes(player)
    end
  end
end)

script.on_load(function()
  compatibility.register_picker_dollies()

  for _, player_table in pairs(global.players) do
    local pipe_gui = player_table.gui.infinity_pipe
    if pipe_gui then
      infinity_pipe.load_gui(pipe_gui)
    end
  end
end)

script.on_configuration_changed(function(e)
  if migration.on_config_changed(e, migrations) then
    global_data.read_fastest_belt_type()

    compatibility.add_cursor_enhancements_overrides()

    aggregate_chest.update_data()
    aggregate_chest.update_all_filters()
    infinity_loader.cleanup_orphans()

    for i, player in pairs(game.players) do
      player_data.refresh(player, global.players[i])
      -- space exploration - do nothing if they are in the satellite view
      if player.cheat_mode and not compatibility.in_se_satellite_view(player) then
        cheat_mode.enable_recipes(player)
      end
    end
  end
end)

-- CHEAT MODE

script.on_event(defines.events.on_player_cheat_mode_enabled, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local player_table = global.players[e.player_index]

  -- if the scenario enabled it, the player hasn't been initialized yet
  if not player_table then
    return
  end

  -- space exploration - do nothing if they are in the satellite view
  if compatibility.in_se_satellite_view(player) then
    return
  end

  cheat_mode.enable_recipes(player)
end)

-- COMMAND

script.on_event(defines.events.on_console_command, function(e)
  if e.command == "cheat" then
    local tried_tick = global.tried_cheat_command[e.player_index]
    if
      global.executed_cheat_command[e.player_index] or (tried_tick and tried_tick + (60 * 60) >= game.ticks_played)
    then
      global.executed_cheat_command[e.player_index] = true
      global.tried_cheat_command[e.player_index] = nil

      local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
      if e.parameters == "lab" then
        debug_world.lab(player.surface)
      elseif e.parameters == "all" then
        cheat_mode.set_loadout(player)
      end
    else
      global.tried_cheat_command[e.player_index] = game.ticks_played
    end
  end
end)

-- CUSTOM INPUT

script.on_event("ee-toggle-map-editor", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]

  -- quick item search compatibility
  if not compatibility.in_qis_window(player) then
    if player.admin then
      player.toggle_map_editor()
    else
      player.print({ "ee-message.map-editor-denied" })
    end
  end
end)

script.on_event("ee-open-gui", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local selected = player.selected
  if selected then
    if infinity_wagon.check_is_wagon(selected) then
      if player.can_reach_entity(selected) then
        infinity_wagon.open(player, selected)
      else
        util.error_text(player, { "cant-reach" }, selected.position)
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

script.on_event("ee-copy-entity-settings", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local selected = player.selected
  if selected and linked_belt.check_is_linked_belt(selected) and selected.linked_belt_neighbour then
    local player_table = global.players[e.player_index]
    linked_belt.sever_connection(player, player_table, selected)
  end
end)

script.on_event("ee-paste-entity-settings", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
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

script.on_event("ee-fast-entity-transfer", function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local selected = player.selected
  if selected and linked_belt.check_is_linked_belt(selected) then
    linked_belt.sync_belt_types(player, selected)
  end
end)

script.on_event("ee-clear-cursor", function(e)
  local player_table = global.players[e.player_index]
  if player_table.flags.connecting_linked_belts then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    linked_belt.cancel_connection(player, player_table)
    player_table.last_cleared_cursor_tick = game.ticks_played
  end
end)

-- ENTITY

script.on_event({
  defines.events.on_built_entity,
  defines.events.on_entity_cloned,
  defines.events.on_robot_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
}, function(e)
  local entity = e.entity or e.created_entity or e.destination
  local entity_name = entity.name

  -- aggregate chest
  if constants.aggregate_chest_names[entity_name] then
    aggregate_chest.set_filters(entity)
  elseif infinity_loader.check_is_loader(entity) then
    infinity_loader.on_built(entity)
  elseif
    entity.type == "transport-belt"
    or entity.type == "underground-belt"
    or entity.type == "splitter"
    or entity.type == "loader"
    or entity.type == "loader-1x1"
  then
    -- generic other snapping
    snap_belt_neighbours(entity)
    if entity.type == "underground-belt" and entity.neighbours then
      snap_belt_neighbours(entity.neighbours)
    end
  elseif constants.infinity_wagon_names[entity_name] then
    infinity_wagon.build(entity, e.tags)
  elseif linked_belt.check_is_linked_belt(entity) then
    linked_belt.snap(entity)
  elseif entity_name == "ee-super-pump" then
    super_pump.setup(entity, e.tags)
  elseif entity_name == "ee-super-inserter" and e.name == defines.events.on_built_entity then
    super_inserter.snap(entity)
  elseif infinity_pipe.check_is_our_pipe(entity) then
    infinity_pipe.store_amount_type(entity, e.tags)
    -- Only snap manually built pipes
    if e.name == defines.events.on_built_entity then
      infinity_pipe.snap(entity, global.players[e.player_index].settings)
    end
  end
end)

script.on_event({
  defines.events.on_player_mined_entity,
  defines.events.on_robot_mined_entity,
  defines.events.on_entity_died,
  defines.events.script_raised_destroy,
}, function(e)
  local entity = e.entity
  if infinity_loader.check_is_loader(entity) then
    infinity_loader.on_destroyed(entity)
  elseif constants.infinity_wagon_names[entity.name] then
    infinity_wagon.destroy(entity)
  elseif constants.ia.entity_names[entity.name] then
    infinity_accumulator.close_open_guis(entity)
  elseif linked_belt.check_is_linked_belt(entity) then
    local players = global.linked_belt_sources[entity.unit_number]
    if players then
      for player_index in pairs(players) do
        local player = game.get_player(player_index) --[[@as LuaPlayer]]
        local player_table = global.players[player_index]
        linked_belt.cancel_connection(player, player_table)
      end
    end
  elseif infinity_pipe.check_is_our_pipe(entity) then
    infinity_pipe.remove_stored_amount_type(entity)
    local unit_number = entity.unit_number
    for _, player_table in pairs(global.players) do
      --- @type InfinityPipeGui
      local pipe_gui = player_table.gui.infinity_pipe
      if pipe_gui and pipe_gui.entity.valid and pipe_gui.entity.unit_number == unit_number then
        pipe_gui:destroy()
      end
    end
  end
end)

script.on_event(defines.events.on_player_rotated_entity, function(e)
  local entity = e.entity
  if
    entity.type == "transport-belt"
    or entity.type == "underground-belt"
    or entity.type == "splitter"
    or entity.type == "loader"
    or entity.type == "loader-1x1"
  then
    snap_belt_neighbours(entity)
    if entity.type == "underground-belt" and entity.neighbours then
      snap_belt_neighbours(entity.neighbours)
    end
  elseif infinity_loader.check_is_loader(entity) then
    infinity_loader.sync_chest_filter(entity)
    snap_belt_neighbours(entity)
  elseif linked_belt.check_is_linked_belt(entity) then
    linked_belt.handle_rotation(e)
    snap_belt_neighbours(entity)
    local neighbour = entity.linked_belt_neighbour
    if neighbour and neighbour.type ~= "entity-ghost" then
      snap_belt_neighbours(neighbour)
    end
  end
end)

script.on_event({ defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction }, function(e)
  -- event filter removes the need for a check here
  infinity_wagon.clear_inventory(e.entity)
end)

script.on_event(defines.events.on_cancelled_deconstruction, function(e)
  -- event filter removes the need for a check here
  infinity_wagon.reset(e.entity)
end)

script.on_event(defines.events.on_entity_settings_pasted, function(e)
  local source = e.source
  local destination = e.destination
  local source_type = source.type
  local source_name = source.name
  local destination_type = destination.type
  local destination_name = destination.name
  local destination_unit_number = destination.unit_number

  local infinity_pipe_updated = false

  if
    constants.ia.entity_names[source_name]
    and constants.ia.entity_names[destination_name]
    and source_name ~= destination_name
  then
    infinity_accumulator.paste_settings(source, destination)
  elseif infinity_loader.check_is_loader(destination) then
    -- TODO: Handle to/from a constant combinator
    infinity_loader.sync_chest_filter(destination)
  elseif
    source_name == "ee-infinity-cargo-wagon" and destination_name == "ee-infinity-cargo-wagon"
    or source_name == "ee-infinity-fluid-wagon" and destination_name == "ee-infinity-fluid-wagon"
  then
    infinity_wagon.paste_settings(source, destination)
  elseif source_name == "ee-super-pump" and destination_name == "ee-super-pump" then
    super_pump.paste_settings(source, destination)
  elseif source_name == "constant-combinator" and destination_type == "infinity-pipe" then
    local control = source.get_or_create_control_behavior()
    --- @cast control LuaConstantCombinatorControlBehavior
    for _, signal in pairs(control.parameters) do
      if signal.signal.type == "fluid" then
        destination.set_infinity_pipe_filter({ name = signal.signal.name, percentage = 1 })
        infinity_pipe_updated = true
      end
    end
  elseif source_type == "infinity-pipe" and destination_name == "constant-combinator" then
    local filter = source.get_infinity_pipe_filter()
    if filter then
      local control = destination.get_or_create_control_behavior()
      control.parameters = {
        { signal = { type = "fluid", name = filter.name }, count = filter.percentage * 100, index = 1 },
      }
    end
  elseif infinity_pipe.check_is_our_pipe(source) and infinity_pipe.check_is_our_pipe(destination) then
    infinity_pipe_updated = true
    destination = infinity_pipe.paste_settings(source, destination)
  end

  if infinity_pipe_updated then
    for _, player_table in pairs(global.players) do
      --- @type InfinityPipeGui
      local pipe_gui = player_table.gui.infinity_pipe
      if pipe_gui and pipe_gui.entity_unit_number == destination_unit_number then
        -- Update state for the new entity
        pipe_gui.entity = destination
        pipe_gui.entity_unit_number = destination.unit_number
        pipe_gui.state.amount_type = global.infinity_pipe_amount_types[destination.unit_number]
          or constants.infinity_pipe_amount_type.percent
        pipe_gui.state.capacity = destination.fluidbox.get_capacity(1)
        pipe_gui.state.filter = source.get_infinity_pipe_filter()
        -- Update the GUI, including entity preview
        pipe_gui:update(true)
      end
    end
  end
end)

script.on_event(defines.events.on_selected_entity_changed, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  local player_table = global.players[e.player_index]
  linked_belt.render_connection(player, player_table)
end)

-- FORCE

script.on_event(defines.events.on_research_reversed, function(e)
  local parent_force = e.research.force
  -- Don't do anything if this is a testing force
  if string.find(parent_force.name, "EE_TESTFORCE_") then
    return
  end

  if settings.global["ee-testing-lab-match-research"].value then
    local force = game.forces["EE_TESTFORCE_" .. parent_force.name]
    if force then
      force.technologies[e.research.name].researched = false
    end

    for i in pairs(parent_force.players) do
      local force = game.forces["EE_TESTFORCE_" .. i]
      if force then
        force.technologies[e.research.name].researched = false
      end
    end
  end
end)

script.on_event(defines.events.on_research_finished, function(e)
  local parent_force = e.research.force
  -- Don't do anything if a testing force finished a research
  if string.find(parent_force.name, "EE_TESTFORCE_") then
    return
  end

  if settings.global["ee-testing-lab-match-research"].value then
    local force = game.forces["EE_TESTFORCE_" .. parent_force.name]
    if force then
      force.technologies[e.research.name].researched = true
    end

    for i in pairs(parent_force.players) do
      local force = game.forces["EE_TESTFORCE_" .. i]
      if force then
        force.technologies[e.research.name].researched = true
      end
    end
  end
end)

script.on_event(defines.events.on_force_reset, function(e)
  local parent_force = e.force
  -- Don't do anything if this is a testing force
  if string.find(parent_force.name, "EE_TESTFORCE_") then
    return
  end

  if settings.global["ee-testing-lab-match-research"].value then
    local force = game.forces["EE_TESTFORCE_" .. parent_force.name]
    -- Sync research techs with the parent force
    for name, tech in pairs(parent_force.technologies) do
      force.technologies[name].researched = tech.researched
    end
    force.reset_technology_effects()
  end
end)

-- GUI

--- @param e GuiEventData
gui.hook_events(function(e)
  local msg = gui.read_action(e)
  if msg then
    if msg.gui == "ia" then
      infinity_accumulator.handle_gui_action(e, msg)
    elseif msg.gui == "infinity_pipe" then
      local player_table = global.players[e.player_index]
      if player_table and player_table.gui.infinity_pipe then
        player_table.gui.infinity_pipe:dispatch(msg, e)
      end
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
      elseif string.find(entity_name, "ee%-infinity%-pipe") then
        infinity_pipe.create_gui(e.player_index, entity)
      elseif entity_name == "ee-super-pump" then
        super_pump.open(e.player_index, entity)
      elseif infinity_loader.check_is_loader(entity) then
        global.infinity_loader_open[e.player_index] = entity
      elseif infinity_wagon.check_is_wagon(entity) then
        local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
        infinity_wagon.open(player, entity)
      end
    end
  elseif e.name == defines.events.on_gui_closed then
    if e.gui_type and e.gui_type == defines.gui_type.controller then
      inventory.close_string_gui(e.player_index)
    elseif e.gui_type == defines.gui_type.entity then
      local loader = global.infinity_loader_open[e.player_index]
      if loader and loader.valid then
        infinity_loader.sync_chest_filter(loader)
        global.infinity_loader_open[e.player_index] = nil
      end
    end
  end
end)

-- SHORTCUT

script.on_event(defines.events.on_lua_shortcut, function(e)
  if e.prototype_name == "ee-toggle-map-editor" then
    game.get_player(e.player_index).toggle_map_editor()
  end
end)

-- PLAYER

script.on_event(defines.events.on_player_created, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]

  player_data.init(player)

  local in_debug_world = global.flags.in_debug_world
  if player.cheat_mode or (in_debug_world and settings.global["ee-debug-world-cheat-mode"].value) then
    cheat_mode.enable(player)
  end
  if in_debug_world and settings.global["ee-debug-world-give-testing-items"].value then
    cheat_mode.set_loadout(player)
  end

  local player_table = global.players[e.player_index]
  if
    in_debug_world
    and player_table.settings.start_in_editor
    and player.controller_type == defines.controllers.character
  then
    player.toggle_map_editor()
  end
end)

script.on_event(defines.events.on_player_left_game, function(e)
  global.infinity_loader_open[e.player_index] = nil
end)

script.on_event(defines.events.on_player_removed, function(e)
  global.infinity_loader_open[e.player_index] = nil
  global.players[e.player_index] = nil
end)

script.on_event({ defines.events.on_player_promoted, defines.events.on_player_demoted }, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
  -- lock or unlock the shortcut depending on if they're an admin
  player.set_shortcut_available("ee-toggle-map-editor", player.admin)
end)

script.on_event(defines.events.on_player_setup_blueprint, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]

  -- get blueprint
  local blueprint = player.blueprint_to_setup
  if not blueprint or not blueprint.valid_for_read then
    local cursor_blueprint = player.cursor_stack
    if cursor_blueprint and cursor_blueprint.valid then
      if cursor_blueprint.type == "blueprint-book" then
        local item_inventory = cursor_blueprint.get_inventory(defines.inventory.item_main)
        if item_inventory then
          blueprint = item_inventory[cursor_blueprint.active_index]
        else
          return
        end
      else
        blueprint = cursor_blueprint
      end
    end
  end

  -- get blueprint entities and mapping
  local entities = blueprint.get_blueprint_entities()
  if not entities then
    return
  end
  local surface = e.surface

  -- iterate each entity
  local set = false
  for i = 1, #entities do
    local entity = entities[i]
    local entity_name = entity.name
    if constants.aggregate_chest_names[entity_name] then
      set = true
      aggregate_chest.setup_blueprint(entity)
    elseif entity_name == "ee-infinity-cargo-wagon" then
      set = true
      entities[i] = infinity_wagon.setup_cargo_blueprint(entity, surface.find_entity(entity.name, entity.position))
    elseif entity_name == "ee-infinity-fluid-wagon" then
      set = true
      entities[i] = infinity_wagon.setup_fluid_blueprint(entity, surface.find_entity(entity.name, entity.position))
    elseif entity_name == "ee-super-pump" then
      set = true
      entities[i] = super_pump.setup_blueprint(entity, surface.find_entity(entity.name, entity.position))
    elseif infinity_pipe.check_is_our_pipe(entity) then
      set = true
      entities[i] = infinity_pipe.setup_blueprint(entity, surface.find_entity(entity.name, entity.position))
    end
  end

  -- set entities
  if set then
    blueprint.set_blueprint_entities(entities)
  end
end)

script.on_event(defines.events.on_pre_player_toggled_map_editor, function(e)
  local player_table = global.players[e.player_index]
  if not player_table then
    return
  end
  if player_table.settings.inventory_sync_enabled then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    inventory.create_sync_inventories(player_table, player)
  end
end)

script.on_event(defines.events.on_player_toggled_map_editor, function(e)
  local player_table = global.players[e.player_index]
  if not player_table then
    return
  end

  -- the first time someone toggles the map editor, unpause the current tick
  if global.flags.map_editor_toggled == false then
    global.flags.map_editor_toggled = true
    if settings.global["ee-prevent-initial-pause"].value then
      game.tick_paused = false
    end
  end

  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
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

  -- Toggle surface
  local ts_setting = player_table.settings.testing_lab
  if ts_setting ~= constants.testing_lab_setting.off then
    testing_lab.toggle(player, player_table, ts_setting --[[@as number]])
  end
end)

script.on_event(defines.events.on_player_cursor_stack_changed, function(e)
  local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
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

script.on_event(defines.events.on_runtime_mod_setting_changed, function(e)
  if e.setting == "ee-aggregate-include-hidden" then
    aggregate_chest.update_data()
    aggregate_chest.update_all_filters()
  elseif e.setting == "ee-testing-lab-match-research" then
    for _, force in pairs(game.forces) do
      local _, _, force_key = string.find(force.name, "EE_TESTFORCE_(.*)")
      if force_key then
        if settings.global["ee-testing-lab-match-research"].value then
          local parent_force
          local force_key_num = tonumber(force_key) --- @cast force_key_num uint?
          if force_key_num then
            local player = game.get_player(force_key_num) --[[@as LuaPlayer]]
            parent_force = remote.call("EditorExtensions", "get_player_proper_force", player)
          else
            parent_force = game.forces[force_key]
          end
          if parent_force then
            -- Sync research techs with the parent force
            for name, tech in pairs(parent_force.technologies) do
              force.technologies[name].researched = tech.researched
            end
          end
        else
          force.research_all_technologies()
        end
        force.reset_technology_effects()
      end
    end
  elseif game.mod_setting_prototypes[e.setting].mod == "EditorExtensions" and e.setting_type == "runtime-per-user" then
    local player = game.get_player(e.player_index) --[[@as LuaPlayer]]
    local player_table = global.players[e.player_index]
    player_data.update_settings(player, player_table)
  end
end)

-- SURFACE

script.on_event(defines.events.on_surface_cleared, function(e)
  local surface = game.get_surface(e.surface_index)
  if surface and surface.name == "nauvis" and game.tick == 1 and global.flags.in_debug_world then
    script.raise_event(constants.debug_world_ready_event, {})
  end
end)

-- TICK

script.on_event(defines.events.on_tick, function()
  infinity_wagon.flip_inventories()

  for _, player_table in pairs(global.players) do
    --- @type InfinityPipeGui
    local pipe_gui = player_table.gui.infinity_pipe
    if pipe_gui then
      pipe_gui:display_fluid_contents()
    end
  end
end)

script.on_nth_tick(5, function()
  for _, loader in pairs(global.infinity_loader_open) do
    infinity_loader.sync_chest_filter(loader)
  end
end)

-- -----------------------------------------------------------------------------
-- EVENT FILTERS

--- @param events defines.events[]
local function set_filters(events, filters)
  for _, name in pairs(events) do
    script.set_event_filter(name --[[@as uint]], filters)
  end
end

set_filters({
  defines.events.on_built_entity,
  defines.events.on_entity_cloned,
  defines.events.on_robot_built_entity,
}, {
  { filter = "name", name = "ee-aggregate-chest-passive-provider" },
  { filter = "name", name = "ee-aggregate-chest" },
  { filter = "name", name = "ee-infinity-cargo-wagon" },
  { filter = "name", name = "ee-infinity-fluid-wagon" },
  { filter = "name", name = "ee-super-inserter" },
  { filter = "name", name = "ee-super-pump" },
  { filter = "type", type = "transport-belt" },
  { filter = "type", type = "infinity-pipe" },
  { filter = "type", type = "underground-belt" },
  { filter = "type", type = "splitter" },
  { filter = "type", type = "loader" },
  { filter = "type", type = "loader-1x1" },
  { filter = "type", type = "linked-belt" },
  { filter = "ghost" },
  { filter = "ghost_name", name = "ee-super-pump" },
})

set_filters({ defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity }, {
  { filter = "name", name = "ee-infinity-accumulator-primary-output" },
  { filter = "name", name = "ee-infinity-accumulator-primary-input" },
  { filter = "name", name = "ee-infinity-accumulator-secondary-output" },
  { filter = "name", name = "ee-infinity-accumulator-secondary-input" },
  { filter = "name", name = "ee-infinity-accumulator-tertiary-buffer" },
  { filter = "name", name = "ee-infinity-accumulator-tertiary-input" },
  { filter = "name", name = "ee-infinity-accumulator-tertiary-output" },
  { filter = "name", name = "ee-infinity-cargo-wagon" },
  { filter = "name", name = "ee-infinity-fluid-wagon" },
  { filter = "name", name = "ee-infinity-loader-chest" },
  { filter = "type", type = "loader-1x1" },
  { filter = "type", type = "linked-belt" },
  { filter = "type", type = "infinity-pipe" },
})

set_filters({ defines.events.on_pre_player_mined_item, defines.events.on_marked_for_deconstruction }, {
  { filter = "name", name = "ee-infinity-cargo-wagon" },
})

set_filters({ defines.events.on_cancelled_deconstruction }, { { filter = "name", name = "ee-infinity-cargo-wagon" } })
